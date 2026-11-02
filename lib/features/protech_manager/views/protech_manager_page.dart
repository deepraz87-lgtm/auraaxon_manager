import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/business_type_provider.dart';
import '../models/business_type_model.dart';

class ProtechManagerPage extends ConsumerWidget {
  const ProtechManagerPage({super.key});

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

  void _showBusinessTypeDialog(BuildContext context, WidgetRef ref, {BusinessTypeModel? existingType}) {
    final nameController = TextEditingController(text: existingType?.name ?? '');
    final Set<String> selectedTabs = Set<String>.from(existingType?.allowedTabs ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252538),
              title: Text(existingType == null ? 'Add Business Type' : 'Edit Business Type', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Type Name',
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                      ),
                      style: const TextStyle(color: Colors.white),
                      enabled: existingType == null, // Name cannot be edited for existing types since it's the ID
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
                          setState(() {
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final newType = BusinessTypeModel(
                        id: name, // Using name as ID
                        name: name,
                        allowedTabs: selectedTabs.toList(),
                      );
                      
                      if (existingType == null) {
                        ref.read(businessTypeControllerProvider).addBusinessType(newType);
                      } else {
                        ref.read(businessTypeControllerProvider).updateBusinessType(newType);
                      }
                      Navigator.pop(context);
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

  void _deleteBusinessType(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252538),
          title: const Text('Delete Business Type', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete "$id"?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                ref.read(businessTypeControllerProvider).deleteBusinessType(id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (isMobile) ...[
                  const Text(
                    'Protech Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showBusinessTypeDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Business Type'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Protech Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showBusinessTypeDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Business Type'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: isMobile ? 16 : 32),
            Expanded(
              child: Container(
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
                          itemCount: types.length,
                          separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (context, index) {
                            final type = types[index];
                            return ListTile(
                              title: Text(type.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Allowed Tabs: ${type.allowedTabs.join(', ')}',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _showBusinessTypeDialog(context, ref, existingType: type),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteBusinessType(context, ref, type.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  error: (err, stack) => Center(
                    child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
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
