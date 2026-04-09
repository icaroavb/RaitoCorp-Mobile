import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/mock/mock_notifications.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(List.of(mockNotifications));

  void markAsRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
  }

  void markAllAsRead(String email) {
    state = state
        .map((n) => n.userEmail == email ? n.copyWith(read: true) : n)
        .toList();
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void add(AppNotification notification) {
    state = [notification, ...state];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

/// Notificações do usuário logado, ordenadas da mais recente para a mais antiga.
final userNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final all = ref.watch(notificationsProvider);
  final mine = all.where((n) => n.userEmail == user.email).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return mine;
});

/// Contagem de notificações não lidas do usuário logado.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(userNotificationsProvider).where((n) => !n.read).length;
});

/// Notificações agrupadas por "Hoje / Ontem / Esta semana / Mais antigas".
final groupedNotificationsProvider =
    Provider<Map<String, List<AppNotification>>>((ref) {
  final list = ref.watch(userNotificationsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekStart = today.subtract(const Duration(days: 7));

  final result = <String, List<AppNotification>>{
    'Hoje': [],
    'Ontem': [],
    'Esta semana': [],
    'Mais antigas': [],
  };

  for (final n in list) {
    final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    if (d == today) {
      result['Hoje']!.add(n);
    } else if (d == yesterday) {
      result['Ontem']!.add(n);
    } else if (d.isAfter(weekStart)) {
      result['Esta semana']!.add(n);
    } else {
      result['Mais antigas']!.add(n);
    }
  }

  result.removeWhere((_, v) => v.isEmpty);
  return result;
});
