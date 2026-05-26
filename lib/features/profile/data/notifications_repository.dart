import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/entities/notification_entity.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<List<AppNotification>> fetchMine() async {
    final res = await _api.getJson('/me/notifications') as List;
    return res
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // n8n: path param :id exige webhookId na URL — por isso read/delete são POST +
  // id no body em path estático. Ver docs/N8N_API.md §3.19-3.21.
  Future<void> markAsRead(String id) async {
    await _api.postJson('/me/notifications/read', body: {'id': id});
  }

  Future<void> markAllAsRead() async {
    await _api.postJson('/me/notifications/read-all');
  }

  Future<void> remove(String id) async {
    await _api.postJson('/me/notifications/delete', body: {'id': id});
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});
