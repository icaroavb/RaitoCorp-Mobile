import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_providers.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../data/auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Unauthenticated extends AuthState {
  final String? errorMessage;
  const Unauthenticated([this.errorMessage]);
}

class Authenticated extends AuthState {
  final UserEntity user;
  const Authenticated(this.user);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._api) : super(const AuthLoading()) {
    _api.onUnauthorized = _onUnauthorized;
    _load();
  }

  final AuthRepository _repo;
  final dynamic _api; // ApiClient — guardado só pra registrar callback

  // No Android o clientId NÃO deve ser passado: o plugin lê o OAuth client
  // (tipo Android, SHA-1) do google-services.json. Passar o client web aqui faz
  // o signIn() devolver idToken nulo / falhar. No Web o clientId é obrigatório
  // (não há google-services.json), e o serverClientId garante que o idToken
  // venha com a audience do client web, que é o que o backend valida.
  static const _webClientId =
      '250510478199-ntvbpl5sffki90u4k0lk3eseal8u8t0m.apps.googleusercontent.com';

  final _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
  );

  Future<void> _load() async {
    try {
      final user = await _repo.currentUser();
      state = user == null ? const Unauthenticated() : Authenticated(user);
    } on UnauthorizedException {
      await _repo.logout();
      state = const Unauthenticated();
    } on ApiException {
      state = const Unauthenticated();
    }
  }

  void _onUnauthorized() {
    if (state is Authenticated) {
      _repo.logout();
      state = const Unauthenticated('Sua sessão expirou. Entre novamente.');
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final session = await _repo.login(email, password);
      state = Authenticated(session.user);
      return true;
    } on UnauthorizedException {
      state = const Unauthenticated(
        'E-mail ou senha incorretos. Verifique e tente novamente.',
      );
      return false;
    } on ApiException catch (e) {
      state = Unauthenticated(e.message);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = const Unauthenticated();
        return false;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        // Fallback web: tenta puxar email via People API só pra mostrar erro útil.
        if (kIsWeb) {
          await _debugFetchProfile(auth.accessToken);
        }
        state = const Unauthenticated(
          'Não foi possível obter o token Google. Tente novamente.',
        );
        return false;
      }

      final session = await _repo.loginWithGoogle(idToken);
      state = Authenticated(session.user);
      return true;
    } on ApiException catch (e) {
      state = Unauthenticated(e.message);
      return false;
    } catch (_) {
      state = const Unauthenticated(
        'Não foi possível entrar com Google. Verifique as configurações.',
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AuthLoading();
    try {
      final session = await _repo.register(
        name: name,
        email: email,
        password: password,
      );
      state = Authenticated(session.user);
      return true;
    } on ValidationException catch (e) {
      state = Unauthenticated(e.message);
      return false;
    } on ApiException catch (e) {
      state = Unauthenticated(e.message);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _repo.logout();
    state = const Unauthenticated();
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final current = state;
    if (current is! Authenticated) return;
    try {
      await _repo.updateProfile(name: name, phone: phone);
      state = Authenticated(current.user.copyWith(name: name, phone: phone));
    } on ApiException {
      // Mantém o estado atual; UI pode exibir snackbar lendo via try/catch.
      rethrow;
    }
  }

  /// Só pra logging — não afeta o fluxo.
  Future<void> _debugFetchProfile(String? accessToken) async {
    if (accessToken == null) return;
    try {
      final res = await http.get(
        Uri.parse(
          'https://people.googleapis.com/v1/people/me'
          '?personFields=names,emailAddresses',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (res.statusCode == 200) {
        jsonDecode(res.body);
      }
    } catch (_) {}
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  final state = ref.watch(authProvider);
  return state is Authenticated ? state.user : null;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is Authenticated;
});
