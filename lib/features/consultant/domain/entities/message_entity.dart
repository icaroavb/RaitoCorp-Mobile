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

  factory MessageEntity.fromJson(Map<String, dynamic> json) => MessageEntity(
        id: json['id'].toString(),
        author: _enumFromString(
          MessageAuthor.values,
          json['author'] as String?,
          MessageAuthor.bot,
        ),
        type: _enumFromString(
          MessageType.values,
          json['type'] as String?,
          MessageType.text,
        ),
        text: json['text'] as String?,
        imagePath: json['image_path'] as String?,
        productRecommendations:
            (json['product_recommendations'] as List? ?? const [])
                .map((e) => e.toString())
                .toList(),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.name,
        'type': type.name,
        if (text != null) 'text': text,
        if (imagePath != null) 'image_path': imagePath,
        'product_recommendations': productRecommendations,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

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
