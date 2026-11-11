import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'agent_model.dart';
import 'lead_model.dart';
import 'setup_model.dart';
import 'aura_agent_firebase_service.dart';

final agentsStreamProvider = StreamProvider.autoDispose<List<RegisteredAgentModel>>((ref) {
  final controller = StreamController<List<RegisteredAgentModel>>();
  final localFirestore = FirebaseFirestore.instance;

  final Map<String, RegisteredAgentModel> localMap = {};
  final Map<String, RegisteredAgentModel> secondaryMap = {};

  void emitMerged() {
    if (controller.isClosed) return;
    final Map<String, RegisteredAgentModel> merged = {};
    for (final entry in secondaryMap.entries) {
      merged[entry.key] = entry.value;
    }
    for (final entry in localMap.entries) {
      if (merged.containsKey(entry.key)) {
        merged[entry.key] = merged[entry.key]!.merge(entry.value);
      } else {
        merged[entry.key] = entry.value;
      }
    }
    final list = merged.values.toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    controller.add(list);
  }

  // 1. Primary listener for manager Firestore
  final localSub = localFirestore.collection('agents').snapshots().listen(
    (snap) {
      localMap.clear();
      for (final doc in snap.docs) {
        localMap[doc.id] = RegisteredAgentModel.fromFirestore(doc);
      }
      emitMerged();
    },
    onError: (e) {
      debugPrint('Local agents stream notice: $e');
    },
  );

  // 2. Secondary listener for aura-agent-portal Firestore
  StreamSubscription? secondarySub;
  AuraAgentFirebaseService.getFirestore().then((secFirestore) {
    if (controller.isClosed) return;
    secondarySub = secFirestore.collection('agents').snapshots().listen(
      (snap) {
        secondaryMap.clear();
        for (final doc in snap.docs) {
          secondaryMap[doc.id] = RegisteredAgentModel.fromFirestore(doc);
        }
        emitMerged();
      },
      onError: (e) {
        debugPrint('Secondary agents stream notice: $e');
      },
    );
  }).catchError((e) {
    debugPrint('Could not initialize secondary agents stream: $e');
  });

  ref.onDispose(() {
    localSub.cancel();
    secondarySub?.cancel();
    controller.close();
  });

  return controller.stream;
});

final axonLeadsStreamProvider = StreamProvider.autoDispose<List<AxonLeadModel>>((ref) {
  final controller = StreamController<List<AxonLeadModel>>();
  final localFirestore = FirebaseFirestore.instance;

  final Map<String, AxonLeadModel> localMap = {};
  final Map<String, AxonLeadModel> secondaryMap = {};

  void emitMerged() {
    if (controller.isClosed) return;
    final Map<String, AxonLeadModel> merged = {};
    for (final entry in secondaryMap.entries) {
      merged[entry.key] = entry.value;
    }
    for (final entry in localMap.entries) {
      merged[entry.key] = entry.value;
    }
    final list = merged.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    controller.add(list);
  }

  final localSub = localFirestore.collection('leads').snapshots().listen(
    (snap) {
      localMap.clear();
      for (final doc in snap.docs) {
        localMap[doc.id] = AxonLeadModel.fromFirestore(doc);
      }
      emitMerged();
    },
    onError: (e) => debugPrint('Local leads stream notice: $e'),
  );

  StreamSubscription? secondarySub;
  AuraAgentFirebaseService.getFirestore().then((secFirestore) {
    if (controller.isClosed) return;
    secondarySub = secFirestore.collection('leads').snapshots().listen(
      (snap) {
        secondaryMap.clear();
        for (final doc in snap.docs) {
          secondaryMap[doc.id] = AxonLeadModel.fromFirestore(doc);
        }
        emitMerged();
      },
      onError: (e) => debugPrint('Secondary leads stream notice: $e'),
    );
  }).catchError((e) => debugPrint('Secondary leads init notice: $e'));

  ref.onDispose(() {
    localSub.cancel();
    secondarySub?.cancel();
    controller.close();
  });

  return controller.stream;
});

final axonSetupsStreamProvider = StreamProvider.autoDispose<List<AxonSetupModel>>((ref) {
  final controller = StreamController<List<AxonSetupModel>>();
  final localFirestore = FirebaseFirestore.instance;

  final Map<String, AxonSetupModel> localMap = {};
  final Map<String, AxonSetupModel> secondaryMap = {};

  void emitMerged() {
    if (controller.isClosed) return;
    final Map<String, AxonSetupModel> merged = {};
    for (final entry in secondaryMap.entries) {
      merged[entry.key] = entry.value;
    }
    for (final entry in localMap.entries) {
      merged[entry.key] = entry.value;
    }
    final list = merged.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    controller.add(list);
  }

  final localSub = localFirestore.collection('setups').snapshots().listen(
    (snap) {
      localMap.clear();
      for (final doc in snap.docs) {
        localMap[doc.id] = AxonSetupModel.fromFirestore(doc);
      }
      emitMerged();
    },
    onError: (e) => debugPrint('Local setups stream notice: $e'),
  );

  StreamSubscription? secondarySub;
  AuraAgentFirebaseService.getFirestore().then((secFirestore) {
    if (controller.isClosed) return;
    secondarySub = secFirestore.collection('setups').snapshots().listen(
      (snap) {
        secondaryMap.clear();
        for (final doc in snap.docs) {
          secondaryMap[doc.id] = AxonSetupModel.fromFirestore(doc);
        }
        emitMerged();
      },
      onError: (e) => debugPrint('Secondary setups stream notice: $e'),
    );
  }).catchError((e) => debugPrint('Secondary setups init notice: $e'));

  ref.onDispose(() {
    localSub.cancel();
    secondarySub?.cancel();
    controller.close();
  });

  return controller.stream;
});
