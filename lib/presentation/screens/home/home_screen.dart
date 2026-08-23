import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/home_layout.dart';
import '../../../core/models/note_template.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/app_providers.dart';
import '../../providers/home_layout_provider.dart';
import '../../providers/pdf_library_provider.dart';
import '../../widgets/mindflow_drawer.dart';
import '../library/library_tab.dart';
import '../library/pdf_reader_screen.dart';
import '../notes/note_editor_screen.dart';
import '../notes/notes_tab.dart';
import '../reminders/add_edit_reminder_sheet.dart';
import '../reminders/pomodoro_timer_screen.dart';
import '../reminders/reminders_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _showCreationDialog() {
    final layout = ref.read(homeLayoutProvider);
    final currentTab = ref.read(currentTabProvider);
    final visible = layout.visibleTabs;
    if (currentTab < 0 || currentTab >= visible.length) {
      _quickCapture();
      return;
    }
    final tab = visible[currentTab];
    if (tab == HomeTab.reminders) {
      _showReminderMenu();
    } else if (tab == HomeTab.notes) {
      _showNoteTypePicker();
    } else {
      _importPdf();
    }
  }

  /// Quick Capture: long-press the FAB to jump straight into a fresh note.
  void _quickCapture() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
    );
  }

  void _showReminderMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What would you like to create?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alarm_add_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text(
                  'Scheduled Reminder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Set time-based alarm or daily recurring task',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await waitForRouteExit();
                  if (!mounted) return;
                  AddEditReminderSheet.show(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.self_improvement_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                title: const Text(
                  'Focus Timer (Pomodoro)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Start a timed focus session to stay productive',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await waitForRouteExit();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PomodoroTimerScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importPdf() async {
    try {
      final document = await ref.read(pdfLibraryProvider.notifier).importPdf();
      if (document != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfReaderScreen(document: document),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not import that PDF. Please try another file.',
            ),
          ),
        );
      }
    }
  }

  void _showNoteTypePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What would you like to create?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Text Note / Markdown',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Capture thoughts, ideas, and meeting notes',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await waitForRouteExit();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NoteEditorScreen(isChecklistMode: false),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: AppColors.success,
                  ),
                ),
                title: const Text(
                  'To-Do Checklist',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Interactive checklist with item checkboxes',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await waitForRouteExit();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NoteEditorScreen(isChecklistMode: true),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C6BB5).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: Color(0xFF7C6BB5),
                  ),
                ),
                title: const Text(
                  'From Template',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Choose from pre-built note templates'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await waitForRouteExit();
                  if (!mounted) return;
                  _showTemplateChooser();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alarm_add_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text(
                  'Scheduled Reminder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Set time-based alarm or daily recurring task',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await waitForRouteExit();
                  if (!mounted) return;
                  AddEditReminderSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateChooser() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose a template',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...NoteTemplate.templates.map(
                (template) => ListTile(
                  leading: Text(
                    template.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    template.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await waitForRouteExit();
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteEditorScreen(
                          template: template,
                          isChecklistMode: template.isChecklist,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final layout = ref.watch(homeLayoutProvider);
    final visibleTabs = layout.visibleTabs;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Keep the selected tab index valid when tabs are hidden/reordered.
    final activeIndex = currentTab >= 0 && currentTab < visibleTabs.length
        ? currentTab
        : 0;
    final screens = [
      for (final tab in visibleTabs)
        switch (tab) {
          HomeTab.reminders => RemindersTab(onMenuPressed: _openMenu),
          HomeTab.notes => NotesTab(onMenuPressed: _openMenu),
          HomeTab.library => LibraryTab(onMenuPressed: _openMenu),
        },
    ];
    final fabLabel = activeIndex >= 0 && activeIndex < visibleTabs.length
        ? switch (visibleTabs[activeIndex]) {
            HomeTab.reminders => 'New Reminder',
            HomeTab.notes => 'New Note',
            HomeTab.library => 'Import PDF',
          }
        : 'New Note';
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MindFlowDrawer(),
      body: Stack(
        children: [
          // Main Content Screens
          IndexedStack(index: activeIndex, children: screens),
        ],
      ),
      // Central Action Floating Action Button
      floatingActionButton: GestureDetector(
        onLongPress: _quickCapture,
        child: FloatingActionButton.extended(
          onPressed: _showCreationDialog,
          heroTag: 'primary_fab',
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            fabLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Modern Clean Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < visibleTabs.length; i++)
                      Expanded(
                        child: _BottomNavItem(
                          tab: visibleTabs[i],
                          isActive: i == activeIndex,
                          isDark: isDark,
                          onTap: () {
                            ref.read(currentTabProvider.notifier).state = i;
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Built by punpun',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color:
                        (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)
                            .withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.tab,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });
  final HomeTab tab;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final (IconData activeIcon, IconData inactiveIcon) = switch (tab) {
      HomeTab.reminders => (Icons.alarm_on_rounded, Icons.alarm_outlined),
      HomeTab.notes => (Icons.edit_note_rounded, Icons.notes_rounded),
      HomeTab.library => (Icons.menu_book_rounded, Icons.menu_book_outlined),
    };
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
