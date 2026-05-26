import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../products/domain/entities/product_entity.dart';
import '../../profile/domain/entities/order_entity.dart';

/// Ações exclusivas de admin (validadas por `is_admin` no backend).
class AdminRepository {
  AdminRepository(this._api);
  final ApiClient _api;

  /// Lista TODOS os pedidos (admin vê de todos os clientes).
  Future<List<OrderEntity>> fetchAllOrders() async {
    final res = await _api.getJson('/admin/orders') as List;
    return res
        .map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Avança o pedido pra próxima etapa (confirmed→preparing→shipped→delivered).
  Future<OrderEntity> advanceOrder(String orderId) async {
    final res = await _api.postJson('/admin/orders/advance', body: {'id': orderId})
        as Map<String, dynamic>;
    return OrderEntity.fromJson(res);
  }

  /// Cria um produto novo. `product` é o `ProductEntity.toJson()` sem `id`.
  Future<ProductEntity> createProduct(Map<String, dynamic> product) async {
    final res = await _api.postJson('/admin/products', body: {'product': product})
        as Map<String, dynamic>;
    return ProductEntity.fromJson(res);
  }

  /// Edita um produto. `product` deve conter `id` + os campos a alterar
  /// (update parcial: campos ausentes mantêm o valor atual).
  Future<ProductEntity> updateProduct(Map<String, dynamic> product) async {
    final res =
        await _api.postJson('/admin/products/update', body: {'product': product})
            as Map<String, dynamic>;
    return ProductEntity.fromJson(res);
  }

  /// Soft-delete (active=false): some do catálogo, preserva pedidos antigos.
  Future<void> deleteProduct(String id) async {
    await _api.postJson('/admin/products/delete', body: {'id': id});
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});
