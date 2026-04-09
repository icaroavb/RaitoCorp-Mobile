import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/orders_provider.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(userOrdersProvider);
    final toReview = orders
        .where((o) => o.status.isDelivered && !o.reviewed)
        .toList();
    final reviewed = orders
        .where((o) => o.status.isDelivered && o.reviewed)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Minhas avaliações'),
        backgroundColor: AppColors.cream,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.obsidian,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.amber400,
          tabs: [
            Tab(text: 'Para avaliar (${toReview.length})'),
            Tab(text: 'Já avaliados (${reviewed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OrdersList(
            orders: toReview,
            emptyTitle: 'Nenhum produto para avaliar',
            emptyBody: 'Depois que você receber um pedido, ele aparece aqui.',
            showRateButton: true,
          ),
          _OrdersList(
            orders: reviewed,
            emptyTitle: 'Você ainda não avaliou nada',
            emptyBody: 'Suas avaliações enviadas ficam guardadas aqui.',
            showRateButton: false,
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderEntity> orders;
  final String emptyTitle;
  final String emptyBody;
  final bool showRateButton;
  const _OrdersList({
    required this.orders,
    required this.emptyTitle,
    required this.emptyBody,
    required this.showRateButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.star(),
                  size: 56, color: AppColors.gray400),
              const SizedBox(height: AppSpacing.lg),
              Text(emptyTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                emptyBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.gray500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.page),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final order = orders[i];
        final item = order.items.first;
        return Container(
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
                          'Entregue em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(order.createdAt)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (showRateButton)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRateSheet(context, item.productName),
                    icon: Icon(PhosphorIcons.star(), size: 18),
                    label: const Text('Avaliar produto'),
                  ),
                )
              else
                Row(
                  children: [
                    for (int s = 0; s < 5; s++)
                      Icon(
                        PhosphorIcons.star(PhosphorIconsStyle.fill),
                        size: 18,
                        color: s < 5 ? AppColors.amber400 : AppColors.gray300,
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Avaliado por você',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRateSheet(BuildContext context, String productName) {
    int rating = 5;
    final comment = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.page,
              right: AppSpacing.page,
              top: AppSpacing.lg,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: AppRadius.full,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Avaliar $productName',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int s = 1; s <= 5; s++)
                      IconButton(
                        onPressed: () => setState(() => rating = s),
                        icon: Icon(
                          PhosphorIcons.star(
                            s <= rating
                                ? PhosphorIconsStyle.fill
                                : PhosphorIconsStyle.regular,
                          ),
                          size: 36,
                          color: AppColors.amber400,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: comment,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Conte como foi sua experiência (opcional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Obrigado pela avaliação!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Enviar avaliação'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
