import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

const Map<PomodoroPhase, int> pomodoroDefaultMinutes = {
  PomodoroPhase.work: 25,
  PomodoroPhase.shortBreak: 5,
  PomodoroPhase.longBreak: 15,
};

class PomodoroState {
  final PomodoroPhase phase;
  final int secondsRemaining;
  final bool isRunning;
  final int completedSessions;
  final Map<PomodoroPhase, int> customMinutes;

  PomodoroState({
    this.phase = PomodoroPhase.work,
    int? secondsRemaining,
    this.isRunning = false,
    this.completedSessions = 0,
    Map<PomodoroPhase, int>? customMinutes,
  })  : customMinutes = customMinutes ?? const {},
        secondsRemaining = secondsRemaining ?? (pomodoroDefaultMinutes[phase]! * 60);

  int get totalSeconds => (customMinutes[phase] ?? pomodoroDefaultMinutes[phase]!) * 60;

  double get progress =>
      1.0 - (secondsRemaining / totalSeconds).clamp(0.0, 1.0);

  String get label => switch (phase) {
        PomodoroPhase.work => 'Focus',
        PomodoroPhase.shortBreak => 'Short Break',
        PomodoroPhase.longBreak => 'Long Break',
      };

  String get timeDisplay {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? secondsRemaining,
    bool? isRunning,
    int? completedSessions,
    Map<PomodoroPhase, int>? customMinutes,
  }) =>
      PomodoroState(
        phase: phase ?? this.phase,
        secondsRemaining: secondsRemaining ?? this.secondsRemaining,
        isRunning: isRunning ?? this.isRunning,
        completedSessions: completedSessions ?? this.completedSessions,
        customMinutes: customMinutes ?? this.customMinutes,
      );
}

final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier();
});

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  PomodoroNotifier() : super(PomodoroState());

  Timer? _timer;

  void startPause() {
    if (state.isRunning) {
      _pause();
    } else {
      _start();
    }
  }

  void _start() {
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsRemaining <= 1) {
        _onPhaseComplete();
      } else {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    final sessions = state.phase == PomodoroPhase.work
        ? state.completedSessions + 1
        : state.completedSessions;

    // After 4 work sessions, give a long break; otherwise short break
    final nextPhase = state.phase == PomodoroPhase.work
        ? (sessions % 4 == 0 ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak)
        : PomodoroPhase.work;

    state = PomodoroState(
      phase: nextPhase,
      completedSessions: sessions,
      isRunning: false,
      customMinutes: state.customMinutes,
    );
  }

  void reset() {
    _timer?.cancel();
    state = PomodoroState(
      phase: state.phase,
      completedSessions: state.completedSessions,
      customMinutes: state.customMinutes,
    );
  }

  void skipToNext() {
    _timer?.cancel();
    _onPhaseComplete();
  }

  void setPhase(PomodoroPhase phase) {
    _timer?.cancel();
    state = PomodoroState(
      phase: phase,
      completedSessions: state.completedSessions,
      customMinutes: state.customMinutes,
    );
  }

  void setCustomMinutes(PomodoroPhase phase, int minutes) {
    final custom = Map<PomodoroPhase, int>.from(state.customMinutes)
      ..[phase] = minutes;
    state = state.copyWith(customMinutes: custom);
    if (state.phase == phase && !state.isRunning) {
      state = state.copyWith(secondsRemaining: minutes * 60);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
