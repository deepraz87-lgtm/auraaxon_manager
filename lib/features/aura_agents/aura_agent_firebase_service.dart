import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuraAgentFirebaseService {
  static FirebaseApp? _agentApp;

  static const FirebaseOptions agentOptions = FirebaseOptions(
    apiKey: 'AIzaSyC22HGmj1WNjQyOfezLiBZLWj6HshKghes',
    appId: '1:171521102897:web:a5d8d21a2e5883a7703110',
    messagingSenderId: '171521102897',
    projectId: 'aura-agent-portal',
    authDomain: 'aura-agent-portal.firebaseapp.com',
    storageBucket: 'aura-agent-portal.firebasestorage.app',
  );

  static Future<FirebaseApp> getAgentApp() async {
    if (_agentApp != null) return _agentApp!;
    try {
      _agentApp = Firebase.app('AURA_AGENT_PORTAL');
    } catch (_) {
      try {
        _agentApp = await Firebase.initializeApp(
          name: 'AURA_AGENT_PORTAL',
          options: agentOptions,
        );
      } catch (e) {
        debugPrint('Error initializing secondary app AURA_AGENT_PORTAL: $e');
        _agentApp = Firebase.app('AURA_AGENT_PORTAL');
      }
    }

    try {
      final auth = FirebaseAuth.instanceFor(app: _agentApp!);
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('AURA_AGENT_PORTAL anonymous auth notice: $e');
    }

    return _agentApp!;
  }

  static Future<FirebaseFirestore> getFirestore() async {
    final app = await getAgentApp();
    return FirebaseFirestore.instanceFor(app: app);
  }

  static Future<void> updateAgentStatus(String agentId, String newStatus) async {
    try {
      final firestore = await getFirestore();
      await firestore.collection('agents').doc(agentId).update({'status': newStatus});
    } catch (e) {
      debugPrint('Error updating secondary agent status: $e');
    }

    try {
      await FirebaseFirestore.instance.collection('agents').doc(agentId).update({'status': newStatus});
    } catch (_) {}
  }

  static Future<void> updateLeadStatus(String leadId, String newStatus) async {
    final updateData = {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      final firestore = await getFirestore();
      await firestore.collection('leads').doc(leadId).update(updateData);
    } catch (e) {
      debugPrint('Error updating secondary lead status: $e');
    }

    try {
      await FirebaseFirestore.instance.collection('leads').doc(leadId).update(updateData);
    } catch (_) {}
  }
}