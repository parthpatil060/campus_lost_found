import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF59E0B);
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
      case 'matched':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF4CAF50);
        label = 'Matched';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'claimed':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF2196F3);
        label = 'Claimed';
        icon = Icons.done_all_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        fg = AppTheme.error;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = AppTheme.textSecondary;
        label = status;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
