import 'package:equatable/equatable.dart';

import '../../core/utils/firestore_utils.dart';

class EventModel extends Equatable {
  const EventModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final String createdBy;
  final DateTime createdAt;

  EventModel copyWith({
    String? id,
    String? familyId,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'title': title,
      'description': description,
      'location': location,
      'startDate': toTimestamp(startDate),
      'createdBy': createdBy,
      'createdAt': toTimestamp(createdAt),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: (map['id'] ?? '') as String,
      familyId: (map['familyId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      startDate: parseFirestoreDate(map['startDate']),
      createdBy: (map['createdBy'] ?? '') as String,
      createdAt: parseFirestoreDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyId,
    title,
    description,
    location,
    startDate,
    createdBy,
    createdAt,
  ];
}
