import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/entities/product_entity.dart';
import '../domain/entities/review_entity.dart';

class ProductsRepository {
  ProductsRepository(this._api);
  final ApiClient _api;

  Future<List<ProductEntity>> fetchAll() async {
    final res = await _api.getJson('/products', auth: false) as List;
    return res
        .map((e) => ProductEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // n8n: webhook com path param dinamico (:id) exige o webhookId na URL — por
  // isso detalhe e reviews usam query string. Ver docs/N8N_API.md §3.7/§3.8.
  Future<ProductEntity> fetchById(String id) async {
    final res = await _api.getJson('/products/detail',
        query: {'id': id}, auth: false) as Map<String, dynamic>;
    return ProductEntity.fromJson(res);
  }

  Future<List<ReviewEntity>> fetchReviews(String productId) async {
    final res = await _api.getJson('/products/reviews',
        query: {'id': productId}, auth: false) as List;
    return res
        .map((e) => ReviewEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(apiClientProvider));
});
