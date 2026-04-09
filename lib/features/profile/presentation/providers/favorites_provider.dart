import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/mock/mock_users.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Mapeia email → set de product IDs favoritos.
class FavoritesNotifier extends StateNotifier<Map<String, Set<String>>> {
  FavoritesNotifier()
      : super({
          for (final c in mockCredentials)
            c.user.email: Set.of(c.favoriteProductIds),
        });

  void toggle(String email, String productId) {
    final current = Set<String>.of(state[email] ?? const <String>{});
    if (current.contains(productId)) {
      current.remove(productId);
    } else {
      current.add(productId);
    }
    state = {...state, email: current};
  }

  bool isFavorite(String email, String productId) {
    return (state[email] ?? const <String>{}).contains(productId);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Map<String, Set<String>>>(
  (ref) => FavoritesNotifier(),
);

final userFavoriteIdsProvider = Provider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const {};
  return ref.watch(favoritesProvider)[user.email] ?? const {};
});

final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(userFavoriteIdsProvider).contains(productId);
});
