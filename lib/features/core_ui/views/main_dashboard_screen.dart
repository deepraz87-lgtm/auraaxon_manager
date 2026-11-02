import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../license_management/views/licenses_page.dart';
import '../../product_updates/views/products_page.dart';
import '../../auth/providers/auth_provider.dart';
import '../../system_design/views/system_design_page.dart';
import '../../protech_manager/views/protech_manager_page.dart';
import '../../whatsapp_server/views/whatsapp_server_page.dart';
import '../../aura_operations/views/aura_operations_hub_page.dart';

class _DestinationItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  const _DestinationItem(this.title, this.icon, this.selectedIcon);
}

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  int _selectedIndex = 0;

  static const List<_DestinationItem> _destinations = [
    _DestinationItem('Licenses', Icons.vpn_key_outlined, Icons.vpn_key),
    _DestinationItem('Products', Icons.inventory_2_outlined, Icons.inventory),
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
    const Center(
      child: Text('Marketing Analytics', style: TextStyle(fontSize: 24)),
    ),
    const SystemDesignPage(),
    const ProtechManagerPage(),
    const WhatsAppServerPage(),
    const AuraOperationsHubPage(),
    const Center(child: Text('Settings', style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final isExtended = screenWidth >= 1100;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF252538),
          elevation: 0,
          title: Text(
            _destinations[_selectedIndex].title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.hub_outlined,
                          color: Color(0xFF6C63FF),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auraaxon',
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
          NavigationRail(
            backgroundColor: const Color(0xFF252538),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: isExtended,
            destinations: _destinations.map((d) {
              return NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.title),
              );
            }).toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: isExtended
                      ? TextButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                          onPressed: () {
                            ref.read(authControllerProvider).signOut();
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          tooltip: 'Logout',
                          onPressed: () {
                            ref.read(authControllerProvider).signOut();
                          },
                        ),
                ),
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
