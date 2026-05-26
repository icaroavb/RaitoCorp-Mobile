import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/data/products_repository.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../profile/domain/entities/order_entity.dart';
import '../../data/admin_repository.dart';

/// Lista de TODOS os pedidos (visão admin). Recarrega sob demanda.
class AdminOrdersNotifier extends StateNotifier<AsyncValue<List<OrderEntity>>> {
  AdminOrdersNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }

  final AdminRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.fetchAllOrders());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Avança um pedido e atualiza a lista no lugar.
  Future<void> advance(String orderId) async {
    final updated = await _repo.advanceOrder(orderId);
    final current = state.valueOrNull ?? const [];
    state = AsyncValue.data([
      for (final o in current)
        if (o.id == orderId) updated else o,
    ]);
  }

  Future<ProductEntity> createProduct(Map<String, dynamic> product) {
    return _repo.createProduct(product);
  }
}

final adminOrdersProvider = StateNotifierProvider<AdminOrdersNotifier,
    AsyncValue<List<OrderEntity>>>((ref) {
  return AdminOrdersNotifier(ref.watch(adminRepositoryProvider));
});

/// Catálogo na visão admin (reusa o GET /products público) + ações de escrita.
/// Após criar/editar/excluir, invalida `allProductsProvider` pra o catálogo
/// do app refletir a mudança.
class AdminProductsNotifier extends StateNotifier<AsyncValue<List<ProductEntity>>> {
  AdminProductsNotifier(this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  final Ref _ref;
  AdminRepository get _repo => _ref.read(adminRepositoryProvider);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(
          await _ref.read(productsRepositoryProvider).fetchAll());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(Map<String, dynamic> product) async {
    await _repo.createProduct(product);
    _ref.invalidate(allProductsProvider);
    await refresh();
  }

  Future<void> update(Map<String, dynamic> product) async {
    await _repo.updateProduct(product);
    _ref.invalidate(allProductsProvider);
    await refresh();
  }

  Future<void> remove(String id) async {
    await _repo.deleteProduct(id);
    _ref.invalidate(allProductsProvider);
    await refresh();
  }
}

final adminProductsProvider = StateNotifierProvider<AdminProductsNotifier,
    AsyncValue<List<ProductEntity>>>((ref) {
  return AdminProductsNotifier(ref);
});
