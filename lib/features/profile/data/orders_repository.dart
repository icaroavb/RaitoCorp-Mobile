import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../cart/domain/entities/cart_item_entity.dart';
import '../domain/entities/address_entity.dart';
import '../domain/entities/order_entity.dart';

class OrdersRepository {
  OrdersRepository(this._api);
  final ApiClient _api;

  Future<List<OrderEntity>> fetchMine() async {
    final res = await _api.getJson('/me/orders') as List;
    return res
        .map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderEntity> create({
    required List<CartItemEntity> items,
    required AddressEntity address,
    required String paymentMethod,
    required double subtotal,
    required double shipping,
    required double discount,
  }) async {
    final res = await _api.postJson('/me/orders', body: {
      'items': items
          .map((i) => {
                'product_id': i.productId,
                'product_name': i.productName,
                'image_url': i.imageUrl,
                'subtitle': i.subtitle,
                'price': i.price,
                'quantity': i.quantity,
              })
          .toList(),
      'address_id': address.id,
      'payment_method': paymentMethod,
      'subtotal': subtotal,
      'shipping': shipping,
      'discount': discount,
    }) as Map<String, dynamic>;
    return OrderEntity.fromJson(res);
  }

  // n8n: path param :id exige webhookId na URL — por isso cancel é POST + id no
  // body em path estático. Ver docs/N8N_API.md §3.11.
  Future<OrderEntity> cancel(String orderId) async {
    final res = await _api.postJson('/me/orders/cancel', body: {'id': orderId})
        as Map<String, dynamic>;
    return OrderEntity.fromJson(res);
  }

  /// Avalia um pedido entregue. `photoUrl` opcional (já no Cloudinary).
  /// Ver docs/N8N_API.md §3.11b.
  Future<void> review({
    required String orderId,
    required int rating,
    required String comment,
    String? photoUrl,
  }) async {
    await _api.postJson('/me/orders/review', body: {
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
      if (photoUrl != null) 'photo_url': photoUrl,
    });
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});
