import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/mock/mock_users.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/address_entity.dart';

/// Armazena endereços por e-mail (em memória durante a sessão).
class AddressesNotifier
    extends StateNotifier<Map<String, List<AddressEntity>>> {
  AddressesNotifier()
      : super({
          for (final c in mockCredentials) c.user.email: List.of(c.addresses),
        });

  void add(String email, AddressEntity address) {
    final current = List<AddressEntity>.of(state[email] ?? const []);
    // Se for o primeiro endereço, marca como padrão
    final addr = current.isEmpty
        ? AddressEntity(
            id: address.id,
            label: address.label,
            street: address.street,
            number: address.number,
            complement: address.complement,
            neighborhood: address.neighborhood,
            city: address.city,
            state: address.state,
            zipCode: address.zipCode,
            isDefault: true,
          )
        : address;
    current.add(addr);
    state = {...state, email: current};
  }

  void remove(String email, String addressId) {
    final current = List<AddressEntity>.of(state[email] ?? const [])
      ..removeWhere((a) => a.id == addressId);
    // Se removeu o padrão, promove o primeiro da lista
    if (!current.any((a) => a.isDefault) && current.isNotEmpty) {
      current[0] = current[0].copyWith(isDefault: true);
    }
    state = {...state, email: current};
  }

  void setDefault(String email, String addressId) {
    final current = (state[email] ?? const <AddressEntity>[])
        .map((a) => a.copyWith(isDefault: a.id == addressId))
        .toList();
    state = {...state, email: current};
  }
}

final addressesProvider =
    StateNotifierProvider<AddressesNotifier, Map<String, List<AddressEntity>>>(
  (ref) => AddressesNotifier(),
);

final userAddressesProvider = Provider<List<AddressEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(addressesProvider)[user.email] ?? const [];
});

final defaultAddressProvider = Provider<AddressEntity?>((ref) {
  final list = ref.watch(userAddressesProvider);
  for (final a in list) {
    if (a.isDefault) return a;
  }
  return list.isNotEmpty ? list.first : null;
});
