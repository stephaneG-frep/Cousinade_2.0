import 'package:equatable/equatable.dart';

import '../../core/utils/firestore_utils.dart';

class PostModel extends Equatable {
  const PostModel({
    required this.id,
    required this.familyId,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    this.authorAvatar,
    this.text,
    this.imageUrl,
    this.videoUrl,
    this.videoThumbnailUrl,
  });

  final String id;
  final String familyId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  PostModel copyWith({
    String? id,
    String? familyId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? videoThumbnailUrl,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
  }) {
    return PostModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'videoThumbnailUrl': videoThumbnailUrl,
      'createdAt': toTimestamp(createdAt),
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: (map['id'] ?? '') as String,
      familyId: (map['familyId'] ?? '') as String,
      authorId: (map['authorId'] ?? '') as String,
      authorName: (map['authorName'] ?? '') as String,
      authorAvatar: map['authorAvatar'] as String?,
      text: map['text'] as String?,
      imageUrl: map['imageUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      videoThumbnailUrl: map['videoThumbnailUrl'] as String?,
      createdAt: parseFirestoreDate(map['createdAt']),
      likeCount: (map['likeCount'] ?? 0) as int,
      commentCount: (map['commentCount'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyId,
    authorId,
    authorName,
    authorAvatar,
    text,
    imageUrl,
    videoUrl,
    videoThumbnailUrl,
    createdAt,
    likeCount,
    commentCount,
  ];
}
