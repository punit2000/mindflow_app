import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../../../core/models/note.dart';
import '../../../core/models/note_template.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/note_links_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/color_picker_sheet.dart';
import '../../widgets/wiki_linked_markdown.dart';
import '../reminders/add_edit_reminder_sheet.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? initialNote;
  final bool isChecklistMode;
  final NoteTemplate? template;
  final String? linkedSourceId;
  final String? initialTitle;
  final String? initialContent;

  const NoteEditorScreen({
    super.key,
    this.initialNote,
    this.isChecklistMode = false,
    this.template,
    this.linkedSourceId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;
  late TextEditingController _newChecklistItemController;

  late int _colorIndex;
  late bool _isPinned;
  late bool _isChecklist;
  late List<ChecklistItem> _checklistItems;
  late List<String> _tags;
  late String? _folder;
  bool _hasModified = false;
  bool _isPreviewMode = false;
  bool _isListening = false;
  late final stt.SpeechToText _speechToText;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;
    final template = widget.template;

    _titleController = TextEditingController(
      text: note?.title ?? (template?.titlePlaceholder ?? widget.initialTitle ?? ''),
    );
    _contentController = TextEditingController(
      text: note?.content ?? (template?.contentPlaceholder ?? widget.initialContent ?? ''),
    );
    _tagInputController = TextEditingController();
    _newChecklistItemController = TextEditingController();

    _colorIndex = note?.colorIndex ?? 0;
    _isPinned = note?.isPinned ?? false;
    _isChecklist = note?.isChecklist ?? (template?.isChecklist ?? widget.isChecklistMode);
    _checklistItems = note != null
        ? List.from(note.checklistItems)
        : (template?.checklistItems ?? [])
            .asMap()
            .entries
            .map(
              (e) => ChecklistItem(
                id: const Uuid().v4(),
                text: e.value,
              ),
            )
            .toList();
    _tags = List.from(note?.tags ?? []);
    _folder = note?.folder;

    _titleController.addListener(() => _hasModified = true);
    _contentController.addListener(() => _hasModified = true);

    _speechToText = stt.SpeechToText();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    try {
      await _speechToText.initialize(
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech error: $error')),
            );
          }
        },
        onStatus: (status) {
          if (mounted) {
            setState(() {});
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initialize speech: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    _newChecklistItemController.dispose();
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _checklistItems.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final now = DateTime.now();

    if (widget.initialNote != null) {
      final updated = widget.initialNote!.copyWith(
        title: title,
        content: content,
        colorIndex: _colorIndex,
        isPinned: _isPinned,
        isChecklist: _isChecklist,
        checklistItems: _checklistItems,
        tags: _tags,
        folder: _folder,
        updatedAt: now,
      );
      ref.read(notesProvider.notifier).updateNote(updated);
    } else {
      final newNote = Note(
        id: const Uuid().v4(),
        title: title.isNotEmpty ? title : (_isChecklist ? 'Checklist' : 'Quick Note'),
        content: content,
        colorIndex: _colorIndex,
        isPinned: _isPinned,
        isChecklist: _isChecklist,
        checklistItems: _checklistItems,
        tags: _tags,
        folder: _folder,
        linkedSourceId: widget.linkedSourceId,
        createdAt: now,
        updatedAt: now,
      );
      ref.read(notesProvider.notifier).addNote(newNote);
      Navigator.pop(context, newNote.id);
      return;
    }

    Navigator.pop(context);
  }

  void _insertMarkdown(String prefix, [String suffix = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.start < 0) {
      _contentController.text = '$text$prefix$suffix';
      return;
    }

    final selectedText = selection.textInside(text);
    final replacement = '$prefix$selectedText$suffix';
    final newText = text.replaceRange(selection.start, selection.end, replacement);

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length + suffix.length,
      ),
    );
    _hasModified = true;
  }

  void _addChecklistItem() {
    final text = _newChecklistItemController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklistItems.add(
          ChecklistItem(id: const Uuid().v4(), text: text, isChecked: false),
        );
        _hasModified = true;
      });
      _newChecklistItemController.clear();
    }
  }

  void _addTag(String tag) {
    final clean = tag.trim().replaceAll('#', '');
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
        _hasModified = true;
      });
      _tagInputController.clear();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await waitForRouteExit();
              if (widget.initialNote != null) {
                ref.read(notesProvider.notifier).deleteNote(widget.initialNote!.id);
              }
              if (mounted) Navigator.pop(context); // Close editor
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final shareText = '${title.isNotEmpty ? title : 'Note'}\n\n$content';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share Note'),
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(ShareParams(text: shareText));
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy to Clipboard'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareText));
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createReminder() {
    final title = _titleController.text.trim();
    AddEditReminderSheet.show(
      context,
      initialTitle: title.isNotEmpty ? title : 'Note Reminder',
    );
  }

  void _startVoiceRecording() async {
    if (!_speechToText.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              final currentText = _contentController.text;
              final newText = currentText.isEmpty
                  ? result.recognizedWords
                  : '$currentText ${result.recognizedWords}';
              _contentController.text = newText;
              _hasModified = true;

              if (result.finalResult) {
                setState(() => _isListening = false);
              }
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.noteColorPalettes[
        _colorIndex.clamp(0, AppColors.noteColorPalettes.length - 1)];
    final bgColor = palette.getColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_hasModified) {
              _saveNote();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Markdown Preview Toggle (only in not-checklist mode)
          if (!_isChecklist)
            IconButton(
              icon: Icon(
                _isPreviewMode ? Icons.edit_rounded : Icons.preview_rounded,
                color: _isPreviewMode ? palette.accentColor : null,
              ),
              tooltip: _isPreviewMode ? 'Edit mode' : 'Preview mode',
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                });
              },
            ),
          // Create Reminder button
          IconButton(
            icon: const Icon(Icons.alarm_add_rounded),
            tooltip: 'Create reminder',
            onPressed: _createReminder,
          ),
          // Share button
          if (widget.initialNote != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share note',
              onPressed: _showShareOptions,
            ),
          // Checklist Mode Toggle
          IconButton(
            icon: Icon(
              _isChecklist ? Icons.checklist_rounded : Icons.format_list_bulleted_rounded,
              color: _isChecklist ? palette.accentColor : null,
            ),
            tooltip: _isChecklist ? 'Switch to text mode' : 'Switch to checklist mode',
            onPressed: () {
              setState(() {
                _isChecklist = !_isChecklist;
                _isPreviewMode = false; // Reset preview mode when toggling checklist
                _hasModified = true;
              });
            },
          ),
          // Pin button
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? palette.accentColor : null,
            ),
            tooltip: _isPinned ? 'Unpin' : 'Pin note',
            onPressed: () {
              setState(() {
                _isPinned = !_isPinned;
                _hasModified = true;
              });
            },
          ),
          // Delete button (if editing existing note)
          if (widget.initialNote != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete note',
              onPressed: _showDeleteConfirmation,
            ),
          // Save button
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.primary),
            tooltip: 'Save note',
            onPressed: _saveNote,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  // Title Field
                  TextField(
                    controller: _titleController,
                    maxLines: null,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Note Title',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Folder Selector
                  Consumer(
                    builder: (context, ref, _) {
                      final allFolders = ref.watch(allNotesFoldersProvider);
                      final foldersList = ['All Notes', ...allFolders];
                      final displayFolder = _folder ?? 'All Notes';

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: foldersList
                              .map((folder) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(folder),
                                      selected: displayFolder == folder,
                                      onSelected: (isSelected) {
                                        setState(() {
                                          _folder = isSelected && folder != 'All Notes' ? folder : null;
                                          _hasModified = true;
                                        });
                                      },
                                      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                                      selectedColor: palette.accentColor.withValues(alpha: 0.2),
                                      labelStyle: TextStyle(
                                        color: displayFolder == folder
                                            ? palette.accentColor
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Checklist Mode Content
                  if (_isChecklist) ...[
                    for (int i = 0; i < _checklistItems.length; i++) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _checklistItems[i].isChecked,
                            activeColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _checklistItems[i] =
                                    _checklistItems[i].copyWith(isChecked: val ?? false);
                                _hasModified = true;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              _checklistItems[i].text,
                              style: TextStyle(
                                fontSize: 15,
                                decoration: _checklistItems[i].isChecked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: _checklistItems[i].isChecked
                                    ? (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary)
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            onPressed: () {
                              setState(() {
                                _checklistItems.removeAt(i);
                                _hasModified = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                    // Add new checklist item row
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.add, size: 20, color: AppColors.primary),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _newChecklistItemController,
                            onSubmitted: (_) => _addChecklistItem(),
                            decoration: const InputDecoration(
                              hintText: 'Add an item...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: AppColors.primary),
                          onPressed: _addChecklistItem,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Standard Text / Markdown Field
                  if (_isPreviewMode)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: WikiLinkedMarkdown(
                        data: _contentController.text.isEmpty ? '*No content yet*' : _contentController.text,
                        softLineBreak: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          h1: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          h2: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          h3: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          em: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          code: TextStyle(
                            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          blockquote: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                width: 4,
                              ),
                            ),
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    )
                  else
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: _isChecklist
                            ? 'Add optional notes or descriptions...'
                            : 'Type your note here... Supports markdown formatting.',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Tags Section
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final tag in _tags)
                        Chip(
                          label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() {
                              _tags.remove(tag);
                              _hasModified = true;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _tagInputController,
                          onSubmitted: _addTag,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: '+ Add tag',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Backlinks Section (notes that reference this note)
                  if (widget.initialNote != null)
                    Consumer(
                      builder: (context, ref, _) {
                        final backlinks =
                            ref.watch(noteBacklinksProvider)[widget.initialNote!.id] ?? const [];
                        if (backlinks.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  size: 16,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LINKED FROM (${backlinks.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (final source in backlinks)
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          NoteEditorScreen(initialNote: source),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.north_west_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          source.title.isEmpty ? 'Untitled Note' : source.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),

            // Bottom Toolbar: Color Picker & Markdown Helpers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Markdown Tools (hidden in preview mode or checklist mode)
                  if (!_isPreviewMode && !_isChecklist)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.format_bold_rounded, size: 20),
                            tooltip: 'Bold',
                            onPressed: () => _insertMarkdown('**', '**'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_italic_rounded, size: 20),
                            tooltip: 'Italic',
                            onPressed: () => _insertMarkdown('*', '*'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.title_rounded, size: 20),
                            tooltip: 'Heading',
                            onPressed: () => _insertMarkdown('## '),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
                            tooltip: 'Bullet List',
                            onPressed: () => _insertMarkdown('• '),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_quote_rounded, size: 20),
                            tooltip: 'Quote',
                            onPressed: () => _insertMarkdown('> '),
                          ),
                          IconButton(
                            icon: const Icon(Icons.code_rounded, size: 20),
                            tooltip: 'Code',
                            onPressed: () => _insertMarkdown('`', '`'),
                          ),
                          const SizedBox(width: 8),
                          VerticalDivider(
                            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                            thickness: 1,
                            width: 1,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                              size: 20,
                              color: _isListening ? AppColors.danger : null,
                            ),
                            tooltip: _isListening ? 'Stop recording' : 'Start voice input',
                            onPressed: _startVoiceRecording,
                          ),
                        ],
                      ),
                    ),

                  // Color Picker Row
                  ColorPickerRow(
                    selectedColorIndex: _colorIndex,
                    onColorSelected: (idx) {
                      setState(() {
                        _colorIndex = idx;
                        _hasModified = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
