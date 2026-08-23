import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/note.dart';
import '../../core/theme/app_colors.dart';
import '../providers/note_links_provider.dart';
import '../providers/notes_provider.dart';
import 'wiki_linked_markdown.dart';

class NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback? onTap;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
  });

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backlinks = ref.watch(noteBacklinksProvider)[note.id] ?? const [];
    final palette = AppColors.noteColorPalettes[
        note.colorIndex.clamp(0, AppColors.noteColorPalettes.length - 1)];
    final cardBg = palette.getColor(isDark);

    final completedChecklistCount =
        note.checklistItems.where((item) => item.isChecked).length;
    final totalChecklistCount = note.checklistItems.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: note.isPinned
              ? palette.accentColor.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          width: note.isPinned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Pin Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isNotEmpty ? note.title : 'Untitled Note',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    // Pin toggle button
                    IconButton(
                      icon: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                        color: note.isPinned
                            ? palette.accentColor
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: note.isPinned ? 'Unpin' : 'Pin to top',
                      onPressed: () {
                        ref.read(notesProvider.notifier).togglePin(note.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Note Body / Checklist preview
                if (note.isChecklist && note.checklistItems.isNotEmpty) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in note.checklistItems.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  ref
                                      .read(notesProvider.notifier)
                                      .toggleChecklistItem(note.id, item.id);
                                },
                                child: Icon(
                                  item.isChecked
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 16,
                                  color: item.isChecked
                                      ? AppColors.success
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    decoration: item.isChecked
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: item.isChecked
                                        ? (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (note.checklistItems.length > 3)
                        Text(
                          '+${note.checklistItems.length - 3} more items',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ] else if (note.content.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 56),
                    child: ClipRect(
                      child: OverflowBox(
                        maxHeight: double.infinity,
                        alignment: Alignment.topCenter,
                        child: WikiLinkedMarkdown(
                          data: note.content,
                          softLineBreak: true,
                          selectable: false,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            strong: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            em: const TextStyle(fontStyle: FontStyle.italic),
                            h1: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            h2: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            h3: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            code: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            blockquote: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            listBullet: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Tags & Timestamp Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tags List
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (note.isChecklist && totalChecklistCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✓ $completedChecklistCount/$totalChecklistCount',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          for (final tag in note.tags.take(2))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (backlinks.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link_rounded,
                                    size: 10,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${backlinks.length} linked',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Updated At
                    Text(
                      _formatTimeAgo(note.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
