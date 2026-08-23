import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/calendar_sync_provider.dart';

class CalendarSyncDialog extends ConsumerWidget {
  const CalendarSyncDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const CalendarSyncDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncState = ref.watch(calendarSyncProvider);
    final syncNotifier = ref.read(calendarSyncProvider.notifier);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text(
            'Google Calendar Sync',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bidirectionally sync your reminders with your Google Calendar account.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),

            if (Platform.isAndroid || Platform.isIOS) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No Google sign-in needed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 3),
                    const Text('Save reminders directly to your phone calendar. Google Calendar will sync them if that account is already on your device.', style: TextStyle(fontSize: 12, height: 1.35)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: syncState.isSyncing ? null : () => syncNotifier.exportToDeviceCalendar(),
                      icon: const Icon(Icons.phone_android_rounded, size: 17),
                      label: const Text('Save to phone calendar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Status banners ──────────────────────────────────────────
            if (syncState.lastSyncTime != null) ...[
              _StatusBanner(
                color: AppColors.success,
                icon: Icons.check_circle_outline_rounded,
                text:
                    'Last synced: ${DateFormat('h:mm a, MMM d').format(syncState.lastSyncTime!)}',
              ),
              const SizedBox(height: 12),
            ],

            if (syncState.message != null && syncState.status == SyncStatus.error) ...[
              _StatusBanner(
                color: AppColors.danger,
                icon: Icons.error_outline_rounded,
                text: syncState.message!,
              ),
              const SizedBox(height: 12),
            ],

            if (syncState.message != null && syncState.status == SyncStatus.success) ...[
              _StatusBanner(
                color: AppColors.success,
                icon: Icons.sync_rounded,
                text: syncState.message!,
              ),
              const SizedBox(height: 12),
            ],

            // ── Sign-in / Account section ───────────────────────────────
            if (!syncState.isSignedIn) ...[
              OutlinedButton.icon(
                onPressed: syncState.isSyncing ? null : () => syncNotifier.signIn(),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign in with Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ] else ...[
              // Signed in — show calendars list
              const Text(
                'Select Target Calendar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (syncState.availableCalendars.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      const Text(
                        'No calendars found.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => syncNotifier.loadCalendars(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: syncState.availableCalendars.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                    itemBuilder: (ctx, idx) {
                      final cal = syncState.availableCalendars[idx];
                      final isSelected = syncState.selectedCalendarId == cal.id;

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          cal.summary ?? 'Calendar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: cal.id != null
                            ? Text(
                                cal.id!,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () {
                          if (cal.id != null) {
                            syncNotifier.setSelectedCalendar(
                                cal.id!, cal.summary ?? 'Google Calendar');
                          }
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => syncNotifier.signOut(),
                  icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.grey),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (syncState.isSignedIn)
          ElevatedButton.icon(
            onPressed: syncState.isSyncing
                ? null
                : () async {
                    await syncNotifier.triggerSync();
                  },
            icon: syncState.isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync_rounded, size: 18),
            label: Text(syncState.isSyncing ? 'Syncing...' : 'Sync Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
      ],
    );
  }
}

// ── Helper widget ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _StatusBanner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
