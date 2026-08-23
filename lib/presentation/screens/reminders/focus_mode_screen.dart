import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/focus_lock_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/app_providers.dart';

final focusModeProvider = StateNotifierProvider<FocusModeNotifier, DateTime?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FocusModeNotifier(storage);
});

class FocusModeNotifier extends StateNotifier<DateTime?> {
  FocusModeNotifier(this._storage) : super(null) {
    _load();
  }

  final StorageService _storage;

  void _load() {
    final saved = _storage.loadFocusModeUntil();
    if (saved != null && saved.isAfter(DateTime.now())) {
      state = saved;
    }
  }

  Future<void> startFocus(Duration duration) async {
    final until = DateTime.now().add(duration);
    state = until;
    await _storage.saveFocusModeUntil(until);
  }

  Future<void> endFocus() async {
    state = null;
    await _storage.saveFocusModeUntil(null);
  }

  bool get isActive => state != null && state!.isAfter(DateTime.now());
}

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  static Future<void> show(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FocusModeScreen()),
      );

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  int _selectedMinutes = 25;
  bool _blockApps = false;
  bool _overlayAvailable = false;
  bool _usageStatsAvailable = false;
  List<String> _blockedPackages = [];
  Timer? _ticker;
  final FocusLockService _focusLock = FocusLockService();

  static const _presets = [15, 25, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _blockedPackages = ref.read(focusBlockedAppsProvider);
    _blockApps = _blockedPackages.isNotEmpty;
    _startTicker();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final overlay = await _focusLock.canDrawOverlay();
    final usage = await _focusLock.canAccessUsageStats();
    if (mounted) {
      setState(() {
        _overlayAvailable = overlay;
        _usageStatsAvailable = usage;
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final until = ref.read(focusModeProvider);
      if (until == null || until.isBefore(DateTime.now())) {
        ref.read(focusModeProvider.notifier).endFocus();
        _focusLock.stop();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _requestOverlayPermission() async {
    await _focusLock.openOverlaySettings();
    await _checkPermissions();
  }

  Future<void> _requestUsageStatsPermission() async {
    await _focusLock.openUsageStatsSettings();
    await _checkPermissions();
  }

  Future<void> _openAppPicker() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const BlockedAppsScreen()),
    );
    if (selected != null && mounted) {
      await waitForRouteExit();
      if (!mounted) return;
      setState(() {
        _blockedPackages = selected;
        _blockApps = selected.isNotEmpty;
      });
      ref.read(focusBlockedAppsProvider.notifier).state = selected;
      await ref.read(storageServiceProvider).saveFocusBlockedPackages(selected);
    }
  }

  Future<void> _showCustomTimeDialog() async {
    final controller = TextEditingController(text: _selectedMinutes.toString());
    String? errorText;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final parsed = int.tryParse(controller.text.trim());
            if (parsed == null || parsed < 1 || parsed > 720) {
              setDialogState(() => errorText = 'Enter minutes between 1 and 720');
              return;
            }
            Navigator.pop(dialogContext, parsed);
          }

          return AlertDialog(
            title: const Text('Set focus duration'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minutes',
                suffixText: 'min',
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submit,
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
    await waitForRouteExit();
    controller.dispose();
    if (result != null && mounted) {
      setState(() => _selectedMinutes = result);
    }
  }

  Future<void> _onActionPressed() async {
    if (ref.read(focusModeProvider.notifier).isActive) {
      await ref.read(focusModeProvider.notifier).endFocus();
      await _focusLock.stop();
    } else {
      await ref.read(focusModeProvider.notifier)
          .startFocus(Duration(minutes: _selectedMinutes));
      if (_blockApps && _focusLock.isSupported && _blockedPackages.isNotEmpty) {
        final canOverlay = await _focusLock.canDrawOverlay();
        final canUsage = await _focusLock.canAccessUsageStats();
        if (!canOverlay || !canUsage) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Grant “Display over other apps” and “Usage access” to block apps during focus.',
                ),
              ),
            );
          }
        } else {
          await _focusLock.start(_selectedMinutes, _blockedPackages);
        }
      }
      _startTicker();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final until = ref.watch(focusModeProvider);
    final isActive = until != null && until.isAfter(DateTime.now());
    final remaining = isActive ? until.difference(DateTime.now()) : Duration.zero;
    final totalSeconds = _selectedMinutes * 60;
    final progress = isActive ? (remaining.inSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Focus Mode', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status label
              Text(
                isActive ? 'Notifications paused' : 'Choose focus duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.success : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Timer ring
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.do_not_disturb_on_rounded,
                          size: 32,
                          color: isActive ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isActive ? _fmt(remaining) : '$_selectedMinutes:00',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -2,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          isActive ? 'remaining' : 'minutes',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Preset chips (only when not active)
              if (!isActive) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _presets.map((min) {
                    final selected = _selectedMinutes == min;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMinutes = min),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                          ),
                        ),
                        child: Text(
                          '$min min',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
const SizedBox(height: 10),

                TextButton.icon(
                  onPressed: _showCustomTimeDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Set custom time',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // App blocking card
                if (_focusLock.isSupported)
                  _buildBlockAppsCard(isDark),
                const SizedBox(height: 32),
              ],

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onActionPressed,
                  icon: Icon(isActive ? Icons.notifications_active_rounded : Icons.do_not_disturb_on_rounded),
                  label: Text(
                    isActive ? 'End Focus Mode' : 'Start Focus Mode',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? AppColors.danger : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (!isActive)
                Text(
                  _focusLock.isSupported
                      ? 'Reminder notifications are paused during focus time.'
                      : 'Reminder notifications will be paused during focus time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockAppsCard(bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final permissionsOk = _overlayAvailable && _usageStatsAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _blockApps ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: _blockApps ? AppColors.primary : textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Block distracting apps',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      _blockedPackages.isNotEmpty
                          ? '${_blockedPackages.length} app(s) selected'
                          : 'Selected apps are locked during focus',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _blockApps,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _blockApps = v),
              ),
            ],
          ),
          if (_blockApps && !permissionsOk) ...[
            const Divider(height: 1),
            _PermissionRow(
              label: 'Display over other apps',
              granted: _overlayAvailable,
              onTap: _requestOverlayPermission,
            ),
            _PermissionRow(
              label: 'Usage access',
              granted: _usageStatsAvailable,
              onTap: _requestUsageStatsPermission,
            ),
          ],
          if (_blockApps) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apps_rounded, color: AppColors.primary),
              title: Text(
                _blockedPackages.isEmpty ? 'Choose apps to block' : 'Change blocked apps',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: _blockedPackages.isEmpty
                  ? Text(
                      'Pick the apps that get locked during focus',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    )
                  : null,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openAppPicker,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.onTap,
  });

  final String label;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: granted ? AppColors.success : AppColors.warning,
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(granted ? 'Granted' : 'Grant'),
      ),
    );
  }
}

/// Full-screen picker listing installed apps with checkboxes for blocking.
class BlockedAppsScreen extends ConsumerStatefulWidget {
  const BlockedAppsScreen({super.key});

  static Future<void> open(BuildContext context, WidgetRef ref) async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const BlockedAppsScreen()),
    );
    if (selected != null) {
      await waitForRouteExit();
      ref.read(focusBlockedAppsProvider.notifier).state = selected;
      await ref.read(storageServiceProvider).saveFocusBlockedPackages(selected);
    }
  }

  @override
  ConsumerState<BlockedAppsScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<BlockedAppsScreen> {
  final FocusLockService _focusLock = FocusLockService();
  List<({String package, String label})> _apps = [];
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected
      ..clear()
      ..addAll(ref.read(focusBlockedAppsProvider));
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await _focusLock.listInstalledApps();
    if (mounted) {
      setState(() {
        _apps = apps;
        _loading = false;
      });
    }
  }

  void _toggle(String package) {
    setState(() {
      if (!_selected.remove(package)) {
        _selected.add(package);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps to block', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    'Selected apps will be locked with a full-screen overlay while focus mode is active.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ),
                Expanded(
                  child: _apps.isEmpty
                      ? const Center(child: Text('No installed apps found'))
                      : ListView.builder(
                          itemCount: _apps.length,
                          itemBuilder: (context, index) {
                            final app = _apps[index];
                            final checked = _selected.contains(app.package);
                            return CheckboxListTile(
                              value: checked,
                              title: Text(
                                app.label,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                app.package,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                              secondary: Icon(
                                Icons.android_rounded,
                                color: checked ? AppColors.primary : textSecondary,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              onChanged: (_) => _toggle(app.package),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}