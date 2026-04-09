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

  const ReviewEntity({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.rating,
    required this.comment,
    required this.date,
    this.room,
    this.hasPhoto = false,
  });

  @override
  List<Object?> get props => [id];
}
