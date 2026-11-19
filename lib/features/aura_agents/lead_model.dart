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
  bool get hasCoordinates => latitude != null && longitude != null && latitude != 0.0 && longitude != 0.0;
  String get mapsUrl => hasCoordinates ? 'https://www.google.com/maps?q=$latitude,$longitude' : '';
  String get coordinatesDisplay => hasCoordinates ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}' : '';
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
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
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
    this.latitude,
    this.longitude,
    this.locationAddress,
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
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAddress: map['locationAddress']?.toString(),
      createdAt: created,
      updatedAt: updated,
    );
  }
}