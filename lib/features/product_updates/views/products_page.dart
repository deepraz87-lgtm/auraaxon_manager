import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../product_provider.dart';
import 'product_details_page.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  // Add Product Dialog එක පෙන්වීම සඳහා
  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final versionController = TextEditingController();
    final priceController = TextEditingController();
    final monthlyFeeController = TextEditingController();
    final descController = TextEditingController();
    final imageController = TextEditingController();
    String selectedCategory = 'Hardware';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252538),
              title: const Text('Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: versionController,
                      decoration: const InputDecoration(
                        labelText: 'Version (e.g. v1.0.0)',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: const Color(0xFF252538),
                      decoration: const InputDecoration(labelText: 'Category'),
                      style: const TextStyle(color: Colors.white),
                      items: ['Hardware', 'Software', 'Accessory', 'Bundle']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price (\$)',
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: monthlyFeeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monthly Fee (\$)',
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        versionController.text.isNotEmpty) {
                      ref
                          .read(productControllerProvider)
                          .addProduct(
                            name: nameController.text,
                            version: versionController.text,
                            category: selectedCategory,
                            price: double.tryParse(priceController.text) ?? 0.0,
                            monthlyFee: double.tryParse(monthlyFeeController.text) ?? 0.0,
                            description: descController.text,
                            imageUrl: imageController.text,
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Product'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productStreamProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            const Text(
              'Products Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage software products, versions, and releases.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddProductDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products Management',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage software products, versions, and release statuses.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
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
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white38),
                          SizedBox(height: 16),
                          Text('No products found', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Click "Add Product" to create one', style: TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
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
                      DataColumn(label: Text('Product ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Current Version')),
                      DataColumn(label: Text('Monthly Fee')),
                      DataColumn(label: Text('Release Date')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: products.map((product) {
                      return DataRow(
                        onSelectChanged: (_) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsPage(product: product),
                            ),
                          );
                        },
                        cells: [
                          DataCell(Text(product.id)),
                          DataCell(Text(product.name)),
                          DataCell(Text(product.version)),
                          DataCell(Text('\${product.monthlyFee.toStringAsFixed(2)}')),
                          DataCell(Text(product.releaseDate)),
                          DataCell(
                            Text(
                              product.status,
                              style: TextStyle(
                                color: product.status == 'Active'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
