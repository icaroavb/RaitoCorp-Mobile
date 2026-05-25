import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/entities/address_entity.dart';

class AddressesRepository {
  AddressesRepository(this._api);
  final ApiClient _api;

  Future<List<AddressEntity>> fetchMine() async {
    final res = await _api.getJson('/me/addresses') as List;
    return res
        .map((e) => AddressEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddressEntity> create(AddressEntity address) async {
    final body = address.toJson()..remove('id');
    final res =
        await _api.postJson('/me/addresses', body: body) as Map<String, dynamic>;
    return AddressEntity.fromJson(res);
  }

  // n8n: webhook com path param dinamico (:id) exige o webhookId na URL, o que
  // o app nao tem como montar. Por isso delete/default sao POST com id no body
  // e path estatico. Ver docs/N8N_API.md §3.14/§3.15.
  Future<void> remove(String id) async {
    await _api.postJson('/me/addresses/delete', body: {'id': id});
  }

  Future<void> setDefault(String id) async {
    await _api.postJson('/me/addresses/default', body: {'id': id});
  }
}

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return AddressesRepository(ref.watch(apiClientProvider));
});
