import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/notifications_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/logout_confirmation_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return _SignedOutView(theme: theme);
    }

    final activeOrder = ref.watch(activeOrderProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final ordersCount = ref.watch(userOrdersProvider).length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.cream,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('Meu perfil'),
            actions: [
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(PhosphorIcons.bell(), color: AppColors.obsidian),
                    if (unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.push('/profile/notifications'),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Identidade
                _IdentityCard(
                  name: user.name,
                  email: user.email,
                  initials: user.initials,
                  memberSince: user.memberSince,
                  isAdmin: user.isAdmin,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Pedido ativo (se houver)
                if (activeOrder != null) ...[
                  _ActiveOrderCard(order: activeOrder),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Menu
                _MenuSection(
                  items: [
                    _MenuEntry(
                      icon: PhosphorIcons.package(),
                      label: 'Meus pedidos',
                      trailing: ordersCount > 0 ? '$ordersCount' : null,
                      onTap: () => context.push('/profile/orders'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIcons.heart(),
                      label: 'Favoritos',
                      onTap: () => context.push('/profile/favorites'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIcons.star(),
                      label: 'Minhas avaliações',
                      onTap: () => context.push('/profile/reviews'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIcons.mapPin(),
                      label: 'Meus endereços',
                      onTap: () => context.push('/profile/addresses'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIcons.user(),
                      label: 'Meus dados',
                      onTap: () => context.push('/profile/my-data'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIcons.bell(),
                      label: 'Notificações',
                      trailing: unreadCount > 0 ? '$unreadCount' : null,
                      onTap: () => context.push('/profile/notifications'),
                    ),
                    _MenuEntry(
                      icon: PhosphorIcons.question(),
                      label: 'Ajuda',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Em breve — suporte 24/7.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Fidelidade
                _LoyaltyCard(points: user.loyaltyPoints),
                const SizedBox(height: AppSpacing.xxl),

                // Sair
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => showLogoutConfirmationSheet(context, ref),
                    icon: Icon(PhosphorIcons.signOut(), size: 18),
                    label: const Text('Sair da conta'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Raitõ Corp · versão 1.0.0',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray500),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  final ThemeData theme;
  const _SignedOutView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: AppColors.cream,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.amber100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.userCircle(),
                  size: 56,
                  color: AppColors.amber600,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Entre para ver seu perfil',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Acompanhe pedidos, salve favoritos e acumule pontos de fidelidade.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Entrar'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Criar conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String email;
  final String initials;
  final DateTime memberSince;
  final bool isAdmin;
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.memberSince,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.obsidian,
        borderRadius: AppRadius.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.amber400,
              borderRadius: AppRadius.full,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.obsidian,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber400,
                          borderRadius: AppRadius.sm,
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: AppColors.obsidian,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.gray300),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Membro desde ${DateFormat('MMM yyyy', 'pt_BR').format(memberSince)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.gray400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final OrderEntity order;
  const _ActiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AppRadius.md,
      onTap: () => context.push('/profile/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.amber100,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.amber400, width: 1),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.amber400,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.truck(PhosphorIconsStyle.fill),
                    color: AppColors.obsidian,
                    size: 24,
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.amber400.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      duration: 1400.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.5, 1.5),
                      curve: Curves.easeOut,
                    )
                    .fadeOut(duration: 1400.ms),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.status.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.obsidian,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pedido #${order.id}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray700),
                  ),
                  if (order.estimatedDelivery != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Previsão: ${DateFormat('dd/MM', 'pt_BR').format(order.estimatedDelivery!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.gray700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(PhosphorIcons.caretRight(),
                size: 16, color: AppColors.obsidian),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuEntry> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Divider(height: 1, color: AppColors.gray100, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _MenuEntry extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _MenuEntry({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: 18, color: AppColors.obsidian),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  trailing!,
                  style: const TextStyle(
                    color: AppColors.amber600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Icon(PhosphorIcons.caretRight(),
                size: 14, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  final int points;
  const _LoyaltyCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const nextTier = 1000;
    final progress = (points / nextTier).clamp(0.0, 1.0);
    final remaining = (nextTier - points).clamp(0, nextTier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  color: AppColors.amber400, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Raitõ Pontos',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$points pts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.gray100,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.amber400),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            remaining > 0
                ? 'Faltam $remaining pontos para o próximo nível.'
                : 'Você atingiu o nível máximo!',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
