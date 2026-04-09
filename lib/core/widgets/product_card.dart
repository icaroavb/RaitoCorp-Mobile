import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/profile/presentation/providers/favorites_provider.dart';
import '../../shared/extensions/number_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'temperature_bar.dart';

/// Card vertical de produto (usado em Home e lista).
class ProductCard extends ConsumerWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    required this.product,
    this.onTap,
    this.onAddToCart,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(isFavoriteProvider(product.id));
    final user = ref.watch(currentUserProvider);
    return Material(
      color: AppColors.warmWhite,
      borderRadius: AppRadius.md,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem + barra de temperatura
            Stack(
              children: [
                Hero(
                  tag: 'product-image-${product.id}',
                  child: AspectRatio(
                    aspectRatio: 16 / 11,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.gray100),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.gray100,
                        alignment: Alignment.center,
                        child: Icon(
                          PhosphorIcons.lightbulb(),
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: TemperatureBar(temperature: product.lightTemperature),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: AppColors.warmWhite,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Entre para salvar seus favoritos.'),
                            ),
                          );
                          return;
                        }
                        ref
                            .read(favoritesProvider.notifier)
                            .toggle(user.email, product.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFavorite
                              ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                              : PhosphorIcons.heart(),
                          size: 18,
                          color: isFavorite
                              ? AppColors.error
                              : AppColors.obsidian,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        product.price.formatCurrency(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (product.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: AppRadius.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _compatibilityText(product),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (onAddToCart != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        child: const Text('Adicionar ao carrinho'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compatibilityText(ProductEntity p) {
    final parts = <String>[];
    parts.add('${p.socketType} (bocal comum)');
    if (p.isEasyInstall) parts.add('Fácil instalar');
    return parts.join(' · ');
  }
}
