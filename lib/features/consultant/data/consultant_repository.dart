import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/entities/message_entity.dart';

class ConsultantRepository {
  ConsultantRepository(this._api);
  final ApiClient _api;

  /// Envia uma mensagem de texto do usuário e recebe a resposta do bot.
  /// `sessionId` agrupa a conversa do lado do n8n (mesma row de `chat_sessions`).
  Future<MessageEntity> sendText({
    required String sessionId,
    required String text,
  }) async {
    final res = await _api.postJson('/consultant/message', body: {
      'session_id': sessionId,
      'text': text,
    }) as Map<String, dynamic>;
    return MessageEntity.fromJson(res);
  }

  /// Envia uma imagem (path local → o n8n vai instruir o app a fazer upload
  /// em uma segunda chamada, ou recebe base64). Por ora, o body manda só o
  /// nome do arquivo + a intent — a estratégia final de upload (S3 / direto)
  /// fica como decisão.
  /// TODO: definir estratégia de upload de imagem com você (S3 presigned,
  /// multipart direto pro n8n, ou base64 inline).
  Future<MessageEntity> sendImage({
    required String sessionId,
    required String imagePath,
  }) async {
    final res = await _api.postJson('/consultant/image', body: {
      'session_id': sessionId,
      'image_path': imagePath,
    }) as Map<String, dynamic>;
    return MessageEntity.fromJson(res);
  }

  /// Histórico opcional de uma sessão (pra reabrir conversa antiga).
  Future<List<MessageEntity>> fetchHistory(String sessionId) async {
    final res = await _api.getJson('/consultant/sessions/$sessionId') as List;
    return res
        .map((e) => MessageEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final consultantRepositoryProvider = Provider<ConsultantRepository>((ref) {
  return ConsultantRepository(ref.watch(apiClientProvider));
});
