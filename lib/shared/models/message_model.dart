import 'package:equatable/equatable.dart';

import '../../core/utils/firestore_utils.dart';

class MessageModel extends Equatable {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'createdAt': toTimestamp(createdAt),
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: (map['id'] ?? '') as String,
      conversationId: (map['conversationId'] ?? '') as String,
      senderId: (map['senderId'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      createdAt: parseFirestoreDate(map['createdAt']),
      isRead: (map['isRead'] ?? false) as bool,
    );
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    text,
    createdAt,
    isRead,
  ];
}
