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

  Future<ProductEntity> fetchById(String id) async {
    final res = await _api.getJson('/products/$id', auth: false) as Map<String, dynamic>;
    return ProductEntity.fromJson(res);
  }

  Future<List<ReviewEntity>> fetchReviews(String productId) async {
    final res = await _api.getJson('/products/$productId/reviews', auth: false)
        as List;
    return res
        .map((e) => ReviewEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(apiClientProvider));
});
