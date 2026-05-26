import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../profile/domain/entities/order_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/new_product_form.dart';

/// Hub do administrador: gerencia pedidos (avança etapa) e faz o CRUD de
/// produtos. Acesso controlado por `is_admin` na navegação (profile_screen).
class AdminHubScreen extends ConsumerWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('Painel Admin'),
          bottom: const TabBar(
            labelColor: AppColors.amber600,
            unselectedLabelColor: AppColors.gray500,
            indicatorColor: AppColors.amber400,
            tabs: [
              Tab(text: 'Pedidos'),
              Tab(text: 'Produtos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersTab(),
            _ProductsTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Aba de pedidos ──────────────────────────────────────────────────────────

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(adminOrdersProvider.notifier).refresh(),
      child: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          const SizedBox(height: 120),
          Center(child: Text('Erro ao carregar: $e')),
        ]),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('Nenhum pedido ainda.')),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.page),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _AdminOrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerStatefulWidget {
  final OrderEntity order;
  const _AdminOrderCard({required this.order});

  @override
  ConsumerState<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends ConsumerState<_AdminOrderCard> {
  bool _loading = false;

  Future<void> _advance() async {
    setState(() => _loading = true);
    try {
      await ref.read(adminOrdersProvider.notifier).advance(widget.order.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível avançar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = widget.order;
    final canAdvance = o.status.isInProgress;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pedido #${o.id}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              _StatusChip(status: o.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(o.userEmail,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.sm),
          Text('${o.totalItems} item(s) · ${o.total.formatCurrency()}',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAdvance && !_loading ? _advance : null,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(canAdvance
                      ? 'Avançar para: ${_nextLabel(o.status)}'
                      : o.status.label),
            ),
          ),
        ],
      ),
    );
  }

  String _nextLabel(OrderStatus s) => switch (s) {
        OrderStatus.confirmed => 'Em preparo',
        OrderStatus.preparing => 'Saiu para entrega',
        OrderStatus.shipped => 'Entregue',
        _ => '—',
      };
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.delivered => (AppColors.successBg, AppColors.success),
      OrderStatus.cancelled => (const Color(0xFFFDE8E8), AppColors.error),
      _ => (AppColors.amber100, AppColors.amber600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Aba de produtos (CRUD) ──────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  void _openForm(BuildContext context, WidgetRef ref, {ProductEntity? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.page,
          right: AppSpacing.page,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(existing == null ? 'Novo produto' : 'Editar produto',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              NewProductForm(
                existing: existing,
                onSaved: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ProductEntity p) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Remover "${p.name}" do catálogo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ref.read(adminProductsProvider.notifier).remove(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto removido.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao remover: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.amber400,
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProductsProvider.notifier).refresh(),
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text('Erro: $e')),
          ]),
          data: (products) {
            if (products.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('Nenhum produto cadastrado.')),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, AppSpacing.page, AppSpacing.page, 96),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final p = products[i];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: p.imageUrls.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: p.imageUrls.first,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    const _ImgFallback())
                            : const _ImgFallback(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(p.price.formatCurrency(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.gray500)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.amber600),
                        onPressed: () =>
                            _openForm(context, ref, existing: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: () => _confirmDelete(context, ref, p),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();
  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        color: AppColors.gray100,
        child: const Icon(Icons.lightbulb_outline, color: AppColors.gray400),
      );
}
