import 'package:equatable/equatable.dart';

import 'product_entity.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String authorName;
  final String authorInitials;
  final int rating;
  final String comment;
  final DateTime date;
  final Room? room;
  final bool hasPhoto;
  final String? photoUrl;

  const ReviewEntity({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.rating,
    required this.comment,
    required this.date,
    this.room,
    this.hasPhoto = false,
    this.photoUrl,
  });

  factory ReviewEntity.fromJson(Map<String, dynamic> json) {
    final name = json['author_name'] as String? ?? 'Anônimo';
    return ReviewEntity(
      id: json['id'].toString(),
      authorName: name,
      authorInitials: (json['author_initials'] as String?) ?? _initials(name),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String? ?? '',
      date: DateTime.parse(json['date'] as String).toLocal(),
      room: json['room'] == null
          ? null
          : _enumFromString(Room.values, json['room'] as String?, Room.living),
      hasPhoto: json['has_photo'] as bool? ?? false,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_name': authorName,
        'author_initials': authorInitials,
        'rating': rating,
        'comment': comment,
        'date': date.toUtc().toIso8601String(),
        if (room != null) 'room': room!.name,
        'has_photo': hasPhoto,
        if (photoUrl != null) 'photo_url': photoUrl,
      };

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [id];
}

T _enumFromString<T extends Enum>(List<T> values, String? raw, T fallback) {
  if (raw == null) return fallback;
  for (final v in values) {
    if (v.name.toLowerCase() == raw.toLowerCase()) return v;
  }
  return fallback;
}
