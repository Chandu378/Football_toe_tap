import 'package:flutter/material.dart';

/// Compact visual badge displaying performance metrics, foot states, or counters.
class StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  const StatBadge({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    final effectiveBg = backgroundColor ?? Colors.black.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: effectiveColor.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
