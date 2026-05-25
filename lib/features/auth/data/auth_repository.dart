import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/auth_storage.dart';
import '../../profile/domain/entities/user_entity.dart';

/// Resultado de uma autenticação bem-sucedida.
class AuthSession {
  final String token;
  final UserEntity user;
  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: json['token'] as String,
        user: UserEntity.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class AuthRepository {
  AuthRepository(this._api, this._storage);
  final ApiClient _api;
  final AuthStorage _storage;

  Future<AuthSession> login(String email, String password) async {
    final res = await _api.postJson(
      '/auth/login',
      auth: false,
      body: {'email': email.trim(), 'password': password},
    ) as Map<String, dynamic>;
    final session = AuthSession.fromJson(res);
    await _storage.saveToken(session.token);
    return session;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.postJson(
      '/auth/register',
      auth: false,
      body: {'name': name, 'email': email.trim(), 'password': password},
    ) as Map<String, dynamic>;
    final session = AuthSession.fromJson(res);
    await _storage.saveToken(session.token);
    return session;
  }

  /// Troca o `id_token` do Google por uma sessão Raitõ. O n8n valida o
  /// id_token no endpoint da Google e cria/atualiza o usuário.
  Future<AuthSession> loginWithGoogle(String idToken) async {
    final res = await _api.postJson(
      '/auth/google',
      auth: false,
      body: {'id_token': idToken},
    ) as Map<String, dynamic>;
    final session = AuthSession.fromJson(res);
    await _storage.saveToken(session.token);
    return session;
  }

  /// Reidrata a sessão usando o token salvo. Retorna `null` se não há token
  /// ou se o backend rejeitou (401 → AuthNotifier limpa estado).
  Future<UserEntity?> currentUser() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    final res = await _api.getJson('/me') as Map<String, dynamic>;
    return UserEntity.fromJson(res);
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    await _api.patchJson('/me', body: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(authStorageProvider),
  );
});
