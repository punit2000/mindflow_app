import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/priority.dart';
import '../../../core/models/reminder.dart';
import '../../../core/models/repeat_interval.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/app_providers.dart';

class AddEditReminderSheet extends ConsumerStatefulWidget {
  final Reminder? initialReminder;
  final String? initialTitle;

  const AddEditReminderSheet({
    super.key,
    this.initialReminder,
    this.initialTitle,
  });

  static Future<void> show(
    BuildContext context, {
    Reminder? reminder,
    String? initialTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditReminderSheet(
        initialReminder: reminder,
        initialTitle: initialTitle,
      ),
    );
  }

  @override
  ConsumerState<AddEditReminderSheet> createState() => _AddEditReminderSheetState();
}

class _AddEditReminderSheetState extends ConsumerState<AddEditReminderSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late RepeatInterval _repeatInterval;
  late PriorityLevel _priority;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    final rem = widget.initialReminder;
    _titleController = TextEditingController(
      text: widget.initialTitle ?? rem?.title ?? '',
    );
    _descController = TextEditingController(text: rem?.description ?? '');
    _tagController = TextEditingController();

    final now = DateTime.now();
    _selectedDate = rem?.scheduledTime ?? now;
    _selectedTime = rem != null
        ? TimeOfDay(hour: rem.scheduledTime.hour, minute: rem.scheduledTime.minute)
        : TimeOfDay(
            hour: (now.hour + 1) % 24,
            minute: 0,
          );
    _repeatInterval = rem?.repeatInterval ?? RepeatInterval.none;
    _priority = rem?.priority ?? PriorityLevel.medium;
    _tags = List.from(rem?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addTag(String text) {
    final clean = text.trim().replaceAll('#', '');
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
      });
      _tagController.clear();
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder title')),
      );
      return;
    }

    final scheduled = _repeatInterval == RepeatInterval.hourly
        ? DateTime.now().add(const Duration(hours: 1))
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );

    // Prompt while the user is actively creating a reminder, rather than only
    // from the hidden test-notification action.
    await ref.read(notificationServiceProvider).requestPermissions();

    if (widget.initialReminder != null) {
      final updated = widget.initialReminder!.copyWith(
        title: title,
        description: _descController.text.trim(),
        scheduledTime: scheduled,
        repeatInterval: _repeatInterval,
        priority: _priority,
        tags: _tags,
      );
      await ref.read(remindersProvider.notifier).updateReminder(updated);
    } else {
      final newReminder = Reminder(
        id: const Uuid().v4(),
        title: title,
        description: _descController.text.trim(),
        scheduledTime: scheduled,
        repeatInterval: _repeatInterval,
        priority: _priority,
        tags: _tags,
        createdAt: DateTime.now(),
      );
      await ref.read(remindersProvider.notifier).addReminder(newReminder);
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scheduled.isAfter(DateTime.now()) &&
                  !DateUtils.isSameDay(scheduled, DateTime.now())
              ? 'Reminder saved. Find it in Upcoming.'
              : 'Reminder saved.',
        ),
      ),
    );
  }
  
  Future<void> _saveWithErrorHandling() async {
    try {
      await _save();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save reminder. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialReminder != null ? 'Edit Reminder' : 'New Reminder',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title Input
            TextField(
              controller: _titleController,
              autofocus: widget.initialReminder == null,
              decoration: const InputDecoration(
                hintText: 'What would you like to be reminded of?',
                prefixIcon: Icon(Icons.alarm_add_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),

            // Description Input
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add notes or extra details (optional)',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time Selectors Row
            if (_repeatInterval == RepeatInterval.hourly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(child: Text('This reminder starts in one hour and repeats every hour.')),
                  ],
                ),
              )
            else
              Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEE, MMM d').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              ),
            const SizedBox(height: 16),

            // Repeat Interval Selector
            const Text('Repeat Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final interval in RepeatInterval.values) ...[
                    ChoiceChip(
                      label: Text(interval.label),
                      selected: _repeatInterval == interval,
                      onSelected: (val) {
                        if (val) setState(() => _repeatInterval = interval);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _repeatInterval == interval
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        fontWeight: _repeatInterval == interval ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Priority Selector
            const Text('Urgency / Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final p in PriorityLevel.values) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        avatar: Icon(p.icon, size: 16, color: p.color),
                        label: Text(p.label),
                        selected: _priority == p,
                        onSelected: (val) {
                          if (val) setState(() => _priority = p);
                        },
                        selectedColor: p.color.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: p.color,
                          fontWeight: _priority == p ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _priority == p ? p.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Tag Input & Chips
            const Text('Tags', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    onSubmitted: _addTag,
                    decoration: InputDecoration(
                      hintText: 'Add a tag (e.g. Work, Health)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary),
                        onPressed: () => _addTag(_tagController.text),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in _tags)
                    Chip(
                      label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() => _tags.remove(tag));
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveWithErrorHandling,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  widget.initialReminder != null ? 'Update Reminder' : 'Set Reminder',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
