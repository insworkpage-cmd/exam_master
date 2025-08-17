import 'package:flutter/material.dart';

class QuestionStatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const QuestionStatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'در انتظار تأیید';
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        color = Colors.green;
        text = 'تأیید شده';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'رد شده';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12), // ✡️ const حذف شد
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: color, size: fontSize != null ? fontSize! * 0.8 : 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
