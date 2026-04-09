import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/address_entity.dart';
import '../providers/addresses_provider.dart';
import '../widgets/address_form_sheet.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(userAddressesProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Meus endereços'),
        backgroundColor: AppColors.cream,
      ),
      body: addresses.isEmpty
          ? Center(
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
                      child: Icon(PhosphorIcons.mapPin(),
                          size: 48, color: AppColors.amber600),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Nenhum endereço cadastrado',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Adicione um endereço para agilizar suas compras.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.page),
              itemCount: addresses.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _AddressCard(
                address: addresses[i],
                onSetDefault: user == null
                    ? null
                    : () => ref
                        .read(addressesProvider.notifier)
                        .setDefault(user.email, addresses[i].id),
                onDelete: user == null
                    ? null
                    : () => _confirmDelete(
                          context,
                          ref,
                          user.email,
                          addresses[i],
                        ),
              ),
            ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddressFormSheet(context, ref, user.email),
              icon: const Icon(Icons.add),
              label: const Text('Novo endereço'),
              backgroundColor: AppColors.obsidian,
              foregroundColor: AppColors.warmWhite,
            ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String email, AddressEntity a) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover endereço?'),
        content: Text('Tem certeza que quer remover "${a.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(addressesProvider.notifier).remove(email, a.id);
              Navigator.pop(context);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressEntity address;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;
  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: address.isDefault ? AppColors.amber400 : AppColors.gray100,
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.house(), size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(address.label,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.sm),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber100,
                    borderRadius: AppRadius.full,
                  ),
                  child: const Text(
                    'PADRÃO',
                    style: TextStyle(
                      color: AppColors.amber600,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(PhosphorIcons.dotsThreeVertical()),
                onSelected: (v) {
                  if (v == 'default') onSetDefault?.call();
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Definir como padrão'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remover'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(address.line1, style: theme.textTheme.bodyMedium),
          Text(address.line2, style: theme.textTheme.bodyMedium),
          Text(
            address.line3,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
