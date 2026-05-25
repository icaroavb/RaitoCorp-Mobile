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

  Future<void> markAsRead(String id) async {
    await _api.patchJson('/me/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _api.patchJson('/me/notifications/read-all');
  }

  Future<void> remove(String id) async {
    await _api.deleteJson('/me/notifications/$id');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});
