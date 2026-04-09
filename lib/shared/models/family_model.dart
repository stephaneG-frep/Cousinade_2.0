import 'package:equatable/equatable.dart';

import '../../core/utils/firestore_utils.dart';

class FamilyModel extends Equatable {
  const FamilyModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.membersCount,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final int membersCount;

  FamilyModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
    int? membersCount,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      membersCount: membersCount ?? this.membersCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdAt': toTimestamp(createdAt),
      'membersCount': membersCount,
    };
  }

  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      inviteCode: (map['inviteCode'] ?? '') as String,
      createdBy: (map['createdBy'] ?? '') as String,
      createdAt: parseFirestoreDate(map['createdAt']),
      membersCount: (map['membersCount'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    inviteCode,
    createdBy,
    createdAt,
    membersCount,
  ];
}
