import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'agent_provider.dart';
import 'aura_agent_firebase_service.dart';
import 'notification_helper.dart';

class NotificationsModal extends ConsumerStatefulWidget {
  final void Function(String agentUid)? onViewAgent;

  const NotificationsModal({super.key, this.onViewAgent});

  static Future<void> show(BuildContext context, {void Function(String agentUid)? onViewAgent}) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF6C63FF), width: 1.2),
          ),
          child: SizedBox(
            width: 540,
            height: 660,
            child: NotificationsModal(onViewAgent: onViewAgent),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E1E2C),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.90,
            child: NotificationsModal(onViewAgent: onViewAgent),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends ConsumerState<NotificationsModal> {
  String _permStatus = NotificationHelper.permissionStatus;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  void _refreshStatus() {
    if (mounted) {
      setState(() {
        _permStatus = NotificationHelper.permissionStatus;
      });
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
  }

  Future<void> _handleRequestPermission() async {
    final current = NotificationHelper.permissionStatus;
    if (current == 'denied') {
      _showUnblockInstructions();
      return;
    }

    setState(() => _isRequesting = true);
    final newStatus = await NotificationHelper.requestPermission();
    if (mounted) {
      setState(() {
        _isRequesting = false;
        _permStatus = newStatus;
      });

      if (newStatus == 'granted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled successfully!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      } else if (newStatus == 'denied') {
        _showUnblockInstructions();
      }
    }
  }

  void _testAlert() {
    NotificationHelper.playChime();
    NotificationHelper.showSystemNotification(
      title: 'AuraAxon Alerts Working! ??',
      body: 'Device sound and push notifications are active.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chime sound played! Check your device screen & speakers.'),
        backgroundColor: Color(0xFF6C63FF),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showUnblockInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notifications Block ?? ??',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '???? Browser ????? ?? Phone Settings ????? Notifications Block ?? ??? ?????? "Allow" button ????? popup ????. ??????? ??? ????? ??????? ?????:',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '?? Phone ??? (Home Screen / Chrome):',
                      style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. Home Screen ??? ??? AuraAxon Manager icon ?? ????? 2?? Long-press ?? "App info (i)" ??? ????.\n2. "Notifications" ???? "Allow notifications" ON ?????.\n(?? Chrome ??: ? > Settings > Site settings > Notifications > auraaxon-manager.web.app ???? Allow ?????)',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '?? PC ??? (Chrome / Edge):',
                      style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. Address Bar ?? ????? ??? Lock / Settings icon (?? ?? ??) ?????? ?????.\n2. Notifications ????????? ??? option ?? "Allow" ?????.\n3. ?????? Page ?? Refresh (F5) ?????.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _refreshStatus();
            },
            child: const Text('Re-check Status', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK, Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(managerNotificationsStreamProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF252538),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF6C63FF), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              notifsAsync.maybeWhen(
                data: (list) {
                  final unread = list.where((n) => !n.read).length;
                  if (unread == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread new',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const Spacer(),
              notifsAsync.maybeWhen(
                data: (list) {
                  final unreadIds = list.where((n) => !n.read).map((n) => n.id).toList();
                  if (unreadIds.isEmpty) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () {
                      AuraAgentFirebaseService.markAllNotificationsAsRead(unreadIds);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Device Permission & Test Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _permStatus == 'granted'
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : (_permStatus == 'denied'
                    ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.12)),
            border: const Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Icon(
                _permStatus == 'granted'
                    ? Icons.check_circle_rounded
                    : (_permStatus == 'denied'
                        ? Icons.block_rounded
                        : Icons.notification_important_rounded),
                color: _permStatus == 'granted'
                    ? const Color(0xFF10B981)
                    : (_permStatus == 'denied'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B)),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _permStatus == 'granted'
                          ? 'Device Alerts Active'
                          : (_permStatus == 'denied'
                              ? 'Notifications Blocked'
                              : 'Allow Device Notifications'),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _permStatus == 'granted'
                            ? const Color(0xFF10B981)
                            : (_permStatus == 'denied'
                                ? const Color(0xFFEF4444)
                                : Colors.white),
                      ),
                    ),
                    Text(
                      _permStatus == 'granted'
                          ? 'Sound chime & OS notifications are enabled.'
                          : (_permStatus == 'denied'
                              ? 'Browser ????? Block ?? ??. Unblock ?????? ????? ?????.'
                              : 'Tap "Allow" to enable popup alerts on Phone & PC.'),
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_permStatus == 'granted') ...[
                OutlinedButton.icon(
                  onPressed: _testAlert,
                  icon: const Icon(Icons.volume_up_rounded, size: 14),
                  label: const Text('Test', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ] else if (_permStatus == 'denied') ...[
                OutlinedButton.icon(
                  onPressed: _testAlert,
                  icon: const Icon(Icons.volume_up_rounded, size: 14),
                  label: const Text('Sound', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C63FF),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _showUnblockInstructions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Unblock', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _testAlert,
                  icon: const Icon(Icons.volume_up_rounded, size: 14),
                  label: const Text('Sound', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C63FF),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _isRequesting ? null : _handleRequestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isRequesting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Allow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),

        // Body List
        Expanded(
          child: notifsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
            error: (err, _) => Center(
              child: Text('Error loading notifications: $err', style: const TextStyle(color: Colors.redAccent)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 40, color: Colors.white38),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'New agent registrations & system alerts will appear here.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: list.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notif = list[index];
                  final isUnread = !notif.read;

                  return Container(
                    decoration: BoxDecoration(
                      color: isUnread
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.12)
                          : const Color(0xFF252538),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnread ? const Color(0xFF6C63FF).withValues(alpha: 0.6) : Colors.white10,
                        width: isUnread ? 1.4 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? const Color(0xFF6C63FF).withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notif.type == 'new_agent_registration'
                                ? Icons.person_add_alt_1_rounded
                                : Icons.info_outline_rounded,
                            color: isUnread ? const Color(0xFF6C63FF) : Colors.white70,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(notif.createdAt),
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: TextStyle(
                                  color: isUnread ? Colors.white.withValues(alpha: 0.9) : Colors.white60,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (notif.agentUid.isNotEmpty) ...[
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        AuraAgentFirebaseService.markNotificationAsRead(notif.id);
                                        Navigator.of(context).pop();
                                        widget.onViewAgent?.call(notif.agentUid);
                                      },
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                      label: const Text("View", style: TextStyle(fontSize: 11.5)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF6C63FF),
                                        side: const BorderSide(color: Color(0xFF6C63FF)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        visualDensity: VisualDensity.compact,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await AuraAgentFirebaseService.updateAgentStatus(notif.agentUid, "Active");
                                        await AuraAgentFirebaseService.markNotificationAsRead(notif.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("${notif.agentName.isNotEmpty ? notif.agentName : "Agent"} approved & activated!"),
                                              backgroundColor: const Color(0xFF10B981),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.check_circle_outline, size: 14),
                                      label: const Text("Approve & Activate", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        visualDensity: VisualDensity.compact,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (isUnread)
                                    IconButton(
                                      tooltip: 'Mark as read',
                                      icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF6C63FF)),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        AuraAgentFirebaseService.markNotificationAsRead(notif.id);
                                      },
                                    ),
                                  IconButton(
                                    tooltip: 'Delete notification',
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white38),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      AuraAgentFirebaseService.deleteNotification(notif.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
