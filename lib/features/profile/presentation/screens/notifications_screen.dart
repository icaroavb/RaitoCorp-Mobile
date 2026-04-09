import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(groupedNotificationsProvider);
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: AppColors.cream,
        actions: [
          if (unread > 0 && user != null)
            TextButton(
              onPressed: () => ref
                  .read(notificationsProvider.notifier)
                  .markAllAsRead(user.email),
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: grouped.isEmpty
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
                      child: Icon(PhosphorIcons.bell(),
                          size: 48, color: AppColors.amber600),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Tudo em dia!', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Nenhuma notificação no momento.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      bottom: AppSpacing.sm,
                      top: AppSpacing.sm,
                    ),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  for (final n in entry.value)
                    Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: AppRadius.md,
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) =>
                          ref.read(notificationsProvider.notifier).remove(n.id),
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _NotificationTile(
                          notification: n,
                          onTap: () => ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(n.id),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.read
              ? AppColors.warmWhite
              : AppColors.amber100.withValues(alpha: 0.5),
          borderRadius: AppRadius.md,
          border: Border.all(
            color: notification.read ? AppColors.gray100 : AppColors.amber200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _bgColor(notification.type),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(
                _icon(notification.type),
                color: _fgColor(notification.type),
                size: 20,
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
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: notification.read
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.amber400,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM · HH:mm', 'pt_BR')
                        .format(notification.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray400, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(AppNotificationType t) => switch (t) {
        AppNotificationType.order => PhosphorIcons.package(),
        AppNotificationType.review => PhosphorIcons.star(),
        AppNotificationType.promotion => PhosphorIcons.tag(),
        AppNotificationType.system => PhosphorIcons.info(),
      };

  Color _bgColor(AppNotificationType t) => switch (t) {
        AppNotificationType.order => AppColors.amber100,
        AppNotificationType.review => const Color(0xFFFEF3C7),
        AppNotificationType.promotion => const Color(0xFFFCE7F3),
        AppNotificationType.system => AppColors.gray100,
      };

  Color _fgColor(AppNotificationType t) => switch (t) {
        AppNotificationType.order => AppColors.amber600,
        AppNotificationType.review => AppColors.warning,
        AppNotificationType.promotion => const Color(0xFFBE185D),
        AppNotificationType.system => AppColors.gray700,
      };
}
