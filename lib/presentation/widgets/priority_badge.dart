import 'package:flutter/material.dart';
import '../../core/models/priority.dart';

class PriorityBadge extends StatelessWidget {
  final PriorityLevel priority;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: priority.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          priority.icon,
          size: 14,
          color: priority.color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: priority.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priority.color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priority.icon,
            size: 13,
            color: priority.color,
          ),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: priority.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
