import 'package:cloud_firestore/cloud_firestore.dart';

enum AxonLeadStatus {
  newLead('New Lead'),
  demoScheduled('Demo Scheduled'),
  quotationSent('Quotation Sent'),
  closedWon('Closed Won'),
  closedLost('Closed Lost');

  final String label;
  const AxonLeadStatus(this.label);

  static AxonLeadStatus fromString(String value) {
    return AxonLeadStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => AxonLeadStatus.newLead,
    );
  }
}

class AxonLeadModel {
  final String id;
  final String agentId;
  final String agentName;
  final String clientName;
  final String companyName;
  final String phone;
  final String email;
  final String territory;
  final String softwarePackage;
  final double quotedPriceLkr;
  final AxonLeadStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AxonLeadModel({
    required this.id,
    this.agentId = '',
    this.agentName = '',
    required this.clientName,
    required this.companyName,
    required this.phone,
    required this.email,
    this.territory = 'Sri Lanka',
    required this.softwarePackage,
    required this.quotedPriceLkr,
    required this.status,
    this.notes = '',
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory AxonLeadModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created = DateTime.now();
    DateTime updated = DateTime.now();

    if (map['createdAt'] is Timestamp) {
      created = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      created = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    }

    if (map['updatedAt'] is Timestamp) {
      updated = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updated = DateTime.tryParse(map['updatedAt']) ?? created;
    }

    return AxonLeadModel(
      id: doc.id,
      agentId: (map['agentId'] ?? '').toString(),
      agentName: (map['agentName'] ?? '').toString(),
      clientName: (map['clientName'] ?? '').toString(),
      companyName: (map['companyName'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      territory: (map['territory'] ?? 'Sri Lanka').toString(),
      softwarePackage: (map['softwarePackage'] ?? 'BizManager POS Standard').toString(),
      quotedPriceLkr: (map['quotedPriceLkr'] as num?)?.toDouble() ?? 0.0,
      status: AxonLeadStatus.fromString((map['status'] ?? 'newLead').toString()),
      notes: (map['notes'] ?? '').toString(),
      createdAt: created,
      updatedAt: updated,
    );
  }
}