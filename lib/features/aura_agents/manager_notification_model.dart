import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerNotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String agentUid;
  final String agentId;
  final String agentName;
  final String agentEmail;
  final String agentPhone;
  final String territory;
  final bool read;
  final DateTime createdAt;

  ManagerNotificationModel({
    required this.id,
    this.type = 'new_agent_registration',
    required this.title,
    required this.message,
    this.agentUid = '',
    this.agentId = '',
    this.agentName = '',
    this.agentEmail = '',
    this.agentPhone = '',
    this.territory = '',
    this.read = false,
    required this.createdAt,
  });

  factory ManagerNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime dt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      dt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      dt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    return ManagerNotificationModel(
      id: doc.id,
      type: (data['type'] ?? 'new_agent_registration').toString(),
      title: (data['title'] ?? 'Notification').toString(),
      message: (data['message'] ?? '').toString(),
      agentUid: (data['agentUid'] ?? '').toString(),
      agentId: (data['agentId'] ?? '').toString(),
      agentName: (data['agentName'] ?? '').toString(),
      agentEmail: (data['agentEmail'] ?? '').toString(),
      agentPhone: (data['agentPhone'] ?? '').toString(),
      territory: (data['territory'] ?? '').toString(),
      read: data['read'] == true,
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'agentUid': agentUid,
      'agentId': agentId,
      'agentName': agentName,
      'agentEmail': agentEmail,
      'agentPhone': agentPhone,
      'territory': territory,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ManagerNotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? agentUid,
    String? agentId,
    String? agentName,
    String? agentEmail,
    String? agentPhone,
    String? territory,
    bool? read,
    DateTime? createdAt,
  }) {
    return ManagerNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      agentUid: agentUid ?? this.agentUid,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      agentEmail: agentEmail ?? this.agentEmail,
      agentPhone: agentPhone ?? this.agentPhone,
      territory: territory ?? this.territory,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
