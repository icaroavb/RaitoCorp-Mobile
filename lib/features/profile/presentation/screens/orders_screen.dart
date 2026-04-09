import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/orders_provider.dart';

enum OrdersFilter { all, inProgress, delivered, cancelled }

extension _OrdersFilterLabel on OrdersFilter {
  String get label => switch (this) {
        OrdersFilter.all => 'Todos',
        OrdersFilter.inProgress => 'Em andamento',
        OrdersFilter.delivered => 'Entregues',
        OrdersFilter.cancelled => 'Cancelados',
      };
}

final _ordersFilterProvider =
    StateProvider.autoDispose<OrdersFilter>((_) => OrdersFilter.all);

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_ordersFilterProvider);
    final all = ref.watch(userOrdersProvider);

    final filtered = switch (filter) {
      OrdersFilter.all => all,
      OrdersFilter.inProgress =>
        all.where((o) => o.status.isInProgress).toList(),
      OrdersFilter.delivered =>
        all.where((o) => o.status.isDelivered).toList(),
      OrdersFilter.cancelled =>
        all.where((o) => o.status.isCancelled).toList(),
    };

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Meus pedidos'),
        backgroundColor: AppColors.cream,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              itemCount: OrdersFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final f = OrdersFilter.values[i];
                final selected = f == filter;
                return Center(
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(_ordersFilterProvider.notifier).state = f,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyOrders(filter: filter)
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _OrderCard(order: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final OrdersFilter filter;
  const _EmptyOrders({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body) = switch (filter) {
      OrdersFilter.all => (
          'Você ainda não comprou nada',
          'Seus pedidos vão aparecer aqui assim que você fechar a primeira compra.'
        ),
      OrdersFilter.inProgress => (
          'Sem pedidos em andamento',
          'Quando você fizer um pedido, vamos acompanhar ele em tempo real por aqui.'
        ),
      OrdersFilter.delivered => (
          'Nenhum pedido entregue',
          'Seus pedidos concluídos ficam guardados aqui.'
        ),
      OrdersFilter.cancelled => (
          'Nenhum pedido cancelado',
          'Bom sinal! Tudo que você pediu seguiu em frente.'
        ),
    };

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
              child: Icon(PhosphorIcons.package(),
                  size: 48, color: AppColors.amber600),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: AppColors.gray500),
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
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = order.items.first;
    return InkWell(
      borderRadius: AppRadius.md,
      onTap: () => context.push('/profile/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${order.id}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.gray500),
                ),
                const Spacer(),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.sm,
                  child: CachedNetworkImage(
                    imageUrl: first.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.gray100,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.productName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.items.length > 1
                            ? '${order.items.length} itens'
                            : '${first.quantity}x ${first.subtitle}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.gray500),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        DateFormat('dd MMM yyyy', 'pt_BR')
                            .format(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.gray400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  order.total.formatCurrency(),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.confirmed ||
      OrderStatus.preparing ||
      OrderStatus.shipped =>
        (AppColors.amber100, AppColors.amber600),
      OrderStatus.delivered => (AppColors.successBg, AppColors.success),
      OrderStatus.cancelled =>
        (const Color(0xFFFEE2E2), AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.full,
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
