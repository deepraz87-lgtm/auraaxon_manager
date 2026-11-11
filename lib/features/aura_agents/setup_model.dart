import 'package:cloud_firestore/cloud_firestore.dart';

enum AxonSetupStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed');

  final String label;
  const AxonSetupStatus(this.label);

  static AxonSetupStatus fromString(String value) {
    return AxonSetupStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => AxonSetupStatus.pending,
    );
  }
}

class AxonChecklistItem {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;

  AxonChecklistItem({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
  });

  factory AxonChecklistItem.fromMap(Map<String, dynamic> map) {
    return AxonChecklistItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

class AxonSetupModel {
  final String id;
  final String agentId;
  final String agentName;
  final String companyName;
  final String targetSoftwareVersion;
  final String leadId;
  final List<AxonChecklistItem> checklist;
  final AxonSetupStatus status;
  final bool isSignedOff;
  final String? signOffNotes;
  final DateTime? signedOffAt;
  final DateTime updatedAt;

  AxonSetupModel({
    required this.id,
    this.agentId = '',
    this.agentName = '',
    required this.companyName,
    required this.targetSoftwareVersion,
    required this.leadId,
    required this.checklist,
    required this.status,
    this.isSignedOff = false,
    this.signOffNotes,
    this.signedOffAt,
    required this.updatedAt,
  });

  double get progress {
    if (checklist.isEmpty) return 0.0;
    final completedCount = checklist.where((c) => c.isCompleted).length;
    return completedCount / checklist.length;
  }

  factory AxonSetupModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    final rawChecklist = map['checklist'] as List<dynamic>? ?? [];

    DateTime updated = DateTime.now();
    if (map['updatedAt'] is Timestamp) {
      updated = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updated = DateTime.tryParse(map['updatedAt']) ?? DateTime.now();
    }

    DateTime? signedAt;
    if (map['signedOffAt'] is Timestamp) {
      signedAt = (map['signedOffAt'] as Timestamp).toDate();
    } else if (map['signedOffAt'] is String) {
      signedAt = DateTime.tryParse(map['signedOffAt']);
    }

    return AxonSetupModel(
      id: doc.id,
      agentId: (map['agentId'] ?? '').toString(),
      agentName: (map['agentName'] ?? '').toString(),
      companyName: (map['companyName'] ?? '').toString(),
      targetSoftwareVersion: (map['targetSoftwareVersion'] ?? '').toString(),
      leadId: (map['leadId'] ?? '').toString(),
      checklist: rawChecklist
          .map((item) => AxonChecklistItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      status: AxonSetupStatus.fromString((map['status'] ?? 'pending').toString()),
      isSignedOff: (map['isSignedOff'] as bool?) ?? false,
      signOffNotes: map['signOffNotes'] as String?,
      signedOffAt: signedAt,
      updatedAt: updated,
    );
  }
}