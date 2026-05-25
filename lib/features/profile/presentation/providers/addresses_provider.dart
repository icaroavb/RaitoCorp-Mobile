import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/addresses_repository.dart';
import '../../domain/entities/address_entity.dart';

class AddressesNotifier extends StateNotifier<List<AddressEntity>> {
  AddressesNotifier(this._repo, this._isLoggedIn) : super(const []) {
    if (_isLoggedIn) refresh();
  }

  final AddressesRepository _repo;
  final bool _isLoggedIn;

  Future<void> refresh() async {
    try {
      state = await _repo.fetchMine();
    } catch (_) {}
  }

  /// Mantém assinatura compatível com as telas (que ainda passam email).
  /// O `email` é ignorado: o backend já sabe quem é o usuário pelo JWT.
  Future<void> add(String email, AddressEntity address) async {
    final created = await _repo.create(address);
    state = [...state, created];
  }

  Future<void> remove(String email, String addressId) async {
    await _repo.remove(addressId);
    state = state.where((a) => a.id != addressId).toList();
  }

  Future<void> setDefault(String email, String addressId) async {
    await _repo.setDefault(addressId);
    state = state
        .map((a) => a.copyWith(isDefault: a.id == addressId))
        .toList();
  }
}

final addressesProvider =
    StateNotifierProvider<AddressesNotifier, List<AddressEntity>>((ref) {
  return AddressesNotifier(
    ref.watch(addressesRepositoryProvider),
    ref.watch(isLoggedInProvider),
  );
});

final userAddressesProvider = Provider<List<AddressEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(addressesProvider);
});

final defaultAddressProvider = Provider<AddressEntity?>((ref) {
  final list = ref.watch(userAddressesProvider);
  for (final a in list) {
    if (a.isDefault) return a;
  }
  return list.isNotEmpty ? list.first : null;
});
