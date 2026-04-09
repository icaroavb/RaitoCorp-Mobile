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
import '../../../products/presentation/providers/products_provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(cart.isEmpty ? 'Carrinho' : 'Carrinho ($totalItems item${totalItems > 1 ? 's' : ''})'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: Text(
                'Limpar tudo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.amber600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCartView()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: [
                for (final item in cart) ...[
                  _CartItemCard(
                    imageUrl: item.imageUrl,
                    name: item.productName,
                    subtitle: item.subtitle,
                    price: item.price * item.quantity,
                    quantity: item.quantity,
                    onRemove: () =>
                        ref.read(cartProvider.notifier).removeItem(item.productId),
                    onDecrease: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(item.productId, item.quantity - 1),
                    onIncrease: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(item.productId, item.quantity + 1),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: AppRadius.md,
                  ),
                  child: Column(
                    children: [
                      Text('RESUMO DO PEDIDO',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.md),
                      _summaryRow(context, 'Subtotal',
                          subtotal.formatCurrency()),
                      const SizedBox(height: AppSpacing.sm),
                      _summaryRow(context, 'Frete', 'Grátis',
                          valueColor: AppColors.success),
                      const Divider(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: theme.textTheme.titleLarge),
                          Text(
                            subtotal.formatCurrency(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _PaymentChip(label: 'Pix'),
                    const SizedBox(width: AppSpacing.sm),
                    _PaymentChip(label: 'Cartão'),
                    const SizedBox(width: AppSpacing.sm),
                    _PaymentChip(label: 'Boleto'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                      size: 14,
                      color: AppColors.amber600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pague com Pix e ganhe 5% de desconto',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.amber600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Text(
                    'Pagamento 100% seguro · Entrega estimada em 2 dias úteis',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => _proceedToCheckout(context, ref),
                  child: Text('Finalizar compra · ${subtotal.formatCurrency()}'),
                ),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
    );
  }

  /// Regra de negócio: exige login antes de prosseguir.
  /// - Sem login → vai para /login?redirect=/checkout
  /// - Com login → vai direto para /checkout
  void _proceedToCheckout(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      _showLoginRequiredSheet(context);
      return;
    }
    context.push('/checkout');
  }

  void _showLoginRequiredSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.warmWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            top: AppSpacing.xxl,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: AppRadius.full,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.amber100,
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIcons.lockKey(),
                    color: AppColors.amber600, size: 32),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Entre para finalizar',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Você precisa estar logado para fechar o pedido. Seus itens continuam salvos no carrinho.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.gray500),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/login?redirect=/checkout');
                  },
                  child: const Text('Fazer login'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/register?redirect=/checkout');
                  },
                  child: const Text('Criar conta'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.obsidian,
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String subtitle;
  final double price;
  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  const _CartItemCard({
    required this.imageUrl,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.quantity,
    required this.onRemove,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.sm,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 64,
                height: 64,
                color: AppColors.gray100,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, style: theme.textTheme.titleMedium),
                    ),
                    Text(
                      price.formatCurrency(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.amber600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onRemove,
                      child: Text(
                        'Remover',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.gray500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _QtyButton(icon: Icons.remove, onTap: onDecrease),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: onIncrease,
                      filled: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? AppColors.obsidian : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: filled ? AppColors.obsidian : AppColors.gray300,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? AppColors.warmWhite : AppColors.obsidian,
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  const _PaymentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.full,
          border: Border.all(color: AppColors.amber400),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.amber600,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _EmptyCartView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bestSellersAsync = ref.watch(bestSellersProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.amber100,
              borderRadius: AppRadius.md,
            ),
            child: Icon(
              PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
              size: 36,
              color: AppColors.amber600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Seu carrinho está escuro',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Adicione produtos e deixe seu ambiente do jeito que você quer.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => context.go('/products'),
          child: const Text('Explorar produtos'),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text('VOCÊ PODE GOSTAR DE...', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        bestSellersAsync.maybeWhen(
          data: (list) => SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.take(4).length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final p = list[i];
                return InkWell(
                  onTap: () => context.go('/products/${p.id}'),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppColors.warmWhite,
                      borderRadius: AppRadius.md,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 130,
                          child: CachedNetworkImage(
                            imageUrl: p.imageUrls.first,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.price.formatCurrency(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.amber600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
