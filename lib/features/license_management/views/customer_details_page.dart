import 'package:flutter/material.dart';
import '../../protech_manager/services/pos_firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/license_model.dart';

// Provider to fetch the specific customer document in real-time
final customerProfileProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, id) {
      return FirebaseFirestore.instance
          .collection('business_profiles')
          .doc(id)
          .snapshots()
          .map((doc) => doc.data());
    });

class CustomerDetailsPage extends ConsumerWidget {
  final LicenseModel license;

  const CustomerDetailsPage({super.key, required this.license});

  Future<void> _editBusinessType(
    BuildContext context,
    String id,
    String currentType,
  ) async {
    final List<String> businessTypes = [
      'Mobile Phone Shop',
      'Restaurant / Cafe',
      'Grocery / Supermarket',
      'Pharmacy',
      'Electronics',
      'Clothing / Apparel',
      'Hardware / Construction',
      'Service Center',
      'Other',
    ];

    String selectedType = businessTypes.contains(currentType)
        ? currentType
        : 'Other';

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempType = selectedType;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252538),
              title: const Text(
                'Edit Business Type',
                style: TextStyle(color: Colors.white),
              ),
              content: DropdownButtonFormField<String>(
                value: tempType,
                dropdownColor: const Color(0xFF1E1E2C),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                items: businessTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => tempType = val);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempType),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result != currentType) {
      try {
        await FirebaseFirestore.instance
            .collection('business_profiles')
            .doc(id)
            .update({'businessType': result});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business Type updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProfileProvider(license.id));

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text('${license.customerName} Details'),
        backgroundColor: const Color(0xFF252538),
        elevation: 0,
      ),
      body: customerAsync.when(
        data: (data) {
          if (data == null) {
            return const Center(
              child: Text(
                'Customer data not found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Convert data map to a list of entries for easy display
          final mutableData = Map<String, dynamic>.from(data);
          if (!mutableData.containsKey('businessType')) {
            mutableData['businessType'] = 'Not Set';
          }

          final entries = mutableData.entries.toList();
          entries.sort((a, b) => a.key.compareTo(b.key));

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      license.customerName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: license.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: license.isActive
                              ? Colors.green
                              : Colors.redAccent,
                        ),
                      ),
                      child: Text(
                        license.isActive
                            ? 'Active License'
                            : 'Suspended License',
                        style: TextStyle(
                          color: license.isActive
                              ? Colors.green
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252538),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (entry.key == 'businessType')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blueAccent,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _editBusinessType(
                                          context,
                                          license.id,
                                          entry.value.toString(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
