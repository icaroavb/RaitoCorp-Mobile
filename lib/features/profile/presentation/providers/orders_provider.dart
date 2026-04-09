import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/mock/mock_orders.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/order_entity.dart';

/// Lista de pedidos reativa por usuário logado.
/// Mantém uma cópia mutável em memória para permitir `addOrder` via checkout.
class OrdersNotifier extends StateNotifier<List<OrderEntity>> {
  OrdersNotifier() : super(List.of(mockOrders));

  void addOrder(OrderEntity order) {
    state = [order, ...state];
  }

  void cancelOrder(String orderId) {
    state = state
        .map((o) => o.id == orderId
            ? OrderEntity(
                id: o.id,
                userEmail: o.userEmail,
                createdAt: o.createdAt,
                status: OrderStatus.cancelled,
                items: o.items,
                address: o.address,
                subtotal: o.subtotal,
                shipping: o.shipping,
                discount: o.discount,
                paymentMethod: o.paymentMethod,
                timeline: o.timeline,
                reviewed: o.reviewed,
              )
            : o)
        .toList();
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<OrderEntity>>((ref) {
  return OrdersNotifier();
});

/// Pedidos do usuário logado.
final userOrdersProvider = Provider<List<OrderEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final all = ref.watch(ordersProvider);
  final mine = all.where((o) => o.userEmail == user.email).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return mine;
});

/// Primeiro pedido em andamento (se houver).
final activeOrderProvider = Provider<OrderEntity?>((ref) {
  final orders = ref.watch(userOrdersProvider);
  for (final o in orders) {
    if (o.status.isInProgress) return o;
  }
  return null;
});

/// Pedido único por id.
final orderByIdProvider =
    Provider.family<OrderEntity?, String>((ref, id) {
  final all = ref.watch(ordersProvider);
  for (final o in all) {
    if (o.id == id) return o;
  }
  return null;
});
