import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/license_provider.dart';
import '../models/license_model.dart';
import 'customer_details_page.dart';

class LicensesPage extends ConsumerWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licensesAsync = ref.watch(licenseStreamProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'License Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your customers active and pending licenses.',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 16),
            const TabBar(
              tabs: [
                Tab(text: 'Pending Requests'),
                Tab(text: 'Active Licenses'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF252538),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: licensesAsync.when(
                  data: (licenses) {
                    final pendingLicenses = licenses
                        .where((l) => !l.isActive)
                        .toList();
                    final activeLicenses = licenses
                        .where((l) => l.isActive)
                        .toList();

                    return TabBarView(
                      children: [
                        _buildLicensesTable(
                          context,
                          ref,
                          pendingLicenses,
                          isPending: true,
                        ),
                        _buildLicensesTable(
                          context,
                          ref,
                          activeLicenses,
                          isPending: false,
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: SingleChildScrollView(
                      child: Text(
                        'Error: $error\n\nStack:\n$stack',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicensesTable(
    BuildContext context,
    WidgetRef ref,
    List<LicenseModel> licenses, {
    required bool isPending,
  }) {
    if (licenses.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending requests.' : 'No active licenses.',
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
        showCheckboxColumn: false,
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        columns: const [
          DataColumn(label: Text('License ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: licenses.map((license) {
          return DataRow(
            onSelectChanged: (selected) {
              if (selected == true) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerDetailsPage(license: license),
                  ),
                );
              }
            },
            cells: [
              DataCell(Text(license.id)),
              DataCell(Text(license.customerName)),
              DataCell(Text(license.productName)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: license.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    license.isActive ? 'Active' : 'Pending',
                    style: TextStyle(
                      color: license.isActive
                          ? Colors.green
                          : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: license.isActive
                        ? Colors.red.shade400
                        : Colors.green.shade400,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => ref
                      .read(licenseControllerProvider)
                      .toggleLicenseStatus(license.id, license.isActive),
                  child: Text(license.isActive ? 'Suspend' : 'Approve'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ),
  );
}
}
