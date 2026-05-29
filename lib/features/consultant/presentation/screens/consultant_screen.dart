import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';
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

  /// Foto anexada (escolhida mas ainda não enviada). Fica em preview acima do
  /// campo até o usuário tocar em enviar — aí vai junto com o texto opcional.
  Uint8List? _pendingImageBytes;
  String? _pendingImagePath;
  String? _pendingImageName;

  bool get _hasPendingImage => _pendingImageBytes != null;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text;
    final notifier = ref.read(consultantProvider.notifier);

    if (_hasPendingImage) {
      // Foto anexada → envia imagem (com texto opcional junto).
      notifier.sendImage(
        _pendingImagePath ?? '',
        _pendingImageBytes!,
        filename: _pendingImageName,
        text: text.trim().isEmpty ? null : text,
      );
      _clearPendingImage();
      _textController.clear();
      return;
    }

    if (text.trim().isEmpty) return;
    notifier.sendText(text);
    _textController.clear();
  }

  /// Escolhe a foto e a ANEXA (preview acima do campo). Só envia no _send().
  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pendingImageBytes = bytes;
      _pendingImagePath = file.path;
      _pendingImageName = file.name;
    });
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImageBytes = null;
      _pendingImagePath = null;
      _pendingImageName = null;
    });
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar conversa?'),
        content: const Text(
            'Isso apaga todo o histórico desta conversa com o consultor. Não dá pra desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(consultantProvider.notifier).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // O consultor depende de chamadas autenticadas (JWT obrigatório no n8n).
    // Sem login não há token → o webhook responde 401. Em vez de deixar o
    // chat falhar silenciosamente, exige login antes de usar.
    final isLoggedIn = ref.watch(isLoggedInProvider);
    if (!isLoggedIn) {
      return const _SignedOutView();
    }

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
        actions: [
          if (messages.length > 1)
            IconButton(
              tooltip: 'Limpar conversa',
              icon: Icon(PhosphorIcons.trash(), size: 20),
              color: AppColors.gray500,
              onPressed: () => _confirmClear(context),
            ),
        ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview da foto anexada (some ao enviar ou remover).
                  if (_hasPendingImage) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.sm,
                          child: Image.memory(
                            _pendingImageBytes!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            iconSize: 18,
                            icon: const Icon(Icons.cancel, color: AppColors.gray500),
                            onPressed: _clearPendingImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Row(
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
                        hintText: _hasPendingImage
                            ? 'Conte o que procura (opcional)...'
                            : 'Pergunte sobre qualquer produto...',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tela exibida quando o usuário não está logado. O consultor faz requisições
/// autenticadas ao n8n (JWT), então convidamos a entrar antes de usar — mesmo
/// padrão da aba de perfil.
class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Consultor'),
        backgroundColor: AppColors.cream,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.amber100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  size: 56,
                  color: AppColors.amber600,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Entre para falar com o Consultor',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mande uma foto do seu ambiente ou conte o que precisa — '
                'a gente encontra a luz certa pra você.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Entrar'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Criar conta'),
                ),
              ),
            ],
          ),
        ),
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

class _MessageBubble extends ConsumerWidget {
  final MessageEntity message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUser = message.author == MessageAuthor.user;
    // Durante a geração, o texto fica dentro do quadrado de loading — não repete.
    final hasText = (message.text ?? '').isNotEmpty && !message.isGenerating;
    final recs = message.productRecommendations;
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
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Preview sendo gerado: quadrado com loading no lugar da imagem.
                if (message.isGenerating)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: AppRadius.md,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.amber600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Gerando seu preview...\nPode levar de 3 a 7 minutos.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.gray500),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Foto: do usuário (arquivo local) ou preview do bot (URL).
                if (!message.isGenerating &&
                    message.type == MessageType.image &&
                    message.imagePath != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.obsidian : AppColors.warmWhite,
                      borderRadius: AppRadius.md,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.sm,
                      child: message.localBytes != null
                          ? Image.memory(
                              message.localBytes!,
                              width: 200,
                              fit: BoxFit.cover,
                            )
                          : message.imagePath!.startsWith('http')
                              ? GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => _ImageViewer(
                                          imageUrl: message.imagePath!),
                                      fullscreenDialog: true,
                                    ),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: message.imagePath!,
                                    width: 240,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 240,
                                      height: 160,
                                      color: AppColors.gray100,
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 240,
                                      height: 160,
                                      color: AppColors.gray100,
                                      alignment: Alignment.center,
                                      child: Icon(PhosphorIcons.image(),
                                          color: AppColors.gray400),
                                    ),
                                  ),
                                )
                              : Image.file(
                                  File(message.imagePath!),
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                    ),
                  ),
                // Texto (saudação, resposta, rationale da recomendação).
                if (hasText)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color:
                          isUser ? AppColors.obsidian : AppColors.warmWhite,
                      borderRadius: AppRadius.md,
                    ),
                    child: Text(
                      message.text!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser
                            ? AppColors.warmWhite
                            : AppColors.obsidian,
                      ),
                    ),
                  ),
                // Botão "Tentar novamente" (quando o preview demorou/falhou).
                if (message.retryTaskId != null &&
                    message.retryProductId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: OutlinedButton.icon(
                      icon: Icon(PhosphorIcons.arrowClockwise(), size: 16),
                      label: const Text('Tentar novamente'),
                      onPressed: () => ref
                          .read(consultantProvider.notifier)
                          .retryPreview(
                            message.id,
                            message.retryProductId!,
                            message.retryTaskId!,
                          ),
                    ),
                  ),
                // Cards dos produtos recomendados pelo consultor.
                if (recs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final id in recs) _RecommendationCard(productId: id),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini-card de produto recomendado, exibido dentro de uma bolha do consultor.
/// Lê o produto do cache (`productByIdProvider`) e navega pro detalhe ao tocar.
class _RecommendationCard extends ConsumerWidget {
  final String productId;
  const _RecommendationCard({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productByIdProvider(productId));
    final product = productAsync.valueOrNull;
    if (product == null) return const SizedBox.shrink();

    // Botão de preview só faz sentido se há foto do ambiente na conversa.
    final canPreview = ref.watch(consultantProvider.notifier).hasEnvironmentPhoto;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => context.push('/products/${product.id}'),
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.sm,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: product.imageUrls.isEmpty
                            ? Container(color: AppColors.gray100)
                            : CachedNetworkImage(
                                imageUrl: product.imageUrls.first,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: AppColors.gray100),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.gray100,
                                  child: Icon(PhosphorIcons.lightbulb(),
                                      color: AppColors.gray400, size: 18),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.obsidian,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(PhosphorIcons.caretRight(),
                        size: 16, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
            if (canPreview)
              InkWell(
                onTap: () =>
                    ref.read(consultantProvider.notifier).sendPreview(product.id),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.obsidian,
                    border: Border(top: BorderSide(color: AppColors.gray100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                          size: 14, color: AppColors.amber400),
                      const SizedBox(width: 6),
                      Text(
                        'Ver no meu ambiente',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Visualizador de imagem em tela cheia: pinça pra zoom e botão de salvar na
/// galeria. Usado ao tocar no preview "produto no meu ambiente".
class _ImageViewer extends StatefulWidget {
  final String imageUrl;
  const _ImageViewer({required this.imageUrl});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final res = await http.get(Uri.parse(widget.imageUrl));
      if (res.statusCode != 200) throw Exception('download falhou');
      await Gal.putImageBytes(res.bodyBytes, name: 'raito-preview');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem salva na galeria!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não consegui salvar a imagem.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Salvar na galeria',
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Icon(PhosphorIcons.downloadSimple(), color: Colors.white),
            onPressed: _save,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const CircularProgressIndicator(color: AppColors.amber600),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}
