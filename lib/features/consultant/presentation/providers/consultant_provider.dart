import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/upload/cloudinary_service.dart';
import '../../data/consultant_repository.dart';
import '../../domain/entities/message_entity.dart';

/// `session_id` persistido em Hive: gerado uma vez e reusado entre aberturas do
/// app, pra retomar a mesma conversa (e ver previews gerados com o app fechado).
const _consultantBox = 'consultant_box';
const _sessionKey = 'session_id';

final _sessionIdProvider = Provider<String>((_) {
  final box = Hive.box<dynamic>(_consultantBox);
  var sid = box.get(_sessionKey) as String?;
  if (sid == null || sid.isEmpty) {
    sid = 'sess-${DateTime.now().millisecondsSinceEpoch}';
    box.put(_sessionKey, sid);
  }
  return sid;
});

class ConsultantNotifier extends StateNotifier<List<MessageEntity>> {
  ConsultantNotifier(this._repo, this._cloudinary, this._sessionId)
      : super([_welcome()]) {
    _loadHistory();
  }

  final ConsultantRepository _repo;
  final CloudinaryService _cloudinary;
  final String _sessionId;

  static MessageEntity _welcome() => MessageEntity(
        id: 'welcome',
        author: MessageAuthor.bot,
        type: MessageType.text,
        text:
            'Olá! Sou o Consultor Raitõ. Manda uma foto do seu ambiente ou me conta o que precisa — a gente encontra a luz certa sem complicação.',
        createdAt: DateTime.now(),
      );

  /// Ao abrir, busca o histórico da sessão no servidor e o exibe — assim o
  /// usuário reencontra a conversa (incluindo previews gerados com o app
  /// fechado, que ficam salvos no banco mesmo sem o app rodando o polling).
  Future<void> _loadHistory() async {
    try {
      final history = await _repo.fetchHistory(_sessionId);
      if (history.isNotEmpty) {
        state = [_welcome(), ...history];
      }
    } catch (_) {
      // sem histórico / offline → mantém só a saudação
    }
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final userMsg = MessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: MessageAuthor.user,
      type: MessageType.text,
      text: text,
      createdAt: DateTime.now(),
    );
    state = [...state, userMsg];

    try {
      final reply = await _repo.sendText(sessionId: _sessionId, text: text);
      state = [...state, reply];
    } catch (e) {
      state = [
        ...state,
        MessageEntity(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          author: MessageAuthor.bot,
          type: MessageType.text,
          text: 'Não consegui responder agora. Tente de novo em instantes.',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  /// Fluxo de foto: o `localPath`/`bytes` vêm do image_picker. A bolha do
  /// usuário exibe a imagem local (rápido, offline), mas o n8n recebe a URL
  /// pública do Cloudinary — o webhook é hardened e não baixa caminhos locais
  /// do celular. Ver `docs/N8N_API.md` §3.23 e `CloudinaryService`.
  Future<void> sendImage(String localPath, List<int> bytes,
      {String? filename, String? text}) async {
    final hasText = text != null && text.trim().isNotEmpty;
    // Mostra a imagem local imediatamente (com o texto opcional na mesma bolha).
    state = [
      ...state,
      MessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        author: MessageAuthor.user,
        type: MessageType.image,
        imagePath: localPath,
        localBytes: Uint8List.fromList(bytes),
        text: hasText ? text.trim() : null,
        createdAt: DateTime.now(),
      ),
    ];

    try {
      // 1. Sobe pro Cloudinary → URL pública que o n8n consegue baixar.
      final url = await _cloudinary.uploadBytes(bytes, filename: filename);
      // 2. Manda a URL (e o texto, se houver) pro consultor analisar a foto.
      final reply = await _repo.sendImage(
        sessionId: _sessionId,
        imageUrl: url,
        text: hasText ? text : null,
      );
      state = [...state, reply];
    } catch (_) {
      state = [
        ...state,
        MessageEntity(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          author: MessageAuthor.bot,
          type: MessageType.text,
          text: 'Não consegui analisar a imagem agora. Tente de novo.',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  /// Verdadeiro se o usuário já enviou ao menos uma foto do ambiente nesta
  /// conversa — condição pro botão "Ver no meu ambiente" aparecer, já que o
  /// preview funde a foto do ambiente com a do produto.
  bool get hasEnvironmentPhoto =>
      state.any((m) => m.type == MessageType.image && m.author == MessageAuthor.user);

  /// Gera um preview "produto no meu ambiente". Reusa a última foto do ambiente
  /// da sessão e a funde com a foto do produto via ModelScope, reacendendo o
  /// ambiente com a luz do produto. Limite 2/dia: ao estourar, a mensagem
  /// amigável do servidor (429) vira resposta do bot.
  ///
  /// A geração leva 2-4 min, mas o Cloudflare corta conexões em ~100s. Por isso
  /// é assíncrono: `startPreview` dispara e devolve um `task_id`; depois fazemos
  /// polling com `pollPreview` (reenviando o task_id) a cada 30s, até 5 min, até
  /// a imagem ficar pronta. Cada chamada é curta e não estoura o Cloudflare.
  Future<void> sendPreview(String productId) async {
    final genId = '${DateTime.now().millisecondsSinceEpoch}_gen';
    // Placeholder: quadrado com loading no lugar onde a imagem vai aparecer.
    state = [
      ...state,
      MessageEntity(
        id: genId,
        author: MessageAuthor.bot,
        type: MessageType.image,
        text: 'Gerando um preview do produto no seu ambiente... ✨',
        isGenerating: true,
        createdAt: DateTime.now(),
      ),
    ];

    try {
      // 1ª chamada: dispara e pega o task_id.
      final start =
          await _repo.startPreview(sessionId: _sessionId, productId: productId);
      // Polling de 8 min reusando o task_id.
      await _pollUntilDone(genId, productId, start, maxAttempts: 16);
    } on ApiException catch (e) {
      // 429 (limite diário) / 422 (sem foto) / 404 vêm com mensagem amigável.
      _replaceGen(genId, _botText('${genId}_lim', e.message));
    } catch (_) {
      _replaceGen(
        genId,
        _botText('${genId}_err', 'Não consegui gerar o preview agora. Tente de novo.'),
      );
    }
  }

  /// Botão "Tentar novamente": retoma o polling do MESMO task_id por mais ~2 min,
  /// sem disparar nova geração (a task já está rodando/feita no servidor).
  Future<void> retryPreview(
      String failedMsgId, String productId, String taskId) async {
    final genId = '${DateTime.now().millisecondsSinceEpoch}_gen';
    // Troca a mensagem de falha por um novo placeholder de loading.
    _replaceGen(
      failedMsgId,
      MessageEntity(
        id: genId,
        author: MessageAuthor.bot,
        type: MessageType.image,
        text: 'Verificando seu preview... ✨',
        isGenerating: true,
        createdAt: DateTime.now(),
      ),
    );
    try {
      final initial = PreviewStatus(
          state: PreviewState.processing, taskId: taskId);
      await _pollUntilDone(genId, productId, initial, maxAttempts: 4); // ~2 min
    } catch (_) {
      _showRetry(genId, productId, taskId);
    }
  }

  /// Loop de polling compartilhado. Em sucesso mostra a imagem; ao esgotar
  /// (ainda processando) mostra a mensagem com botão de tentar novamente.
  Future<void> _pollUntilDone(
    String genId,
    String productId,
    PreviewStatus initial, {
    required int maxAttempts,
  }) async {
    const interval = Duration(seconds: 30);
    var status = initial;
    var attempts = 0;
    while (status.state == PreviewState.processing && attempts < maxAttempts) {
      final taskId = status.taskId;
      if (taskId == null) break;
      await Future<void>.delayed(interval);
      attempts++;
      try {
        status = await _repo.pollPreview(
          sessionId: _sessionId,
          productId: productId,
          taskId: taskId,
        );
      } catch (_) {
        // erro transitório — tenta de novo no próximo ciclo
      }
    }

    if (status.state == PreviewState.ready && status.message != null) {
      _replaceGen(genId, status.message!);
    } else {
      // Ainda processando ou falhou → oferece retry com o último task_id.
      _showRetry(genId, productId, status.taskId);
    }
  }

  /// Mensagem de "demorou/falhou" com os dados pra o botão de retry.
  void _showRetry(String genId, String productId, String? taskId) {
    _replaceGen(
      genId,
      MessageEntity(
        id: '${genId}_retry',
        author: MessageAuthor.bot,
        type: MessageType.text,
        text:
            'A geração está demorando mais que o normal. Tente novamente mais tarde, daqui uns 30 minutos.',
        retryTaskId: taskId,
        retryProductId: productId,
        createdAt: DateTime.now(),
      ),
    );
  }

  MessageEntity _botText(String id, String text) => MessageEntity(
        id: id,
        author: MessageAuthor.bot,
        type: MessageType.text,
        text: text,
        createdAt: DateTime.now(),
      );

  /// Troca a bolha "Gerando..." (genId) pela mensagem final (imagem ou erro).
  void _replaceGen(String genId, MessageEntity replacement) {
    state = [
      for (final m in state)
        if (m.id == genId) replacement else m,
    ];
  }

  /// Apaga o histórico da conversa no servidor e reseta o chat (volta só pra
  /// saudação). Mantém a mesma sessão. Mantém o Postgres enxuto.
  Future<void> clearHistory() async {
    try {
      await _repo.clearHistory(_sessionId);
    } catch (_) {
      // mesmo se falhar no servidor, limpa localmente
    }
    state = [_welcome()];
  }
}

final consultantProvider =
    StateNotifierProvider<ConsultantNotifier, List<MessageEntity>>((ref) {
  return ConsultantNotifier(
    ref.watch(consultantRepositoryProvider),
    ref.watch(cloudinaryServiceProvider),
    ref.watch(_sessionIdProvider),
  );
});
