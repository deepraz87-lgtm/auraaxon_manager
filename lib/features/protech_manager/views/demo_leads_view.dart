import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/pos_firebase_service.dart';


class DemoLeadModel {
  final String id;
  final String businessName;
  final String businessType;
  final String phone;
  final String address;
  final String agentId;
  final DateTime? timestamp;
  final String status;

  DemoLeadModel({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.phone,
    required this.address,
    this.agentId = '',
    this.timestamp,
    this.status = 'New',
  });

  factory DemoLeadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? time;
    if (data['timestamp'] is Timestamp) {
      time = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      time = DateTime.tryParse(data['timestamp']);
    }
    return DemoLeadModel(
      id: doc.id,
      businessName: data['businessName'] ?? 'Unnamed Business',
      businessType: data['businessType'] ?? 'General',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      agentId: data['agentId'] ?? '',
      timestamp: time,
      status: data['status'] ?? 'New',
    );
  }
}

class DemoLeadsView extends StatefulWidget {
  const DemoLeadsView({super.key});

  @override
  State<DemoLeadsView> createState() => _DemoLeadsViewState();
}

class _DemoLeadsViewState extends State<DemoLeadsView> {
  late Future<FirebaseFirestore> _firestoreFuture;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _firestoreFuture = PosFirebaseService.getFirestore();
  }

  Color _getCategoryColor(String type) {
    switch (type.toLowerCase()) {
      case 'grocery':
        return Colors.green;
      case 'footwear':
        return Colors.purple;
      case 'clothing':
        return Colors.pinkAccent;
      case 'electronics':
        return Colors.blue;
      case 'pharmacy':
        return Colors.teal;
      case 'restaurant':
        return Colors.orange;
      case 'hardware':
        return Colors.amber.shade800;
      case 'books':
        return Colors.indigo;
      case 'cosmetics':
        return Colors.purpleAccent;
      case 'auto':
        return Colors.blueGrey;
      default:
        return Colors.cyan;
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'grocery':
        return Icons.storefront;
      case 'footwear':
        return Icons.shopping_bag;
      case 'clothing':
        return Icons.checkroom;
      case 'electronics':
        return Icons.phone_android;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'restaurant':
        return Icons.restaurant;
      case 'hardware':
        return Icons.hardware;
      case 'books':
        return Icons.menu_book;
      case 'cosmetics':
        return Icons.auto_awesome;
      case 'auto':
        return Icons.directions_car;
      default:
        return Icons.store;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseFirestore>(
      future: _firestoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Error connecting to POS database: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final firestore = snapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('demo_leads')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, leadSnapshot) {
            if (leadSnapshot.hasError) {
              return Center(
                child: Text('Error loading leads: ${leadSnapshot.error}',
                    style: const TextStyle(color: Colors.redAccent)),
              );
            }

            if (leadSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = leadSnapshot.data?.docs ?? [];
            final leads = docs.map((d) => DemoLeadModel.fromFirestore(d)).toList();

            final filteredLeads = leads.where((lead) {
              final matchesSearch = lead.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  lead.phone.contains(_searchQuery) ||
                  lead.address.toLowerCase().contains(_searchQuery.toLowerCase());
              if (!matchesSearch) return false;
              if (_selectedFilter == 'All') return true;
              return lead.businessType.toLowerCase() == _selectedFilter.toLowerCase();
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by store name, phone or city...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                          filled: true,
                          fillColor: const Color(0xFF252538),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252538),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          dropdownColor: const Color(0xFF252538),
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Categories')),
                            DropdownMenuItem(value: 'grocery', child: Text('Grocery & Mart')),
                            DropdownMenuItem(value: 'footwear', child: Text('Footwear')),
                            DropdownMenuItem(value: 'clothing', child: Text('Clothing & Fashion')),
                            DropdownMenuItem(value: 'electronics', child: Text('Electronics & Mobile')),
                            DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
                            DropdownMenuItem(value: 'restaurant', child: Text('Restaurant & Cafe')),
                            DropdownMenuItem(value: 'hardware', child: Text('Hardware')),
                            DropdownMenuItem(value: 'books', child: Text('Bookshop')),
                            DropdownMenuItem(value: 'cosmetics', child: Text('Cosmetics')),
                            DropdownMenuItem(value: 'auto', child: Text('Auto Spare Parts')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFilter = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetricCard('Total Inquiries', '${leads.length}', Icons.people, Colors.blueAccent),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      'Today Leads',
                      '${leads.where((l) => l.timestamp != null && l.timestamp!.day == DateTime.now().day).length}',
                      Icons.trending_up,
                      Colors.greenAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      'Unique Categories',
                      '${leads.map((l) => l.businessType).toSet().length}',
                      Icons.category,
                      Colors.purpleAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: filteredLeads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inbox, size: 64, color: Colors.white24),
                              SizedBox(height: 12),
                              Text(
                                'No demo inquiries found',
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredLeads.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final lead = filteredLeads[index];
                            final catColor = _getCategoryColor(lead.businessType);
                            final catIcon = _getCategoryIcon(lead.businessType);

                            return Card(
                              color: const Color(0xFF252538),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: catColor.withOpacity(0.3)),
                              ),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: catColor.withOpacity(0.18),
                                      radius: 26,
                                      child: Icon(catIcon, color: catColor, size: 26),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                lead.businessName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: catColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  lead.businessType.toUpperCase(),
                                                  style: TextStyle(
                                                    color: catColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              if (lead.phone.isNotEmpty) ...[
                                                const Icon(Icons.phone, size: 14, color: Colors.white70),
                                                const SizedBox(width: 4),
                                                SelectableText(
                                                  lead.phone,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                ),
                                                const SizedBox(width: 16),
                                              ],
                                              if (lead.address.isNotEmpty) ...[
                                                const Icon(Icons.location_on, size: 14, color: Colors.white54),
                                                const SizedBox(width: 4),
                                                Text(
                                                  lead.address,
                                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                                ),
                                                const SizedBox(width: 16),
                                              ],
                                              if (lead.agentId.isNotEmpty) ...[
                                                const Icon(Icons.badge_outlined, size: 14, color: Colors.amberAccent),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Agent: ${lead.agentId}',
                                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (lead.timestamp != null)
                                      Text(
                                        '${lead.timestamp!.year}-${lead.timestamp!.month.toString().padLeft(2, '0')}-${lead.timestamp!.day.toString().padLeft(2, '0')} ${lead.timestamp!.hour.toString().padLeft(2, '0')}:${lead.timestamp!.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                                      ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: Colors.blueAccent, size: 20),
                                      tooltip: 'Copy Phone',
                                      onPressed: () {
                                        if (lead.phone.isNotEmpty) {
                                          Clipboard.setData(ClipboardData(text: lead.phone));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Copied ${lead.phone} to clipboard!'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF252538),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 20,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

