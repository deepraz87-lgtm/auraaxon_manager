import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class PosFirebaseService {
  static FirebaseApp? _posApp;

  static const FirebaseOptions posOptions = FirebaseOptions(
    apiKey: 'AIzaSyC4kUTH8yXd-Ot5jLKIXijEW90h5rsWp_I',
    appId: '1:226275864520:web:b741894fb2d85f30ae5afd',
    messagingSenderId: '226275864520',
    projectId: 'pos-system-1-49ec7',
    authDomain: 'pos-system-1-49ec7.firebaseapp.com',
    storageBucket: 'pos-system-1-49ec7.firebasestorage.app',
  );

  static Future<FirebaseApp> getPosApp() async {
    if (_posApp != null) return _posApp!;
    try {
      _posApp = Firebase.app('POS_PROJECT');
    } catch (_) {
      try {
        _posApp = await Firebase.initializeApp(
          name: 'POS_PROJECT',
          options: posOptions,
        );
      } catch (e) {
        debugPrint('Error initializing POS secondary app: $e');
        _posApp = Firebase.app('POS_PROJECT');
      }
    }
    return _posApp!;
  }

  static Future<FirebaseFirestore> getFirestore() async {
    final app = await getPosApp();
    return FirebaseFirestore.instanceFor(app: app);
  }
}
