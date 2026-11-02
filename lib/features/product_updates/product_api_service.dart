import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_model.dart';

class ProductApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // නිෂ්පාදන ලැයිස්තුව Firebase එකෙන් ලබාගැනීම
  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching products: $e");
      rethrow;
    }
  }

  // නව නිෂ්පාදනයක් Firebase එකට එකතු කිරීම
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      final id = productData['id'];
      await _firestore.collection('products').doc(id).set(productData);
    } catch (e) {
      print("Error adding product: $e");
      rethrow;
    }
  }

  // නිෂ්පාදනයක් මකා දැමීම
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
    } catch (e) {
      print("Error deleting product: $e");
      rethrow;
    }
  }

  // නිෂ්පාදනයක් යාවත්කාලීන කිරීම
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('products').doc(id).update(data);
    } catch (e) {
      print("Error updating product: $e");
      rethrow;
    }
  }
}

// Service එක සඳහා provider එකක්
final productApiServiceProvider = Provider<ProductApiService>((ref) {
  return ProductApiService();
});
