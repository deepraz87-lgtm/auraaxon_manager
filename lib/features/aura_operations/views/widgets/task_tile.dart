import 'package:flutter/material.dart';
import '../../models/bot_agent_model.dart';

class TaskTile extends StatelessWidget {
  final BotTask task;

  const TaskTile({super.key, required this.task});

  Color _getStatusColor() {
    switch (task.status) {
      case TaskStatus.inProgress:
        return Colors.greenAccent;
      case TaskStatus.completed:
        return const Color(0xFF6C63FF);
      case TaskStatus.failed:
        return Colors.redAccent;
      case TaskStatus.needsInput:
        return Colors.amberAccent;
      case TaskStatus.queued:
        return Colors.white54;
    }
  }

  IconData _getStatusIcon() {
    switch (task.status) {
      case TaskStatus.inProgress:
        return Icons.sync;
      case TaskStatus.completed:
        return Icons.check_circle_outline;
      case TaskStatus.failed:
        return Icons.error_outline;
      case TaskStatus.needsInput:
        return Icons.help_outline;
      case TaskStatus.queued:
        return Icons.hourglass_empty;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStatusIcon(), color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.targetBotName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                _formatTime(task.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.brief,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          if (task.resultSummary != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Result: ${task.resultSummary}',
                style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
