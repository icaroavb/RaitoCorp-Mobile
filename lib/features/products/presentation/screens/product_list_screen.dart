import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/products_provider.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(filteredProductsProvider);
    final filter = ref.watch(productFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.question()),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: TextField(
              onChanged: (v) => ref
                  .read(productFilterProvider.notifier)
                  .update((f) => f.copyWith(query: v)),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass(),
                  color: AppColors.gray400,
                  size: 20,
                ),
                hintText: 'Ex: luz quente para quarto...',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.full,
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.full,
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.full,
                  borderSide:
                      const BorderSide(color: AppColors.obsidian, width: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: filter.room == null,
                  onTap: () => ref
                      .read(productFilterProvider.notifier)
                      .update((f) => f.copyWith(clearRoom: true)),
                ),
                const SizedBox(width: AppSpacing.sm),
                for (final room in Room.values) ...[
                  _FilterChip(
                    label: room.label,
                    selected: filter.room == room,
                    onTap: () => ref
                        .read(productFilterProvider.notifier)
                        .update((f) => f.copyWith(room: room)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: productsAsync.when(
              data: (list) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.xxl,
                ),
                itemCount: list.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '${list.length} produtos encontrados',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.amber600,
                        ),
                      ),
                    );
                  }
                  final product = list[i - 1];
                  return ProductCard(
                    product: product,
                    onTap: () => context.go('/products/${product.id}'),
                    onAddToCart: () {
                      ref.read(cartProvider.notifier).addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} adicionado'),
                          action: SnackBarAction(
                            label: 'Ver carrinho',
                            textColor: AppColors.amber400,
                            onPressed: () => context.go('/cart'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.full,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.obsidian : AppColors.warmWhite,
          borderRadius: AppRadius.full,
          border: Border.all(
            color: selected ? AppColors.obsidian : AppColors.gray300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.warmWhite : AppColors.obsidian,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
