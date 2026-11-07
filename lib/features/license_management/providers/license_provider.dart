import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/license_model.dart';
import '../../protech_manager/services/pos_firebase_service.dart';

// Live stream of licenses from Firestore
final licenseStreamProvider = StreamProvider<List<LicenseModel>>((ref) async* {
  final firestore = await PosFirebaseService.getFirestore();
  yield* firestore
      .collection('business_profiles')
      .snapshots()
      .map((snapshot) {
        final List<LicenseModel> licenses = [];
        for (final doc in snapshot.docs) {
          try {
            final data = (doc.data() as Map<String, dynamic>?) ?? {};
            licenses.add(LicenseModel(
              id: doc.id,
              customerName: data['businessName']?.toString() ?? 'Unknown Business',
              productName: 'Auraaxon POS', 
              isActive: data['isActive'] as bool? ?? true,
            ));
          } catch (e) {
            print('Skipping document ${doc.id} due to error: $e');
          }
        }
        return licenses;
      });
});

class LicenseController {
  Future<void> toggleLicenseStatus(String id, bool currentStatus) async {
    try {
      final firestore = await PosFirebaseService.getFirestore();
      await firestore
          .collection('business_profiles')
          .doc(id)
          .set({'isActive': !currentStatus}, SetOptions(merge: true));
    } catch (e) {
      print('Error updating license status: $e');
    }
  }

  Future<void> deleteLicense(String id) async {
    try {
      final firestore = await PosFirebaseService.getFirestore();
      await firestore
          .collection('business_profiles')
          .doc(id)
          .delete();

      try {
        await firestore
            .collection('settings')
            .doc(id)
            .delete();
      } catch (_) {}
    } catch (e) {
      print('Error deleting license: $e');
      rethrow;
    }
  }
}

final licenseControllerProvider = Provider<LicenseController>((ref) {
  return LicenseController();
});
