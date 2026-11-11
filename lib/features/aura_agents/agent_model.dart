import 'package:cloud_firestore/cloud_firestore.dart';

class RegisteredAgentModel {
  final String id;
  final String agentId;
  final String agentPin;
  final String name;
  final String email;
  final String phone;
  final String role; // 'Sales Agent' or 'Sales & Setup Agent'
  final String territory; // location / territory
  final String bio;
  final DateTime? createdAt;
  final String status; // 'Active', 'Pending Verification', 'Inactive', etc.
  final String certificationStatus;
  final int certificationScore;
  final int certificationLevel;
  final bool isPasskeyEnabled;
  final String passkeyPin;

  RegisteredAgentModel({
    required this.id,
    this.agentId = '',
    this.agentPin = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.territory = 'Sri Lanka',
    this.bio = '',
    this.createdAt,
    this.status = 'Active',
    this.certificationStatus = 'locked',
    this.certificationScore = 0,
    this.certificationLevel = 0,
    this.isPasskeyEnabled = false,
    this.passkeyPin = '',
  });

  /// Display ID: Prefer official agentId if present, else fallback to AGT-XXXXX from UID
  String get displayId {
    final cleanId = agentId.trim();
    if (cleanId.isNotEmpty) return cleanId;
    final cleanUid = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (cleanUid.length >= 5) {
      return 'AGT-${cleanUid.substring(0, 5)}';
    }
    return id.isNotEmpty ? id : 'AGT-00001';
  }

  /// Display PIN: agentPin or passkeyPin if available
  String get displayPin {
    if (agentPin.trim().isNotEmpty) return agentPin.trim();
    if (passkeyPin.trim().isNotEmpty) return passkeyPin.trim();
    return '';
  }

  RegisteredAgentModel copyWith({
    String? id,
    String? agentId,
    String? agentPin,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? territory,
    String? bio,
    DateTime? createdAt,
    String? status,
    String? certificationStatus,
    int? certificationScore,
    int? certificationLevel,
    bool? isPasskeyEnabled,
    String? passkeyPin,
  }) {
    return RegisteredAgentModel(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      agentPin: agentPin ?? this.agentPin,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      territory: territory ?? this.territory,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      certificationStatus: certificationStatus ?? this.certificationStatus,
      certificationScore: certificationScore ?? this.certificationScore,
      certificationLevel: certificationLevel ?? this.certificationLevel,
      isPasskeyEnabled: isPasskeyEnabled ?? this.isPasskeyEnabled,
      passkeyPin: passkeyPin ?? this.passkeyPin,
    );
  }

  RegisteredAgentModel merge(RegisteredAgentModel other) {
    return RegisteredAgentModel(
      id: id,
      agentId: agentId.trim().isNotEmpty ? agentId : other.agentId,
      agentPin: agentPin.trim().isNotEmpty ? agentPin : other.agentPin,
      name: (name.trim().isNotEmpty && name != 'Unnamed Agent') ? name : other.name,
      email: (email.trim().isNotEmpty && email != 'No email') ? email : other.email,
      phone: (phone.trim().isNotEmpty && phone != 'No phone') ? phone : other.phone,
      role: (role.trim().isNotEmpty && role != 'Sales Agent') ? role : other.role,
      territory: (territory.trim().isNotEmpty && territory != 'Sri Lanka') ? territory : other.territory,
      bio: bio.trim().isNotEmpty ? bio : other.bio,
      createdAt: createdAt ?? other.createdAt,
      status: status.trim().isNotEmpty ? status : other.status,
      certificationStatus: certificationStatus.isNotEmpty ? certificationStatus : other.certificationStatus,
      certificationScore: certificationScore > 0 ? certificationScore : other.certificationScore,
      certificationLevel: certificationLevel > 0 ? certificationLevel : other.certificationLevel,
      isPasskeyEnabled: isPasskeyEnabled || other.isPasskeyEnabled,
      passkeyPin: passkeyPin.isNotEmpty ? passkeyPin : other.passkeyPin,
    );
  }

  factory RegisteredAgentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt']);
    } else if (data['updatedAt'] is Timestamp) {
      created = (data['updatedAt'] as Timestamp).toDate();
    }

    final terr = data['territory'] ?? data['location'] ?? 'Sri Lanka';
    final stat = data['status'] ?? 'Active';
    final rawName = data['name'] ?? data['displayName'] ?? 'Unnamed Agent';
    final rawAgentId = data['agentId'] ?? data['agent_id'] ?? '';
    final rawPin = data['agentPin'] ?? data['agent_pin'] ?? data['passkeyPin'] ?? data['pin'] ?? '';

    return RegisteredAgentModel(
      id: doc.id,
      agentId: rawAgentId.toString().trim(),
      agentPin: rawPin.toString().trim(),
      name: rawName.toString().trim(),
      email: (data['email'] ?? 'No email').toString().trim(),
      phone: (data['phone'] ?? 'No phone').toString().trim(),
      role: (data['role'] ?? 'Sales Agent').toString().trim(),
      territory: terr.toString().trim().isEmpty ? 'Sri Lanka' : terr.toString().trim(),
      bio: (data['bio'] ?? '').toString().trim(),
      createdAt: created,
      status: stat.toString().trim().isEmpty ? 'Active' : stat.toString().trim(),
      certificationStatus: (data['certificationStatus'] ?? 'locked').toString(),
      certificationScore: (data['certificationScore'] as num?)?.toInt() ?? 0,
      certificationLevel: (data['certificationLevel'] as num?)?.toInt() ?? 0,
      isPasskeyEnabled: data['isPasskeyEnabled'] == true,
      passkeyPin: (data['passkeyPin'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agentId': agentId,
      'agentPin': agentPin,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'territory': territory,
      'location': territory,
      'bio': bio,
      'status': status,
      'certificationStatus': certificationStatus,
      'certificationScore': certificationScore,
      'certificationLevel': certificationLevel,
      'isPasskeyEnabled': isPasskeyEnabled,
      'passkeyPin': passkeyPin,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
