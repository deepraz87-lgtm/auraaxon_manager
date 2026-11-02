import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_type_model.dart';

final businessTypeStreamProvider = StreamProvider<List<BusinessTypeModel>>((ref) {
  return FirebaseFirestore.instance.collection('business_types').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => BusinessTypeModel.fromJson(doc.id, doc.data())).toList();
  });
});

class BusinessTypeController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBusinessType(BusinessTypeModel businessType) async {
    try {
      await _firestore.collection('business_types').doc(businessType.name).set(businessType.toJson());
    } catch (e) {
      print('Error adding business type: $e');
      rethrow;
    }
  }

  Future<void> updateBusinessType(BusinessTypeModel businessType) async {
    try {
      await _firestore.collection('business_types').doc(businessType.id).update(businessType.toJson());
    } catch (e) {
      print('Error updating business type: $e');
      rethrow;
    }
  }

  Future<void> deleteBusinessType(String id) async {
    try {
      await _firestore.collection('business_types').doc(id).delete();
    } catch (e) {
      print('Error deleting business type: $e');
      rethrow;
    }
  }
}

final businessTypeControllerProvider = Provider<BusinessTypeController>((ref) {
  return BusinessTypeController();
});
