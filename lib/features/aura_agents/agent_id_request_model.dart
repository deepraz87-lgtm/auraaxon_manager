import 'package:cloud_firestore/cloud_firestore.dart';

class AgentIdRequestModel {
  final String requestId;
  final String agentUid;
  final String agentName;
  final String agentEmail;
  final String currentAgentId;
  final String requestedAgentId;
  final String reason;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? adminNotes;
  final String? rejectionReason;

  AgentIdRequestModel({
    required this.requestId,
    required this.agentUid,
    required this.agentName,
    required this.agentEmail,
    required this.currentAgentId,
    required this.requestedAgentId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.adminNotes,
    this.rejectionReason,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory AgentIdRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    DateTime? reviewed;
    if (data['reviewedAt'] is Timestamp) {
      reviewed = (data['reviewedAt'] as Timestamp).toDate();
    } else if (data['reviewedAt'] is String) {
      reviewed = DateTime.tryParse(data['reviewedAt']);
    }

    return AgentIdRequestModel(
      requestId: (data['requestId'] ?? doc.id).toString(),
      agentUid: (data['agentUid'] ?? '').toString(),
      agentName: (data['agentName'] ?? 'Unknown Agent').toString(),
      agentEmail: (data['agentEmail'] ?? '').toString(),
      currentAgentId: (data['currentAgentId'] ?? '').toString(),
      requestedAgentId: (data['requestedAgentId'] ?? '').toString(),
      reason: (data['reason'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: created,
      reviewedAt: reviewed,
      adminNotes: data['adminNotes']?.toString(),
      rejectionReason: data['rejectionReason']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'agentUid': agentUid,
      'agentName': agentName,
      'agentEmail': agentEmail,
      'currentAgentId': currentAgentId,
      'requestedAgentId': requestedAgentId,
      'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }
}
