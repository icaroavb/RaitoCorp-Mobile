import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/local_notifications.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/orders_repository.dart';
import '../../domain/entities/order_entity.dart';

/// Notifier que mantém em memória a lista de pedidos do usuário logado.
/// Faz fetch inicial automático ao logar e expõe ações que sincronizam com
/// o backend (n8n) antes de atualizar o estado local.
class OrdersNotifier extends StateNotifier<List<OrderEntity>> {
  OrdersNotifier(this._repo, this._isLoggedIn) : super(const []) {
    if (_isLoggedIn) refresh();
  }

  final OrdersRepository _repo;
  final bool _isLoggedIn;

  Future<void> refresh() async {
    try {
      final previous = {for (final o in state) o.id: o.status};
      final fresh = await _repo.fetchMine();
      // Detecta pedidos que avançaram pra shipped/delivered desde o último
      // estado conhecido e dispara uma notificação local com mensagem legal.
      for (final o in fresh) {
        final before = previous[o.id];
        if (before != null && before != o.status) {
          final msg = _statusMessage(o.status);
          if (msg != null) {
            LocalNotifications.instance.show(
              id: o.id.hashCode,
              title: msg.$1,
              body: 'Pedido #${o.id} — ${msg.$2}',
            );
          }
        }
      }
      state = fresh;
    } catch (_) {
      // Mantém o último estado conhecido em caso de falha de rede.
    }
  }

  /// (título, corpo) da notificação por status — só pra transições que
  /// merecem aviso. Retorna null pros demais.
  (String, String)? _statusMessage(OrderStatus s) => switch (s) {
        OrderStatus.shipped => (
            '🚚 Seu pedido saiu para entrega!',
            'Já está a caminho — prepare o ambiente pra nova iluminação ✨'
          ),
        OrderStatus.delivered => (
            '📦 Pedido entregue!',
            'Chegou! Aproveite e conte pra gente o que achou ⭐'
          ),
        _ => null,
      };

  /// Adiciona localmente um pedido já criado no backend (vindo do checkout).
  void addOrder(OrderEntity order) {
    state = [order, ...state];
  }

  Future<void> cancelOrder(String orderId) async {
    final updated = await _repo.cancel(orderId);
    state = [
      for (final o in state)
        if (o.id == orderId) updated else o,
    ];
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<OrderEntity>>((ref) {
  return OrdersNotifier(
    ref.watch(ordersRepositoryProvider),
    ref.watch(isLoggedInProvider),
  );
});

final userOrdersProvider = Provider<List<OrderEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final all = ref.watch(ordersProvider);
  final mine = all.where((o) => o.userEmail == user.email).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return mine;
});

final activeOrderProvider = Provider<OrderEntity?>((ref) {
  final orders = ref.watch(userOrdersProvider);
  for (final o in orders) {
    if (o.status.isInProgress) return o;
  }
  return null;
});

final orderByIdProvider =
    Provider.family<OrderEntity?, String>((ref, id) {
  final all = ref.watch(ordersProvider);
  for (final o in all) {
    if (o.id == id) return o;
  }
  return null;
});
