import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/consultant_provider.dart';

class ConsultantScreen extends ConsumerStatefulWidget {
  const ConsultantScreen({super.key});

  @override
  ConsumerState<ConsultantScreen> createState() => _ConsultantScreenState();
}

class _ConsultantScreenState extends ConsumerState<ConsultantScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    ref.read(consultantProvider.notifier).sendText(text);
    _textController.clear();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file != null) {
      ref.read(consultantProvider.notifier).sendImage(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(consultantProvider);
    final showQuickReplies = messages.length <= 1;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.full,
              ),
              child: Text(
                'Hoje',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              reverse: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (showQuickReplies) ...[
                  Center(
                    child: Text(
                      'Experimente perguntar:',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuickReply(
                    text: '"Quero luz quente para o quarto"',
                    onTap: () => ref
                        .read(consultantProvider.notifier)
                        .sendText('Quero luz quente para o quarto'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickReply(
                    text: '"Tenho bocal E27, o que funciona?"',
                    onTap: () => ref
                        .read(consultantProvider.notifier)
                        .sendText('Tenho bocal E27, o que funciona?'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickReply(
                    text: '"Qual a mais econômica para sala?"',
                    onTap: () => ref
                        .read(consultantProvider.notifier)
                        .sendText('Qual a mais econômica para sala?'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                for (final msg in messages) _MessageBubble(message: msg),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.warmWhite,
                border: Border(top: BorderSide(color: AppColors.gray100)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(PhosphorIcons.camera(), size: 20),
                    color: AppColors.gray500,
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.image(), size: 20),
                    color: AppColors.gray500,
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Pergunte sobre qualquer produto...',
                        filled: true,
                        fillColor: AppColors.gray50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.full,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: AppColors.obsidian,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.send_rounded,
                          color: AppColors.warmWhite,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReply extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _QuickReply({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.gray200),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.author == MessageAuthor.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.obsidian,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                color: AppColors.amber400,
                size: 14,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color:
                    isUser ? AppColors.obsidian : AppColors.warmWhite,
                borderRadius: AppRadius.md,
              ),
              child: message.type == MessageType.image &&
                      message.imagePath != null
                  ? ClipRRect(
                      borderRadius: AppRadius.sm,
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      message.text ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser
                            ? AppColors.warmWhite
                            : AppColors.obsidian,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
