import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';

class FavoritesRepository {
  FavoritesRepository(this._api);
  final ApiClient _api;

  Future<Set<String>> fetchMine() async {
    final res = await _api.getJson('/me/favorites') as List;
    return res.map((e) => e.toString()).toSet();
  }

  /// Idempotente: o webhook deve aceitar toggle ou criar/remover.
  /// Retorna o novo estado (`true` = favoritado).
  Future<bool> toggle(String productId) async {
    final res = await _api.postJson(
      '/me/favorites/toggle',
      body: {'product_id': productId},
    ) as Map<String, dynamic>;
    return res['favorited'] as bool;
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(apiClientProvider));
});
