import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final ids = ref.watch(userFavoriteIdsProvider);
    final allProductsAsync = ref.watch(allProductsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Favoritos'),
        backgroundColor: AppColors.cream,
      ),
      body: allProductsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erro ao carregar.')),
        data: (all) {
          final favorites =
              all.where((p) => ids.contains(p.id)).toList();

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.amber100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(PhosphorIcons.heart(),
                          size: 48, color: AppColors.amber600),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Nenhum favorito ainda',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Toque no coração de qualquer produto para salvar aqui.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.gray500),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () => context.go('/products'),
                      child: const Text('Explorar produtos'),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.page),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.66,
            ),
            itemCount: favorites.length,
            itemBuilder: (_, i) => _FavoriteTile(
              product: favorites[i],
              onRemove: user == null
                  ? null
                  : () => ref
                      .read(favoritesProvider.notifier)
                      .toggle(user.email, favorites[i].id),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onRemove;
  const _FavoriteTile({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.warmWhite,
      borderRadius: AppRadius.md,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.push('/products/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.gray100),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: AppColors.warmWhite,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRemove,
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          PhosphorIcons.heart(PhosphorIconsStyle.fill),
                          color: AppColors.error,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price.formatCurrency(),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
