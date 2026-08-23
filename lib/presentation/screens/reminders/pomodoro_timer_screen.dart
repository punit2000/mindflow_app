import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/pomodoro_provider.dart';

class PomodoroTimerScreen extends ConsumerWidget {
  const PomodoroTimerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PomodoroTimerScreen()),
    );
  }

  Future<void> _showCustomTimeDialog(
    BuildContext context,
    PomodoroState pomo,
    PomodoroNotifier notifier,
  ) async {
    final controller = TextEditingController(
      text: (pomo.customMinutes[pomo.phase] ?? pomodoroDefaultMinutes[pomo.phase]!).toString(),
    );
    String? errorText;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final parsed = int.tryParse(controller.text.trim());
            if (parsed == null || parsed < 1 || parsed > 300) {
              setDialogState(() => errorText = 'Enter minutes between 1 and 300');
              return;
            }
            Navigator.pop(dialogContext);
            notifier.setCustomMinutes(pomo.phase, parsed);
          }

          return AlertDialog(
            title: const Text('Set custom time'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Duration for ${pomo.label.toLowerCase()} sessions',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
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
              ],
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
  }

  Color _phaseColor(PomodoroPhase phase) => switch (phase) {
        PomodoroPhase.work => AppColors.primary,
        PomodoroPhase.shortBreak => AppColors.success,
        PomodoroPhase.longBreak => const Color(0xFF7C6BB5),
      };

  IconData _phaseIcon(PomodoroPhase phase) => switch (phase) {
        PomodoroPhase.work => Icons.self_improvement_rounded,
        PomodoroPhase.shortBreak => Icons.coffee_rounded,
        PomodoroPhase.longBreak => Icons.weekend_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomo = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phaseColor = _phaseColor(pomo.phase);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Focus Timer', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Session chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: PomodoroPhase.values.map((phase) {
                  final selected = pomo.phase == phase;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => notifier.setPhase(phase),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? _phaseColor(phase).withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? _phaseColor(phase)
                                : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                          ),
                        ),
                        child: Text(
                          switch (phase) {
                            PomodoroPhase.work => 'Focus',
                            PomodoroPhase.shortBreak => 'Short Break',
                            PomodoroPhase.longBreak => 'Long Break',
                          },
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? _phaseColor(phase)
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // Circular progress timer
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background ring
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        phaseColor.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  // Progress ring
                  SizedBox.expand(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pomo.progress),
                      duration: const Duration(milliseconds: 500),
                      builder: (ctx, value, _) => Transform.rotate(
                        angle: -math.pi / 2,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                        ),
                      ),
                    ),
                  ),
                  // Timer content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_phaseIcon(pomo.phase), color: phaseColor, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        pomo.timeDisplay,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w200,
                          letterSpacing: -2,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        pomo.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: phaseColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Session dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sessions: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                ...List.generate(4, (i) {
                  final filled = i < (pomo.completedSessions % 4);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: filled ? 16 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: filled ? phaseColor : phaseColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  );
                }),
              ],
            ),

            const Spacer(),

            // Set custom time
            TextButton.icon(
              onPressed: () => _showCustomTimeDialog(context, pomo, notifier),
              icon: Icon(Icons.edit_outlined, size: 16, color: phaseColor),
              label: Text(
                'Set custom time',
                style: TextStyle(color: phaseColor, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),

            const Spacer(),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset
                  _ControlButton(
                    icon: Icons.replay_rounded,
                    label: 'Reset',
                    onTap: notifier.reset,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    size: 48,
                  ),

                  // Play / Pause
                  GestureDetector(
                    onTap: notifier.startPause,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: phaseColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: phaseColor.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        pomo.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),

                  // Skip
                  _ControlButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Skip',
                    onTap: notifier.skipToNext,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    size: 48,
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

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: size * 0.45),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
