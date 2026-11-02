import 'package:flutter/material.dart';
import '../../models/bot_agent_model.dart';

class BotCard extends StatelessWidget {
  final BotAgent bot;
  final VoidCallback onAssignTask;

  const BotCard({
    super.key,
    required this.bot,
    required this.onAssignTask,
  });

  Color _getStatusColor() {
    switch (bot.status) {
      case BotStatus.running:
        return Colors.greenAccent;
      case BotStatus.blocked:
        return Colors.orangeAccent;
      case BotStatus.offline:
        return Colors.redAccent;
      case BotStatus.idle:
        return const Color(0xFF6C63FF);
    }
  }

  String _getStatusText() {
    switch (bot.status) {
      case BotStatus.running:
        return 'Active / Running';
      case BotStatus.blocked:
        return 'Needs Attention';
      case BotStatus.offline:
        return 'Offline';
      case BotStatus.idle:
        return 'Available (Idle)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bot.status == BotStatus.running
              ? Colors.greenAccent.withValues(alpha: 0.4)
              : Colors.white10,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  child: Icon(
                    bot.id == 'director'
                        ? Icons.shield_outlined
                        : (bot.id == 'dev_lead'
                            ? Icons.terminal
                            : (bot.name.contains('SciRoad')
                                ? Icons.navigation_outlined
                                : Icons.point_of_sale)),
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        bot.role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bot.description,
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
            if (bot.currentTask != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bot.currentTask!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  backgroundColor: const Color(0xFF1E1E2C),
                  side: const BorderSide(color: Colors.white12),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  label: Text(
                    'Engine: ${bot.engine}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAssignTask,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Assign Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
