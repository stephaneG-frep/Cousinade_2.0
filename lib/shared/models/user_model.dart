import 'package:equatable/equatable.dart';

import '../../core/utils/firestore_utils.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.email,
    required this.createdAt,
    this.familyId,
    this.avatarUrl,
    this.bio,
  });

  final String id;
  final String? familyId;
  final String role;
  final String firstName;
  final String lastName;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;

  bool get hasFamily => (familyId ?? '').isNotEmpty;

  UserModel copyWith({
    String? id,
    String? familyId,
    String? role,
    String? firstName,
    String? lastName,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': toTimestamp(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? '') as String,
      familyId: map['familyId'] as String?,
      role: (map['role'] ?? 'member') as String,
      firstName: (map['firstName'] ?? '') as String,
      lastName: (map['lastName'] ?? '') as String,
      displayName: (map['displayName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String?,
      createdAt: parseFirestoreDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyId,
    role,
    firstName,
    lastName,
    displayName,
    email,
    avatarUrl,
    bio,
    createdAt,
  ];
}
