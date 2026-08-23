import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/app_header_actions.dart';
import '../../widgets/note_card.dart';
import '../../widgets/search_and_filter_bar.dart';
import 'note_editor_screen.dart';

class NotesTab extends ConsumerWidget {
  const NotesTab({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = ref.watch(filteredNotesProvider);
    final allTags = ref.watch(allNotesTagsProvider);
    final allFolders = ref.watch(allNotesFoldersProvider);
    final selectedTag = ref.watch(selectedNotesTagProvider);
    final selectedFolder = ref.watch(selectedNotesFolderProvider);

    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final otherNotes = notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Header
          SliverAppBar(
            floating: true,
            pinned: false,
            leading: _MenuButton(onPressed: onMenuPressed),
            title: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Notes & Thoughts',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            actions: [
              GlobalSearchAction(),
              ThemeToggleAction(),
              SizedBox(width: 4),
            ],
          ),

          // Search & Filter Bar
          SliverToBoxAdapter(
            child: SearchAndFilterBar(
              hintText: 'Search notes, tags, checklists...',
              onSearchChanged: (val) {
                ref.read(notesSearchQueryProvider.notifier).state = val;
              },
              filterOptions: allTags,
              selectedFilter: selectedTag,
              onFilterSelected: (tag) {
                ref.read(selectedNotesTagProvider.notifier).state = tag;
              },
            ),
          ),

          // Folder Filter Pills
          if (allFolders.isNotEmpty)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Folders'),
                      selected: selectedFolder == null,
                      onSelected: (_) {
                        ref.read(selectedNotesFolderProvider.notifier).state = null;
                      },
                      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 8),
                    ...allFolders.map((folder) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(folder),
                                selected: selectedFolder == folder,
                                onSelected: (isSelected) {
                                  ref.read(selectedNotesFolderProvider.notifier).state =
                                      isSelected ? folder : null;
                                },
                                backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            )),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Empty State
          if (notes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 54,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Capture Your Ideas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Write thoughts, brainstorm ideas, and organize with checklists & tags.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
                            );
                          },
                          icon: const Icon(Icons.note_add_rounded),
                          label: const Text('Create a Note'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            // Pinned Notes Section
            if (pinnedNotes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'PINNED (${pinnedNotes.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = pinnedNotes[index];
                      return NoteCard(
                        note: note,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteEditorScreen(initialNote: note),
                            ),
                          );
                        },
                      );
                    },
                    childCount: pinnedNotes.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],

            // Other Notes Section
            if (otherNotes.isNotEmpty && pinnedNotes.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    'ALL NOTES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = otherNotes[index];
                    return NoteCard(
                      note: note,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteEditorScreen(initialNote: note),
                          ),
                        );
                      },
                    );
                  },
                  childCount: otherNotes.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menu',
      onPressed: onPressed,
    );
  }
}
