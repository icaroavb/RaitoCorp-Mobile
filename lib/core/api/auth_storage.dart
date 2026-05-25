import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste o JWT do usuário no Keychain (iOS) / Keystore (Android) /
/// Credential Manager (Windows) / libsecret (Linux). Web cai em IndexedDB
/// criptografado pelo plugin.
///
/// NUNCA use `SharedPreferences` para tokens — fica em texto plano.
class AuthStorage {
  AuthStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'n8n_jwt';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
