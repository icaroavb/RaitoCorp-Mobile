import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message_entity.dart';

class ConsultantNotifier extends StateNotifier<List<MessageEntity>> {
  ConsultantNotifier() : super(_initial);

  static final _initial = <MessageEntity>[
    MessageEntity(
      id: 'welcome',
      author: MessageAuthor.bot,
      type: MessageType.text,
      text:
          'Olá! Sou o Consultor Raitõ. Manda uma foto do seu ambiente ou me conta o que precisa — a gente encontra a luz certa sem complicação.',
      createdAt: DateTime.now(),
    ),
  ];

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
    await Future.delayed(const Duration(milliseconds: 800));
    state = [
      ...state,
      MessageEntity(
        id: '${DateTime.now().millisecondsSinceEpoch}_bot',
        author: MessageAuthor.bot,
        type: MessageType.text,
        text:
            'Entendi! Para esse tipo de ambiente eu recomendo começar com luz quente (3000K) e um bocal E27. Quer que eu mostre algumas opções?',
        createdAt: DateTime.now(),
      ),
    ];
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
    await Future.delayed(const Duration(milliseconds: 1200));
    state = [
      ...state,
      MessageEntity(
        id: '${DateTime.now().millisecondsSinceEpoch}_bot',
        author: MessageAuthor.bot,
        type: MessageType.text,
        text:
            'Analisei sua foto! Esse ambiente pede uma iluminação mais aconchegante. Dei uma olhada no nosso catálogo — o Pendente Moderno combinaria muito bem aí.',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

final consultantProvider =
    StateNotifierProvider<ConsultantNotifier, List<MessageEntity>>((ref) {
  return ConsultantNotifier();
});
