import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/entities/message_entity.dart';

/// Estado da geração assíncrona do preview, devolvido por `startPreview`/`pollPreview`.
enum PreviewState { processing, ready, failed }

class PreviewStatus {
  final PreviewState state;

  /// Id da task no ModelScope — o app reenvia em cada polling. Pode mudar entre
  /// pollings se o n8n re-submeteu após um FAILED.
  final String? taskId;

  /// Mensagem pronta (só quando `state == ready`).
  final MessageEntity? message;

  const PreviewStatus({required this.state, this.taskId, this.message});

  factory PreviewStatus.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    if (status == 'ready') {
      return PreviewStatus(
        state: PreviewState.ready,
        message: MessageEntity.fromJson(json['message'] as Map<String, dynamic>),
      );
    }
    if (status == 'failed') {
      return const PreviewStatus(state: PreviewState.failed);
    }
    return PreviewStatus(
      state: PreviewState.processing,
      taskId: json['task_id']?.toString(),
    );
  }
}

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

  /// Envia a URL pública (Cloudinary) de uma foto do ambiente e recebe a
  /// recomendação do bot. O app sobe a imagem pro Cloudinary antes (ver
  /// `ConsultantNotifier.sendImage`) porque o webhook n8n é hardened e baixa
  /// a URL — não recebe caminho local nem binário. Ver `docs/N8N_API.md` §3.23.
  Future<MessageEntity> sendImage({
    required String sessionId,
    required String imageUrl,
    String? text,
  }) async {
    final res = await _api.postJson('/consultant/image', body: {
      'session_id': sessionId,
      'image_path': imageUrl,
      if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
    }) as Map<String, dynamic>;
    return MessageEntity.fromJson(res);
  }

  /// Inicia a geração do preview "produto no meu ambiente". O n8n submete ao
  /// ModelScope (foto do ambiente + foto do produto) e responde NA HORA com um
  /// `task_id` — não espera a imagem (geração leva 2-4 min e o Cloudflare cortaria
  /// a conexão em ~100s). A imagem é buscada depois com `pollPreview`.
  /// Ver `docs/N8N_API.md` §3.25.
  ///
  /// Limite 2/dia por usuário: ao estourar, o n8n responde 429 e o `ApiClient`
  /// lança `ApiException` com a mensagem amigável.
  Future<PreviewStatus> startPreview({
    required String sessionId,
    required String productId,
  }) async {
    final res = await _api.postJson('/consultant/preview', body: {
      'session_id': sessionId,
      'product_id': productId,
    }) as Map<String, dynamic>;
    return PreviewStatus.fromJson(res);
  }

  /// Consulta o andamento da geração reenviando o `task_id`. O n8n só checa o
  /// status no ModelScope (chamada curta, não estoura Cloudflare):
  /// - `ready`  → a imagem ficou pronta (sobe pro Cloudinary, salva e devolve a `message`);
  /// - `processing` → ainda gerando (com o mesmo ou um novo `task_id` se houve retry);
  /// - `failed` → desistiu de vez.
  Future<PreviewStatus> pollPreview({
    required String sessionId,
    required String productId,
    required String taskId,
  }) async {
    final res = await _api.postJson('/consultant/preview', body: {
      'session_id': sessionId,
      'product_id': productId,
      'task_id': taskId,
    }) as Map<String, dynamic>;
    return PreviewStatus.fromJson(res);
  }

  /// Histórico opcional de uma sessão (pra reabrir conversa antiga).
  /// Query string `?id=` (path param `:id` não funciona no n8n sem webhookId,
  /// mesmo motivo de `/products/detail`). Ver `docs/N8N_API.md` §3.24.
  Future<List<MessageEntity>> fetchHistory(String sessionId) async {
    final res = await _api
        .getJson('/consultant/sessions', query: {'id': sessionId}) as List;
    return res
        .map((e) => MessageEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Apaga todas as mensagens da sessão no servidor (limpa o histórico do
  /// consultor e mantém o Postgres enxuto). Ver `docs/N8N_API.md` §3.26.
  Future<void> clearHistory(String sessionId) async {
    await _api.postJson('/consultant/clear', body: {'session_id': sessionId});
  }
}

final consultantRepositoryProvider = Provider<ConsultantRepository>((ref) {
  return ConsultantRepository(ref.watch(apiClientProvider));
});
