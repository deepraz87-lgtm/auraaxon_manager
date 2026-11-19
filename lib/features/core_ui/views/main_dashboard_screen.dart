import '../../../services/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../license_management/views/licenses_page.dart';
import '../../product_updates/views/products_page.dart';
import '../../aura_agents/agents_management_page.dart';
import '../../system_design/views/system_design_page.dart';
import '../../protech_manager/views/protech_manager_page.dart';
import '../../whatsapp_server/views/whatsapp_server_page.dart';
import '../../aura_operations/views/aura_operations_hub_page.dart';
import '../../live_voice/views/live_voice_session_modal.dart';
import '../../aura_agents/agent_provider.dart';
import '../../aura_agents/notification_helper.dart';
import '../../aura_agents/notifications_modal.dart';
import '../../aura_agents/aura_agent_firebase_service.dart';

class _DestinationItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  const _DestinationItem(this.title, this.icon, this.selectedIcon);
}

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  int _selectedIndex = 0;
  final Set<String> _seenNotificationIds = {};
  bool _hasInitializedNotifications = false;

  static const List<_DestinationItem> _destinations = [
    _DestinationItem('Licenses', Icons.vpn_key_outlined, Icons.vpn_key),
    _DestinationItem('Products', Icons.inventory_2_outlined, Icons.inventory),
    _DestinationItem('Aura Agents', Icons.groups_outlined, Icons.groups),
    _DestinationItem('Analytics', Icons.analytics_outlined, Icons.analytics),
    _DestinationItem('Architecture', Icons.architecture_outlined, Icons.architecture),
    _DestinationItem('Protech Manager', Icons.business_center_outlined, Icons.business_center),
    _DestinationItem('WhatsApp AI', Icons.message_outlined, Icons.message),
    _DestinationItem('Aura AI Ops', Icons.hub_outlined, Icons.hub),
    _DestinationItem('Settings', Icons.settings_outlined, Icons.settings),
  ];

  final List<Widget> _pages = [
    const LicensesPage(),
    const ProductsPage(),
    const AgentsManagementPage(),
    const Center(
      child: Text('Marketing Analytics', style: TextStyle(fontSize: 24, color: Colors.white)),
    ),
    const SystemDesignPage(),
    const ProtechManagerPage(),
    const WhatsAppServerPage(),
    const AuraOperationsHubPage(),
    const Center(child: Text('Settings', style: TextStyle(fontSize: 24, color: Colors.white))),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHelper.requestPermission();
      AppUpdateService.checkForUpdates(context, silent: true);
    });
  }

  void _onViewAgent(String agentUid) {
    setState(() {
      _selectedIndex = 2; // Agents Management Page
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final isExtended = screenWidth >= 1100;

    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    // Real-time listener for incoming manager notifications (Phone & PC)
    ref.listen(managerNotificationsStreamProvider, (prev, next) {
      next.whenData((notifs) {
        if (!_hasInitializedNotifications) {
          // On first load, seed existing notification IDs to avoid alerting old history
          for (final n in notifs) {
            _seenNotificationIds.add(n.id);
          }
          _hasInitializedNotifications = true;
          return;
        }

        for (final notif in notifs) {
          if (!notif.read && !_seenNotificationIds.contains(notif.id)) {
            _seenNotificationIds.add(notif.id);

            // 1. Play real-time audio chime on device
            NotificationHelper.playChime();

            // 2. Trigger native OS / Browser system toast (Windows & Android Phone)
            NotificationHelper.showSystemNotification(
              title: notif.title,
              body: notif.message,
            );

            // 3. Show in-app interactive notification banner
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF252538),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  duration: const Duration(seconds: 7),
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C63FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notif.message,
                              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  action: SnackBarAction(
                    label: 'VIEW AGENT',
                    textColor: const Color(0xFF6C63FF),
                    onPressed: () {
                      AuraAgentFirebaseService.markNotificationAsRead(notif.id);
                      _onViewAgent(notif.agentUid);
                    },
                  ),
                ),
              );
            }
          }
        }
      });
    });

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF252538),
          elevation: 0,
          title: Row(
            children: [
              Image.asset(
                'assets/images/auraaxon_icon.png',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 10),
              Text(
                _destinations[_selectedIndex].title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            // Mobile Notification Bell with Live Counter Badge
            IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
              tooltip: 'Notifications',
              onPressed: () => NotificationsModal.show(context, onViewAgent: _onViewAgent),
            ),
            IconButton(
              icon: const Icon(Icons.record_voice_over, color: Color(0xFF6C63FF)),
              tooltip: 'Aura Live Voice',
              onPressed: () => LiveVoiceSessionModal.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'Logout',
              onPressed: () {
                ref.read(authControllerProvider).signOut();
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF1E1E2C),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/auraaxon_icon.png',
                        width: 44,
                        height: 44,
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AuraAxon',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Manager Portal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: unreadCount > 0,
                          label: Text('$unreadCount'),
                          backgroundColor: Colors.redAccent,
                          child: const Icon(Icons.notifications_outlined, color: Colors.white70),
                        ),
                        tooltip: 'Notifications',
                        onPressed: () {
                          Navigator.pop(context);
                          NotificationsModal.show(context, onViewAgent: _onViewAgent);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    itemCount: _destinations.length,
                    itemBuilder: (context, index) {
                      final item = _destinations[index];
                      final isSelected = _selectedIndex == index;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : Colors.white70,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: (item.title == 'Aura Agents' && unreadCount > 0)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                )
                              : null,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.record_voice_over, color: Color(0xFF6C63FF)),
                  title: const Text('Live Voice Call', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    LiveVoiceSessionModal.show(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authControllerProvider).signOut();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        body: _pages[_selectedIndex],
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: isExtended ? 250 : 80,
            color: const Color(0xFF252538),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 18.0,
                      horizontal: isExtended ? 16.0 : 8.0,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white12)),
                    ),
                    child: isExtended
                        ? Row(
                            children: [
                              Image.asset(
                                'assets/images/auraaxon_icon.png',
                                width: 38,
                                height: 38,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AuraAxon',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Manager Portal',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // PC Notification Bell
                              IconButton(
                                icon: Badge(
                                  isLabelVisible: unreadCount > 0,
                                  label: Text('$unreadCount'),
                                  backgroundColor: Colors.redAccent,
                                  child: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
                                ),
                                tooltip: 'Notifications',
                                onPressed: () => NotificationsModal.show(context, onViewAgent: _onViewAgent),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Image.asset(
                                'assets/images/auraaxon_icon.png',
                                width: 36,
                                height: 36,
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                icon: Badge(
                                  isLabelVisible: unreadCount > 0,
                                  label: Text('$unreadCount'),
                                  backgroundColor: Colors.redAccent,
                                  child: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
                                ),
                                tooltip: 'Notifications',
                                onPressed: () => NotificationsModal.show(context, onViewAgent: _onViewAgent),
                              ),
                            ],
                          ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      itemCount: _destinations.length,
                      itemBuilder: (context, index) {
                        final item = _destinations[index];
                        final isSelected = _selectedIndex == index;
                        final isAgentsTab = item.title == 'Aura Agents';

                        if (isExtended) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: isSelected
                                    ? const Color(0xFF6C63FF)
                                    : Colors.white70,
                              ),
                              title: Text(
                                item.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: (isAgentsTab && unreadCount > 0)
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    )
                                  : null,
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Tooltip(
                              message: item.title,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: isAgentsTab && unreadCount > 0
                                      ? Badge(
                                          label: Text('$unreadCount'),
                                          backgroundColor: Colors.redAccent,
                                          child: Icon(
                                            isSelected ? item.selectedIcon : item.icon,
                                            color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                                          ),
                                        )
                                      : Icon(
                                          isSelected ? item.selectedIcon : item.icon,
                                          color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                                        ),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExtended)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.record_voice_over, size: 18),
                              label: const Text('Live Voice'),
                              onPressed: () => LiveVoiceSessionModal.show(context),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.record_voice_over, color: Color(0xFF6C63FF)),
                            tooltip: 'Live Voice Call',
                            onPressed: () => LiveVoiceSessionModal.show(context),
                          ),
                        const SizedBox(height: 6),
                        if (isExtended)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                              label: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              onPressed: () {
                                ref.read(authControllerProvider).signOut();
                              },
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.redAccent),
                            tooltip: 'Logout',
                            onPressed: () {
                              ref.read(authControllerProvider).signOut();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.black26),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
