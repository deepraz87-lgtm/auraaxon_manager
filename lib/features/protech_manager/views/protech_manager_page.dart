import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/business_type_provider.dart';
import '../models/business_type_model.dart';
import 'demo_leads_view.dart';

class ProtechManagerPage extends ConsumerStatefulWidget {
  const ProtechManagerPage({super.key});

  @override
  ConsumerState<ProtechManagerPage> createState() => _ProtechManagerPageState();
}

class _ProtechManagerPageState extends ConsumerState<ProtechManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const Map<String, IconData> availableIcons = {
    'storefront': Icons.storefront,
    'shopping_bag': Icons.shopping_bag,
    'checkroom': Icons.checkroom,
    'phone_android': Icons.phone_android,
    'local_pharmacy': Icons.local_pharmacy,
    'restaurant': Icons.restaurant,
    'hardware': Icons.hardware,
    'menu_book': Icons.menu_book,
    'auto_awesome': Icons.auto_awesome,
    'directions_car': Icons.directions_car,
    'store': Icons.store,
    'shopping_cart': Icons.shopping_cart,
    'computer': Icons.computer,
    'build': Icons.build,
    'local_hospital': Icons.local_hospital,
    'fitness_center': Icons.fitness_center,
    'local_cafe': Icons.local_cafe,
  };

  static IconData getBusinessTypeIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.storefront;
    return availableIcons[iconName.toLowerCase()] ?? Icons.storefront;
  }

  final List<String> availableTabs = const [
    'Dashboard',
    'Sales',
    'Repairs',
    'Inventory',
    'Reports',
    'People',
    'Settings',
    'AI Agent',
  ];

  void _showBusinessTypeDialog(BuildContext context, {BusinessTypeModel? existingType}) {
    final nameController = TextEditingController(text: existingType?.name ?? '');
    String selectedIcon = existingType?.icon ?? 'storefront';
    if (!availableIcons.containsKey(selectedIcon)) {
      selectedIcon = 'storefront';
    }
    final Set<String> selectedTabs = Set<String>.from(existingType?.allowedTabs ?? []);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252538),
              title: Text(
                existingType == null ? 'Add Business Type' : 'Edit Business Type',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Type Name',
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                      ),
                      style: const TextStyle(color: Colors.white),
                      enabled: existingType == null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      dropdownColor: const Color(0xFF252538),
                      decoration: const InputDecoration(
                        labelText: 'Category Icon',
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                      ),
                      items: availableIcons.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.value, color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 10),
                              Text(entry.key, style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedIcon = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Allowed Tabs:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...availableTabs.map((tab) {
                      return CheckboxListTile(
                        title: Text(tab, style: const TextStyle(color: Colors.white70)),
                        value: selectedTabs.contains(tab),
                        checkColor: Colors.white,
                        activeColor: Colors.blueAccent,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedTabs.add(tab);
                            } else {
                              selectedTabs.remove(tab);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final newType = BusinessTypeModel(
                        id: name,
                        name: name,
                        icon: selectedIcon,
                        allowedTabs: selectedTabs.toList(),
                      );
                      
                      if (existingType == null) {
                        ref.read(businessTypeControllerProvider).addBusinessType(newType);
                      } else {
                        ref.read(businessTypeControllerProvider).updateBusinessType(newType);
                      }
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: Text(existingType == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteBusinessType(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252538),
          title: const Text('Delete Business Type', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete "?', style: const TextStyle(color: Colors.white70)),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(dialogCtx),
 child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
 ),
 ElevatedButton(
 style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
 onPressed: () {
 ref.read(businessTypeControllerProvider).deleteBusinessType(id);
 Navigator.pop(dialogCtx);
 },
 child: const Text('Delete', style: TextStyle(color: Colors.white)),
 ),
 ],
 );
 },
 );
 }

 @override
 Widget build(BuildContext context) {
 final businessTypesAsync = ref.watch(businessTypeStreamProvider);

 return Scaffold(
 backgroundColor: const Color(0xFF1E1E2C),
 body: LayoutBuilder(
 builder: (context, constraints) {
 final isMobile = constraints.maxWidth < 600;
 return Padding(
 padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Protech Manager Hub',
 style: TextStyle(
 color: Colors.white,
 fontSize: isMobile ? 22 : 28,
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height: 4),
 const Text(
 'Manage POS configurations & live demo customer inquiries',
 style: TextStyle(color: Colors.white54, fontSize: 13),
 ),
 ],
 ),
 ElevatedButton.icon(
 onPressed: () => _showBusinessTypeDialog(context),
 icon: const Icon(Icons.add),
 label: const Text('Add Business Type'),
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF6C63FF),
 foregroundColor: Colors.white,
 padding: EdgeInsets.symmetric(
 horizontal: isMobile ? 14 : 20,
 vertical: isMobile ? 10 : 12,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 20),
 Container(
 decoration: BoxDecoration(
 color: const Color(0xFF252538),
 borderRadius: BorderRadius.circular(12),
 ),
 child: TabBar(
 controller: _tabController,
 indicatorColor: const Color(0xFF6C63FF),
 indicatorWeight: 3,
 labelColor: Colors.white,
 unselectedLabelColor: Colors.white54,
 labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
 tabs: const [
 Tab(
 icon: Icon(Icons.hub_outlined),
 text: 'Business Types & Tabs',
 ),
 Tab(
 icon: Icon(Icons.contact_mail_outlined),
 text: 'Live Demo Leads & Inquiries',
 ),
 ],
 ),
 ),
 const SizedBox(height: 16),
 Expanded(
 child: TabBarView(
 controller: _tabController,
 children: [
 Container(
 width: double.infinity,
 decoration: BoxDecoration(
 color: const Color(0xFF252538),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: Colors.white12),
 ),
 child: businessTypesAsync.when(
 data: (types) => types.isEmpty
 ? const Center(
 child: Text(
 'No business types found.',
 style: TextStyle(color: Colors.white54, fontSize: 16),
 ),
 )
 : ListView.separated(
 padding: const EdgeInsets.all(16),
 itemCount: types.length,
 separatorBuilder: (context, index) => const Divider(color: Colors.white12),
 itemBuilder: (context, index) {
 final type = types[index];
 return ListTile(
 leading: Container(
 width: 44,
 height: 44,
 decoration: BoxDecoration(
 color: const Color(0xFF6C63FF).withOpacity(0.18),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
 ),
 child: Icon(
 getBusinessTypeIcon(type.icon),
 color: const Color(0xFF9D96FF),
 size: 24,
 ),
 ),
 title: Text(
 type.name,
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
 ),
 subtitle: Padding(
 padding: const EdgeInsets.only(top: 8.0),
 child: Wrap(
 spacing: 6,
 runSpacing: 6,
 children: type.allowedTabs.map((tab) {
 return Chip(
 label: Text(tab, style: const TextStyle(color: Colors.white70, fontSize: 12)),
 backgroundColor: Colors.white.withOpacity(0.08),
 padding: EdgeInsets.zero,
 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
 );
 }).toList(),
 ),
 ),
 trailing: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 IconButton(
 icon: const Icon(Icons.edit, color: Colors.blueAccent),
 onPressed: () => _showBusinessTypeDialog(context, existingType: type),
 ),
 IconButton(
 icon: const Icon(Icons.delete, color: Colors.redAccent),
 onPressed: () => _deleteBusinessType(context, type.id),
 ),
 ],
 ),
 );
 },
 ),
 loading: () => const Center(child: CircularProgressIndicator()),
 error: (error, stack) => Center(
 child: Text(
 'Error: ',
 style: const TextStyle(color: Colors.redAccent),
 ),
 ),
 ),
 ),
 const DemoLeadsView(),
 ],
 ),
 ),
 ],
 ),
 );
 },
 ),
 );
 }
}
