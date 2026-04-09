import 'package:equatable/equatable.dart';

import '../../core/utils/firestore_utils.dart';

class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'createdAt': toTimestamp(createdAt),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: (map['id'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      type: (map['type'] ?? 'general') as String,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      createdAt: parseFirestoreDate(map['createdAt']),
      isRead: (map['isRead'] ?? false) as bool,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, title, body, createdAt, isRead];
}
