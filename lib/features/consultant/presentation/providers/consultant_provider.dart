import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/consultant_repository.dart';
import '../../domain/entities/message_entity.dart';

/// Gera um session id por instância do app. Persistir em Hive é trivial
/// se quisermos retomar conversas entre sessões; por ora vive em memória.
final _sessionIdProvider = Provider<String>(
  (_) => 'sess-${DateTime.now().millisecondsSinceEpoch}',
);

class ConsultantNotifier extends StateNotifier<List<MessageEntity>> {
  ConsultantNotifier(this._repo, this._sessionId) : super([_welcome()]);

  final ConsultantRepository _repo;
  final String _sessionId;

  static MessageEntity _welcome() => MessageEntity(
        id: 'welcome',
        author: MessageAuthor.bot,
        type: MessageType.text,
        text:
            'Olá! Sou o Consultor Raitõ. Manda uma foto do seu ambiente ou me conta o que precisa — a gente encontra a luz certa sem complicação.',
        createdAt: DateTime.now(),
      );

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

  Future<void> sendImage(String path) async {
    state = [
      ...state,
      MessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        author: MessageAuthor.user,
        type: MessageType.image,
        imagePath: path,
        createdAt: DateTime.now(),
      ),
    ];

    try {
      final reply =
          await _repo.sendImage(sessionId: _sessionId, imagePath: path);
      state = [...state, reply];
    } catch (_) {
      state = [
        ...state,
        MessageEntity(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          author: MessageAuthor.bot,
          type: MessageType.text,
          text: 'Não consegui analisar a imagem agora.',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }
}

final consultantProvider =
    StateNotifierProvider<ConsultantNotifier, List<MessageEntity>>((ref) {
  return ConsultantNotifier(
    ref.watch(consultantRepositoryProvider),
    ref.watch(_sessionIdProvider),
  );
});
