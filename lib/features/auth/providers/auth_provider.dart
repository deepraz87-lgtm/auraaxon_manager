import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase Auth Instance Provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Auth State Provider (Listens to user login/logout)
final authStateProvider = StreamProvider<User?>((ref) async* {
  final authStream = ref.watch(firebaseAuthProvider).authStateChanges();
  await for (final user in authStream) {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data()?['role'] == 'Admin') {
          yield user;
        } else {
          // Not an admin, sign out immediately
          await FirebaseAuth.instance.signOut();
          yield null;
        }
      } catch (e) {
        // Error fetching admin status, default to sign out
        await FirebaseAuth.instance.signOut();
        yield null;
      }
    } else {
      yield null;
    }
  }
});

// Auth Controller to handle login and logout actions
class AuthController {
  final FirebaseAuth _auth;

  AuthController(this._auth);

  Future<void> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists || doc.data()?['role'] != 'Admin') {
          // authStateProvider will handle the actual signOut to prevent concurrent crash
          throw Exception("Access Denied: You do not have admin privileges.");
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthController(auth);
});
