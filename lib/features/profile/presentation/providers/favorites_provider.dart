import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/favorites_repository.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._repo, this._isLoggedIn) : super(const {}) {
    if (_isLoggedIn) refresh();
  }

  final FavoritesRepository _repo;
  final bool _isLoggedIn;

  Future<void> refresh() async {
    try {
      state = await _repo.fetchMine();
    } catch (_) {}
  }

  /// `email` ignorado — o backend identifica via JWT. Mantém assinatura
  /// compatível com as telas existentes.
  Future<void> toggle(String email, String productId) async {
    // Otimista: aplica local e desfaz se falhar.
    final wasFav = state.contains(productId);
    state = wasFav
        ? (Set<String>.from(state)..remove(productId))
        : (Set<String>.from(state)..add(productId));
    try {
      await _repo.toggle(productId);
    } catch (_) {
      state = wasFav
          ? (Set<String>.from(state)..add(productId))
          : (Set<String>.from(state)..remove(productId));
    }
  }

  bool isFavorite(String email, String productId) =>
      state.contains(productId);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(
    ref.watch(favoritesRepositoryProvider),
    ref.watch(isLoggedInProvider),
  );
});

final userFavoriteIdsProvider = Provider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const {};
  return ref.watch(favoritesProvider);
});

final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(userFavoriteIdsProvider).contains(productId);
});
