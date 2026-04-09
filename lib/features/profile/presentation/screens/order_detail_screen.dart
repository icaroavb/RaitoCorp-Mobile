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

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderByIdProvider(orderId));
    final theme = Theme.of(context);

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Pedido'),
          backgroundColor: AppColors.cream,
        ),
        body: const Center(child: Text('Pedido não encontrado.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Pedido #${order.id}'),
        backgroundColor: AppColors.cream,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: order.status.isDelivered
                  ? AppColors.successBg
                  : order.status.isCancelled
                      ? const Color(0xFFFEE2E2)
                      : AppColors.amber100,
              borderRadius: AppRadius.md,
            ),
            child: Row(
              children: [
                Icon(
                  order.status.isDelivered
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : order.status.isCancelled
                          ? PhosphorIcons.xCircle(PhosphorIconsStyle.fill)
                          : PhosphorIcons.truck(PhosphorIconsStyle.fill),
                  size: 28,
                  color: order.status.isDelivered
                      ? AppColors.success
                      : order.status.isCancelled
                          ? AppColors.error
                          : AppColors.amber600,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.label,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (order.estimatedDelivery != null &&
                          !order.status.isDelivered &&
                          !order.status.isCancelled)
                        Text(
                          'Previsão: ${DateFormat('EEE, dd MMM', 'pt_BR').format(order.estimatedDelivery!)}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Timeline
          _Section(
            title: 'Acompanhamento',
            child: Column(
              children: [
                for (int i = 0; i < order.timeline.length; i++)
                  _TimelineTile(
                    event: order.timeline[i],
                    isLast: i == order.timeline.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Itens
          _Section(
            title: 'Itens do pedido',
            child: Column(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.sm,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: theme.textTheme.titleSmall),
                              Text(
                                '${item.quantity}x · ${item.subtitle}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.gray500),
                              ),
                            ],
                          ),
                        ),
                        Text(item.subtotal.formatCurrency(),
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Endereço
          _Section(
            title: 'Endereço de entrega',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.mapPin(),
                        size: 16, color: AppColors.amber600),
                    const SizedBox(width: AppSpacing.xs),
                    Text(order.address.label,
                        style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(order.address.line1, style: theme.textTheme.bodyMedium),
                Text(order.address.line2, style: theme.textTheme.bodyMedium),
                Text(order.address.line3,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray500)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Pagamento
          _Section(
            title: 'Pagamento',
            child: Column(
              children: [
                _Line(label: 'Subtotal', value: order.subtotal.formatCurrency()),
                _Line(
                  label: 'Frete',
                  value: order.shipping == 0
                      ? 'Grátis'
                      : order.shipping.formatCurrency(),
                ),
                if (order.discount > 0)
                  _Line(
                    label: 'Desconto',
                    value: '- ${order.discount.formatCurrency()}',
                    valueColor: AppColors.success,
                  ),
                const Divider(height: 20),
                _Line(
                  label: 'Total',
                  value: order.total.formatCurrency(),
                  bold: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(PhosphorIcons.creditCard(),
                        size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                      order.paymentMethod,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          if (order.status.isDelivered && !order.reviewed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/profile/reviews'),
                icon: Icon(PhosphorIcons.star(), size: 18),
                label: const Text('Avaliar este pedido'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (order.status.isInProgress) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () => _confirmCancel(context, ref, order),
                child: const Text('Cancelar pedido'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contato aberto no WhatsApp.')),
                );
              },
              child: const Text('Preciso de ajuda'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, OrderEntity order) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: const Text(
            'Essa ação não pode ser desfeita. Seu estorno será feito em até 5 dias úteis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(ordersProvider.notifier).cancelOrder(order.id);
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pedido cancelado.')),
              );
            },
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final OrderTimelineEvent event;
  final bool isLast;
  const _TimelineTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = event.completed || event.active;
    final color = event.active
        ? AppColors.amber400
        : done
            ? AppColors.success
            : AppColors.gray300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: done ? color : AppColors.warmWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check,
                        size: 11, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? color : AppColors.gray200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: event.active ? FontWeight.w700 : FontWeight.w500,
                      color: done ? AppColors.obsidian : AppColors.gray400,
                    ),
                  ),
                  if (event.timestamp != null)
                    Text(
                      DateFormat('dd MMM · HH:mm', 'pt_BR')
                          .format(event.timestamp!),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.gray500, fontSize: 11),
                    ),
                  if (event.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.description!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.gray700),
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

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _Line({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style?.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
