import '../../services/aura_notification_service.dart';
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

  static Future<void> updateAgentRole(String agentId, String newRole) async {
    int certLevel = 0;
    String certStatus = 'locked';
    if (newRole == 'Agent Manager') {
      certLevel = 3;
      certStatus = 'certified';
    } else if (newRole == 'Sales & Setup Agent') {
      certLevel = 2;
      certStatus = 'certified';
    } else if (newRole == 'Sales Agent') {
      certLevel = 1;
      certStatus = 'certified';
    } else {
      certLevel = 0;
      certStatus = 'locked';
    }

    final updateData = <String, dynamic>{
      'role': newRole,
      'certificationLevel': certLevel,
      'certificationStatus': certStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. Update in secondary Firestore (aura-agent-portal)
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('agents').doc(agentId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating secondary agent role: $e');
    }

    // 2. Update in primary/local Manager Firestore
    try {
      await FirebaseFirestore.instance.collection('agents').doc(agentId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating local agent role: $e');
    }
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

    // When an agent is approved/activated (hired), clear their registration notifications
    if (newStatus.trim().toLowerCase() == 'active' || newStatus.trim().toLowerCase() == 'approved') {
      await clearNotificationsForAgent(agentId);
    }
  }

  static Future<void> clearNotificationsForAgent(String agentId) async {
    final cleanId = agentId.trim();
    if (cleanId.isEmpty) return;

    Future<void> clearFromDb(FirebaseFirestore db) async {
      try {
        final notifs = await db.collection('manager_notifications').get();
        for (final doc in notifs.docs) {
          final data = doc.data();
          final uid = (data['agentUid'] ?? '').toString().trim();
          final aId = (data['agentId'] ?? '').toString().trim();

          if (uid == cleanId || aId == cleanId || doc.id == cleanId) {
            await doc.reference.delete();
            AuraNotificationService.cancelNotification(doc.id);
          }
        }
      } catch (e) {
        debugPrint('Error clearing notifications for agent $cleanId: $e');
      }
    }

    try {
      final secFirestore = await getFirestore();
      await clearFromDb(secFirestore);
    } catch (_) {}

    try {
      await clearFromDb(FirebaseFirestore.instance);
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

  static Future<void> approveAgentIdRequest({
    required String requestId,
    required String agentUid,
    required String requestedAgentId,
    String adminNotes = '',
  }) async {
    final cleanId = requestedAgentId.trim().toUpperCase();
    final requestUpdates = <String, dynamic>{
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': 'AuraAxon Operations Admin',
      if (adminNotes.trim().isNotEmpty) 'adminNotes': adminNotes.trim(),
    };

    final agentUpdates = <String, dynamic>{
      'agentId': cleanId,
      'agent_id': cleanId,
      'agentIdChangesLeft': 0,
      'pendingIdRequest': {
        'requestId': requestId,
        'requestedAgentId': cleanId,
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'AuraAxon Operations Admin',
        if (adminNotes.trim().isNotEmpty) 'adminNotes': adminNotes.trim(),
      },
      'pendingIdRequest.status': FieldValue.delete(),
      'pendingIdRequest.reviewedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. Update in secondary Firestore (aura-agent-portal)
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('agent_id_requests').doc(requestId).set(requestUpdates, SetOptions(merge: true));
      await secFirestore.collection('agents').doc(agentUid).set(agentUpdates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error approving agent ID in secondary DB: $e');
    }

    // 2. Update in primary/local Manager Firestore
    try {
      await FirebaseFirestore.instance.collection('agent_id_requests').doc(requestId).set(requestUpdates, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('agents').doc(agentUid).set(agentUpdates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error approving agent ID in local DB: $e');
    }
  }

  static Future<void> rejectAgentIdRequest({
    required String requestId,
    required String agentUid,
    String reason = '',
  }) async {
    final requestUpdates = <String, dynamic>{
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': 'AuraAxon Operations Admin',
      if (reason.trim().isNotEmpty) 'rejectionReason': reason.trim(),
    };

    final agentUpdates = <String, dynamic>{
      'pendingIdRequest': {
        'requestId': requestId,
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'AuraAxon Operations Admin',
        if (reason.trim().isNotEmpty) 'rejectionReason': reason.trim(),
      },
      'pendingIdRequest.status': FieldValue.delete(),
      'pendingIdRequest.reviewedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. Update in secondary Firestore (aura-agent-portal)
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('agent_id_requests').doc(requestId).set(requestUpdates, SetOptions(merge: true));
      await secFirestore.collection('agents').doc(agentUid).set(agentUpdates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error rejecting agent ID in secondary DB: $e');
    }

    // 2. Update in primary/local Manager Firestore
    try {
      await FirebaseFirestore.instance.collection('agent_id_requests').doc(requestId).set(requestUpdates, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('agents').doc(agentUid).set(agentUpdates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error rejecting agent ID in local DB: $e');
    }
  }

  /// Delete a registered agent and any associated ID requests from both databases
  static Future<void> deleteAgent(String agentUid) async {
    // 1. Delete from secondary Firestore (aura-agent-portal)
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('agents').doc(agentUid).delete();
      final reqSnap = await secFirestore
          .collection('agent_id_requests')
          .where('agentUid', isEqualTo: agentUid)
          .get();
      for (final doc in reqSnap.docs) {
        await doc.reference.delete();
      }
      await secFirestore.collection('agent_id_requests').doc('REQ-$agentUid').delete().catchError((_) {});
    } catch (e) {
      debugPrint('Error deleting agent from secondary DB: $e');
    }

    // 2. Delete from primary/local Manager Firestore
    try {
      final localDb = FirebaseFirestore.instance;
      await localDb.collection('agents').doc(agentUid).delete();
      final reqSnap = await localDb
          .collection('agent_id_requests')
          .where('agentUid', isEqualTo: agentUid)
          .get();
      for (final doc in reqSnap.docs) {
        await doc.reference.delete();
      }
      await localDb.collection('agent_id_requests').doc('REQ-$agentUid').delete().catchError((_) {});
    } catch (e) {
      debugPrint('Error deleting agent from local DB: $e');
    }
  }

  /// Delete a sales pipeline lead from both databases
  static Future<void> deleteLead(String leadId) async {
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('leads').doc(leadId).delete();
    } catch (e) {
      debugPrint('Error deleting lead from secondary DB: $e');
    }

    try {
      await FirebaseFirestore.instance.collection('leads').doc(leadId).delete();
    } catch (e) {
      debugPrint('Error deleting lead from local DB: $e');
    }
  }

  /// Delete a deployment / setup record from both databases
  static Future<void> deleteSetup(String setupId) async {
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('setups').doc(setupId).delete();
    } catch (e) {
      debugPrint('Error deleting setup from secondary DB: $e');
    }

    try {
      await FirebaseFirestore.instance.collection('setups').doc(setupId).delete();
    } catch (e) {
      debugPrint('Error deleting setup from local DB: $e');
    }
  }

  /// Delete an Agent ID change request and clear pendingIdRequest on the agent document in both databases
  static Future<void> deleteAgentIdRequest({
    required String requestId,
    required String agentUid,
  }) async {
    final clearAgentFields = <String, dynamic>{
      'pendingIdRequest': FieldValue.delete(),
      'pendingIdRequest.status': FieldValue.delete(),
      'pendingIdRequest.reviewedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. Delete in secondary Firestore (aura-agent-portal)
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('agent_id_requests').doc(requestId).delete();
      if (agentUid.trim().isNotEmpty) {
        await secFirestore
            .collection('agents')
            .doc(agentUid.trim())
            .set(clearAgentFields, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error deleting agent ID request from secondary DB: $e');
    }

    // 2. Delete in primary/local Manager Firestore
    try {
      final localDb = FirebaseFirestore.instance;
      await localDb.collection('agent_id_requests').doc(requestId).delete();
      if (agentUid.trim().isNotEmpty) {
        await localDb
            .collection('agents')
            .doc(agentUid.trim())
            .set(clearAgentFields, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error deleting agent ID request from local DB: $e');
    }
  }

  static Future<void> markNotificationAsRead(String notifId) async {
    final updateData = {'read': true, 'readAt': FieldValue.serverTimestamp()};
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('manager_notifications').doc(notifId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking notification read in secondary DB: $e');
    }

    try {
      await FirebaseFirestore.instance.collection('manager_notifications').doc(notifId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking notification read in local DB: $e');
    }
  }

  static Future<void> markAllNotificationsAsRead(List<String> notifIds) async {
    for (final id in notifIds) {
      await markNotificationAsRead(id);
    }
  }

  static Future<void> deleteNotification(String notifId) async {
    try {
      final secFirestore = await getFirestore();
      await secFirestore.collection('manager_notifications').doc(notifId).delete();
    } catch (e) {
      debugPrint('Error deleting notification from secondary DB: $e');
    }

    try {
      await FirebaseFirestore.instance.collection('manager_notifications').doc(notifId).delete();
    } catch (e) {
      debugPrint('Error deleting notification from local DB: $e');
    }

    AuraNotificationService.cancelNotification(notifId);
  }
}
