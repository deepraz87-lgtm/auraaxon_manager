import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';
import 'product_api_service.dart';

// Live stream of products from Firestore
final productStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  return FirebaseFirestore.instance.collection('products').snapshots().map((snapshot) {
    final List<ProductModel> products = [];
    for (final doc in snapshot.docs) {
      try {
        final data = Map<String, dynamic>.from(doc.data());
        if (!data.containsKey('id') || data['id'] == null || data['id'].toString().isEmpty) {
          data['id'] = doc.id;
        }
        products.add(ProductModel.fromJson(data));
      } catch (e) {
        print('Skipping document ${doc.id} due to error: $e');
      }
    }
    return products;
  });
});

class ProductController {
  final ProductApiService apiService;

  ProductController(this.apiService);

  // අලුත් නිෂ්පාදනයක් එකතු කිරීම සඳහා
  Future<void> addProduct({
    required String name,
    required String version,
    required String category,
    required double price,
    required double monthlyFee,
    required String description,
    required String imageUrl,
    String warranty = '',
    String specs = '',
    String condition = 'Brand New',
    List<Map<String, dynamic>> variants = const [],
  }) async {
    try {
      final newId = 'API-PRD-${DateTime.now().millisecondsSinceEpoch}';

      final productData = {
        'id': newId,
        'name': name,
        'version': version,
        'status': 'Active',
        'releaseDate': DateTime.now().toString().split(' ')[0],
        'category': category,
        'price': price,
        'monthly_fee': monthlyFee,
        'description': description,
        'image_url': imageUrl,
        'warranty': warranty,
        'specs': specs,
        'condition': condition,
        'variants': variants,
      };

      await apiService.addProduct(productData);
    } catch (e) {
      print('Error adding product: $e');
    }
  }

  // නිෂ්පාදනයක් මකා දැමීම
  Future<void> deleteProduct(String id) async {
    try {
      await apiService.deleteProduct(id);
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  // නිෂ්පාදනයක් යාවත්කාලීන කිරීම
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await apiService.updateProduct(id, data);
    } catch (e) {
      print('Error updating product: $e');
    }
  }
}

final productControllerProvider = Provider<ProductController>((ref) {
  final apiService = ref.read(productApiServiceProvider);
  return ProductController(apiService);
});