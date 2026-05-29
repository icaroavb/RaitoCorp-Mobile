import 'dart:typed_data';

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

  /// Bytes da foto recém-escolhida, só pra exibir a bolha local antes do
  /// upload. Funciona em web (sem filesystem) via Image.memory. Não trafega
  /// pra API — o servidor só conhece image_path (URL Cloudinary).
  final Uint8List? localBytes;

  /// Placeholder de "preview sendo gerado": a UI mostra um quadrado com loading
  /// no lugar da imagem. Só local, não vem da API. Ver `ConsultantNotifier.sendPreview`.
  final bool isGenerating;

  /// Quando o preview esgota o tempo (ainda processando no servidor), a UI mostra
  /// um botão "Tentar novamente" que retoma o polling deste mesmo `retryTaskId`.
  /// Só local. `retryProductId` é necessário pro reenvio.
  final String? retryTaskId;
  final String? retryProductId;

  const MessageEntity({
    required this.id,
    required this.author,
    required this.type,
    this.text,
    this.imagePath,
    this.productRecommendations = const [],
    required this.createdAt,
    this.localBytes,
    this.isGenerating = false,
    this.retryTaskId,
    this.retryProductId,
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
