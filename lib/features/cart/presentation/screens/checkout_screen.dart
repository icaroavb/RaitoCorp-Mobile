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
import '../../../profile/data/orders_repository.dart';
import '../../../profile/domain/entities/address_entity.dart';
import '../../../profile/presentation/providers/addresses_provider.dart';
import '../../../profile/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/widgets/address_form_sheet.dart';
import '../providers/cart_provider.dart';

enum PaymentMethod { pix, credit, boleto }

extension on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.pix => 'Pix',
        PaymentMethod.credit => 'Cartão de crédito',
        PaymentMethod.boleto => 'Boleto',
      };
  IconData icon(BuildContext context) => switch (this) {
        PaymentMethod.pix => PhosphorIcons.lightning(),
        PaymentMethod.credit => PhosphorIcons.creditCard(),
        PaymentMethod.boleto => PhosphorIcons.barcode(),
      };
  String get subtitle => switch (this) {
        PaymentMethod.pix => 'Aprovação imediata · 5% de desconto',
        PaymentMethod.credit => 'Até 10x sem juros',
        PaymentMethod.boleto => 'Vence em 2 dias úteis',
      };
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _paymentMethod = PaymentMethod.pix;
  String? _selectedAddressId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final addresses = ref.watch(userAddressesProvider);
    final theme = Theme.of(context);

    if (user == null || cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Text(
            cart.isEmpty
                ? 'Seu carrinho está vazio.'
                : 'Faça login para finalizar.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Inicializa endereço selecionado com o padrão
    final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull ??
        addresses.firstOrNull;
    final selected = _selectedAddressId != null
        ? addresses.where((a) => a.id == _selectedAddressId).firstOrNull ??
            defaultAddr
        : defaultAddr;

    final shipping = 0.0;
    final discount = _paymentMethod == PaymentMethod.pix ? subtotal * 0.05 : 0.0;
    final total = subtotal + shipping - discount;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Finalizar compra'),
        backgroundColor: AppColors.cream,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          // Itens
          _Section(
            title: 'Itens do pedido (${cart.length})',
            child: Column(
              children: [
                for (final item in cart)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.sm,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                '${item.quantity}x · ${item.subtitle}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.gray500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          (item.price * item.quantity).formatCurrency(),
                          style: theme.textTheme.titleSmall,
                        ),
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
            action: addresses.length > 1
                ? TextButton(
                    onPressed: () =>
                        _showAddressPicker(context, addresses, selected?.id),
                    child: const Text('Trocar'),
                  )
                : null,
            child: selected == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Você ainda não cadastrou um endereço.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.gray500),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () => showAddressFormSheet(
                            context, ref, user.email),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar endereço'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(PhosphorIcons.mapPin(),
                              size: 16, color: AppColors.amber600),
                          const SizedBox(width: AppSpacing.xs),
                          Text(selected.label,
                              style: theme.textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(selected.line1),
                      Text(selected.line2),
                      Text(selected.line3,
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
                for (final m in PaymentMethod.values) ...[
                  _PaymentOption(
                    method: m,
                    selected: _paymentMethod == m,
                    onTap: () => setState(() => _paymentMethod = m),
                  ),
                  if (m != PaymentMethod.values.last)
                    const Divider(height: 1, color: AppColors.gray100),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Resumo
          _Section(
            title: 'Resumo',
            child: Column(
              children: [
                _Line(label: 'Subtotal', value: subtotal.formatCurrency()),
                _Line(
                    label: 'Frete',
                    value: shipping == 0
                        ? 'Grátis'
                        : shipping.formatCurrency(),
                    valueColor: AppColors.success),
                if (discount > 0)
                  _Line(
                    label: 'Desconto Pix (5%)',
                    value: '- ${discount.formatCurrency()}',
                    valueColor: AppColors.success,
                  ),
                const Divider(height: 20),
                _Line(
                  label: 'Total',
                  value: total.formatCurrency(),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: selected == null
                ? null
                : () => _confirmOrder(
                      user.email,
                      selected,
                      subtotal,
                      shipping,
                      discount,
                    ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Confirmar pedido · ${total.formatCurrency()}'),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.shieldCheck(),
                    size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Pagamento 100% seguro',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  void _showAddressPicker(
    BuildContext context,
    List<AddressEntity> addresses,
    String? currentId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            Text('Escolha o endereço',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final a in addresses) ...[
              InkWell(
                onTap: () {
                  setState(() => _selectedAddressId = a.id);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: currentId == a.id
                        ? AppColors.amber100
                        : AppColors.warmWhite,
                    borderRadius: AppRadius.md,
                    border: Border.all(
                      color: currentId == a.id
                          ? AppColors.amber400
                          : AppColors.gray100,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.label,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(a.line1),
                      Text(a.line2),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOrder(
    String email,
    AddressEntity address,
    double subtotal,
    double shipping,
    double discount,
  ) async {
    final cart = ref.read(cartProvider);
    final repo = ref.read(ordersRepositoryProvider);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final order = await repo.create(
        items: cart,
        address: address,
        paymentMethod: _paymentMethod.label,
        subtotal: subtotal,
        shipping: shipping,
        discount: discount,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ref.read(ordersProvider.notifier).addOrder(order);
      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      context.pushReplacement('/checkout/success/${order.id}');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível finalizar: $e')),
      );
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Section({required this.title, required this.child, this.action});

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
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.amber100 : AppColors.gray50,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(
                method.icon(context),
                color: selected ? AppColors.amber600 : AppColors.obsidian,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: theme.textTheme.titleSmall),
                  Text(
                    method.subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.amber400 : AppColors.gray300,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.amber400,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
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
