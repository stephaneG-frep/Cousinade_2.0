import 'package:equatable/equatable.dart';

import '../../core/utils/firestore_utils.dart';

class ConversationModel extends Equatable {
  const ConversationModel({
    required this.id,
    required this.familyId,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  final String id;
  final String familyId;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageAt;

  ConversationModel copyWith({
    String? id,
    String? familyId,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageAt': toTimestamp(lastMessageAt),
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: (map['id'] ?? '') as String,
      familyId: (map['familyId'] ?? '') as String,
      participantIds: List<String>.from((map['participantIds'] ?? []) as List),
      lastMessage: (map['lastMessage'] ?? '') as String,
      lastMessageAt: parseFirestoreDate(map['lastMessageAt']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyId,
    participantIds,
    lastMessage,
    lastMessageAt,
  ];
}
