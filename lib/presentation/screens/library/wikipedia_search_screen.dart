import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/wikipedia_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/wikipedia_provider.dart';
import 'wikipedia_reader_screen.dart';

class WikipediaSearchScreen extends ConsumerStatefulWidget {
  const WikipediaSearchScreen({super.key});

  @override
  ConsumerState<WikipediaSearchScreen> createState() => _WikipediaSearchScreenState();
}

class _WikipediaSearchScreenState extends ConsumerState<WikipediaSearchScreen> {
  final _searchController = TextEditingController();
  List<WikipediaSearchResult> _results = const [];
  List<String> _suggestions = const [];
  String? _error;
  bool _searching = false;
  Timer? _autocompleteDebounce;

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _autocompleteDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _autocompleteDebounce = Timer(const Duration(milliseconds: 320), () async {
      try {
        final suggestions = await ref.read(wikipediaServiceProvider).autocomplete(query);
        if (mounted && _searchController.text.trim() == query) {
          setState(() => _suggestions = suggestions);
        }
      } catch (_) {
        // Suggestions are optional; a full search still remains available.
      }
    });
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type something to search Wikipedia.')),
      );
      return;
    }
    if (_searching) return;
    _autocompleteDebounce?.cancel();
    setState(() {
      _searching = true;
      _error = null;
      _suggestions = const [];
    });
    try {
      final results = await ref.read(wikipediaServiceProvider).search(query);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not search Wikipedia. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _openArticle(WikipediaSearchResult result) async {
    final title = result.title.trim();
    if (title.isEmpty || _searching) return;
    setState(() => _searching = true);
    try {
      final article = await ref.read(wikipediaServiceProvider).loadArticle(result.title);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WikipediaReaderScreen(article: article)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that Wikipedia article.')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _openSuggestion(String title) async {
    _searchController.text = title;
    setState(() => _suggestions = const []);
    await _openArticle(WikipediaSearchResult(title: title, description: ''));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Read Wikipedia')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search Wikipedia',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: _search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'Search, then read articles page by page in focus mode.',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
              ),
              child: Column(
                children: [
                  for (final suggestion in _suggestions)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
                      title: Text(suggestion),
                      onTap: () => _openSuggestion(suggestion),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _results.isEmpty && !_searching
                ? const Center(child: Text('Find something wonderful to read.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return Card(
                        child: ListTile(
                          title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: result.description.isEmpty ? null : Text(result.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                          onTap: () => _openArticle(result),
                        ),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text('Wikipedia content is available under CC BY-SA.', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
