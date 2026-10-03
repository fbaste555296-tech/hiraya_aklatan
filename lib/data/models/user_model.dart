import 'package:cloud_firestore/cloud_firestore.dart';

/// User data model
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.vipExpiry,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime? vipExpiry;
  final DateTime createdAt;

  /// Creates a UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? 'Reader',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'reader',
      vipExpiry: map['vipExpiry'] != null
          ? (map['vipExpiry'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts UserModel to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'vipExpiry': vipExpiry != null ? Timestamp.fromDate(vipExpiry!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    DateTime? vipExpiry,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      vipExpiry: vipExpiry ?? this.vipExpiry,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Checks if user has active VIP subscription
  bool get isVipActive {
    if (vipExpiry == null) return false;
    return vipExpiry!.isAfter(DateTime.now());
  }

  /// Checks if user is admin
  bool get isAdmin => role == 'admin';

  /// Checks if user is reader
  bool get isReader => role == 'reader';

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role, vipExpiry: $vipExpiry)';
  }
}
