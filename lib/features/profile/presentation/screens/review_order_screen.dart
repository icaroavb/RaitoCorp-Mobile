import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/upload/cloudinary_service.dart';
import '../../../../core/upload/image_source_sheet.dart';
import '../../data/orders_repository.dart';
import '../providers/orders_provider.dart';

/// Tela do CLIENTE avaliar um pedido entregue: nota, comentário e foto opcional.
class ReviewOrderScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ReviewOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends ConsumerState<ReviewOrderScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  String? _photoUrl;
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await pickImageWithSource(context);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await ref
          .read(cloudinaryServiceProvider)
          .uploadBytes(bytes, filename: file.name);
      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha no upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(ordersRepositoryProvider).review(
            orderId: widget.orderId,
            rating: _rating,
            comment: _comment.text.trim(),
            photoUrl: _photoUrl,
          );
      // Recarrega pedidos pra refletir reviewed=true.
      await ref.read(ordersProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obrigado pela avaliação!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível enviar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
          backgroundColor: AppColors.cream, title: const Text('Avaliar pedido')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Text('Como foi sua experiência?', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.amber400,
                    size: 40,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _comment,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentário',
              hintText: 'Conte como foi o produto e a entrega...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Foto do produto (opcional)',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: _uploading ? null : _pickPhoto,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
                image: _photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: _uploading
                  ? const Center(child: CircularProgressIndicator())
                  : _photoUrl == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.gray400, size: 28),
                              SizedBox(height: 6),
                              Text('Tirar ou escolher foto',
                                  style: TextStyle(color: AppColors.gray500)),
                            ],
                          ),
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                                onPressed: () =>
                                    setState(() => _photoUrl = null),
                              ),
                            ),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enviar avaliação'),
          ),
        ],
      ),
    );
  }
}
