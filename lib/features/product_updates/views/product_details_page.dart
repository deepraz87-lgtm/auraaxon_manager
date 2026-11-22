import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../product_model.dart';
import '../product_provider.dart';

class ProductDetailsPage extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _versionController;
  late TextEditingController _priceController;
  late TextEditingController _monthlyFeeController;
  late TextEditingController _descController;
  late TextEditingController _imageController;
  late String _selectedCategory;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _versionController = TextEditingController(text: widget.product.version);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _monthlyFeeController = TextEditingController(text: widget.product.monthlyFee.toString());
    _descController = TextEditingController(text: widget.product.description);
    _imageController = TextEditingController(text: widget.product.imageUrl);
    
    _selectedCategory = widget.product.category.isNotEmpty ? widget.product.category : 'Software';
    if (!['Hardware', 'Software', 'Accessory', 'Bundle'].contains(_selectedCategory)) {
      _selectedCategory = 'Software';
    }

    _selectedStatus = widget.product.status.isNotEmpty ? widget.product.status : 'Active';
    if (!['Active', 'Inactive'].contains(_selectedStatus)) {
      _selectedStatus = 'Active';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _versionController.dispose();
    _priceController.dispose();
    _monthlyFeeController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedData = {
      'name': _nameController.text,
      'version': _versionController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'monthly_fee': double.tryParse(_monthlyFeeController.text) ?? 0.0,
      'description': _descController.text,
      'image_url': _imageController.text,
      'category': _selectedCategory,
      'status': _selectedStatus,
    };

    ref.read(productControllerProvider).updateProduct(widget.product.id, updatedData);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252538),
          title: const Text('Delete Product', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete ${widget.product.name}?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                ref.read(productControllerProvider).deleteProduct(widget.product.id);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to products list
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
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text('${widget.product.name} Details'),
        backgroundColor: const Color(0xFF252538),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteProduct,
            tooltip: 'Delete Product',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _versionController,
                decoration: const InputDecoration(labelText: 'Version', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: const Color(0xFF252538),
                      decoration: const InputDecoration(labelText: 'Category', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                      style: const TextStyle(color: Colors.white),
                      items: ['Hardware', 'Software', 'Accessory', 'Bundle']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      dropdownColor: const Color(0xFF252538),
                      decoration: const InputDecoration(labelText: 'Status', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                      style: const TextStyle(color: Colors.white),
                      items: ['Active', 'Inactive']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (\$)', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _monthlyFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monthly Fee (\$)', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'Image URL', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
