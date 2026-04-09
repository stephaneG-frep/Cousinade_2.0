import 'package:equatable/equatable.dart';

import '../../core/utils/firestore_utils.dart';

class CommentModel extends Equatable {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? text,
    DateTime? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': toTimestamp(createdAt),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: (map['id'] ?? '') as String,
      postId: (map['postId'] ?? '') as String,
      authorId: (map['authorId'] ?? '') as String,
      authorName: (map['authorName'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      createdAt: parseFirestoreDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    postId,
    authorId,
    authorName,
    text,
    createdAt,
  ];
}
