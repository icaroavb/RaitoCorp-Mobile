import 'package:equatable/equatable.dart';

enum MessageAuthor { user, bot }

enum MessageType { text, image, productRecommendation }

class MessageEntity extends Equatable {
  final String id;
  final MessageAuthor author;
  final MessageType type;
  final String? text;
  final String? imagePath;
  final List<String> productRecommendations;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.author,
    required this.type,
    this.text,
    this.imagePath,
    this.productRecommendations = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
