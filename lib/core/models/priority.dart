import 'package:flutter/material.dart';

enum PriorityLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case PriorityLevel.low:
        return 'Low';
      case PriorityLevel.medium:
        return 'Medium';
      case PriorityLevel.high:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case PriorityLevel.low:
        return const Color(0xFF10B981); // Emerald Green
      case PriorityLevel.medium:
        return const Color(0xFFF59E0B); // Amber / Warm Orange
      case PriorityLevel.high:
        return const Color(0xFFEF4444); // Crimson / Coral Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PriorityLevel.low:
        return const Color(0xFF10B981).withValues(alpha: 0.15);
      case PriorityLevel.medium:
        return const Color(0xFFF59E0B).withValues(alpha: 0.15);
      case PriorityLevel.high:
        return const Color(0xFFEF4444).withValues(alpha: 0.15);
    }
  }

  IconData get icon {
    switch (this) {
      case PriorityLevel.low:
        return Icons.arrow_downward_rounded;
      case PriorityLevel.medium:
        return Icons.remove_rounded;
      case PriorityLevel.high:
        return Icons.priority_high_rounded;
    }
  }

  static PriorityLevel fromString(String? val) {
    if (val == null) return PriorityLevel.medium;
    return PriorityLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PriorityLevel.medium,
    );
  }
}
