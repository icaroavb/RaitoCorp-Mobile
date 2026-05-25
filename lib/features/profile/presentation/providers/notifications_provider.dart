import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/notifications_repository.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier(this._repo, this._isLoggedIn) : super(const []) {
    if (_isLoggedIn) refresh();
  }

  final NotificationsRepository _repo;
  final bool _isLoggedIn;

  Future<void> refresh() async {
    try {
      state = await _repo.fetchMine();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    state = state
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
    try {
      await _repo.markAsRead(id);
    } catch (_) {}
  }

  /// `email` ignorado — backend usa JWT.
  Future<void> markAllAsRead([String? email]) async {
    state = state.map((n) => n.copyWith(read: true)).toList();
    try {
      await _repo.markAllAsRead();
    } catch (_) {}
  }

  Future<void> remove(String id) async {
    final previous = state;
    state = state.where((n) => n.id != id).toList();
    try {
      await _repo.remove(id);
    } catch (_) {
      state = previous;
    }
  }

  void add(AppNotification notification) {
    state = [notification, ...state];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier(
    ref.watch(notificationsRepositoryProvider),
    ref.watch(isLoggedInProvider),
  );
});

final userNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final all = ref.watch(notificationsProvider);
  final mine = all.where((n) => n.userEmail == user.email).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return mine;
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(userNotificationsProvider).where((n) => !n.read).length;
});

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
