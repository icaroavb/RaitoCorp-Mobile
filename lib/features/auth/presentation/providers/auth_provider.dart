import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/mock/mock_users.dart';
import '../../../profile/domain/entities/user_entity.dart';

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
  AuthNotifier() : super(const AuthLoading()) {
    _load();
  }

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId:
        '250510478199-ntvbpl5sffki90u4k0lk3eseal8u8t0m.apps.googleusercontent.com',
  );

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('auth_email');
    if (email != null) {
      final cred = findCredentialByEmail(email);
      if (cred != null) {
        state = Authenticated(cred.user);
        return;
      }
    }
    state = const Unauthenticated();
  }

  /// Retorna true em caso de sucesso.
  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    await Future.delayed(const Duration(milliseconds: 500));
    final cred = findCredential(email.trim(), password);
    if (cred == null) {
      state = const Unauthenticated(
        'E-mail ou senha incorretos. Verifique e tente novamente.',
      );
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', cred.user.email);
    state = Authenticated(cred.user);
    return true;
  }

  /// Login via Google. Retorna true em caso de sucesso.
  Future<bool> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = const Unauthenticated();
        return false;
      }

      String email = account.email;
      String? displayName = account.displayName;

      // Na web, o plugin token-flow pode retornar email/displayName vazios.
      // Buscamos os dados via People API usando o access token.
      if (kIsWeb && (email.isEmpty)) {
        final auth = await account.authentication;
        final accessToken = auth.accessToken;
        if (accessToken != null) {
          final res = await http.get(
            Uri.parse(
              'https://people.googleapis.com/v1/people/me'
              '?personFields=names,emailAddresses',
            ),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            final emails = data['emailAddresses'] as List<dynamic>?;
            final names = data['names'] as List<dynamic>?;
            if (emails != null && emails.isNotEmpty) {
              email = (emails.first as Map)['value'] as String? ?? email;
            }
            if (names != null && names.isNotEmpty) {
              displayName =
                  (names.first as Map)['displayName'] as String? ?? displayName;
            }
          }
        }
      }

      if (email.isEmpty) {
        state = const Unauthenticated(
          'Não foi possível obter o e-mail da conta Google.',
        );
        return false;
      }

      var cred = findCredentialByEmail(email);
      if (cred == null) {
        final name = displayName ?? email.split('@').first;
        final user = UserEntity(
          email: email,
          name: name,
          initials: _initials(name),
          isAdmin: email.toLowerCase().contains('admin'),
          memberSince: DateTime.now(),
          loyaltyPoints: 100,
        );
        mockCredentials.add(MockCredential(
          user: user,
          password: '',
          addresses: const [],
          favoriteProductIds: const {},
        ));
        cred = mockCredentials.last;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_email', cred.user.email);
      state = Authenticated(cred.user);
      return true;
    } catch (_) {
      state = const Unauthenticated(
        'Não foi possível entrar com Google. Verifique as configurações.',
      );
      return false;
    }
  }

  /// Cadastro cria um usuário em memória (não persistido entre sessões porque
  /// a lista mockCredentials é const, mas o login funciona enquanto o app vive).
  Future<bool> register(String name, String email, String password) async {
    state = const AuthLoading();
    await Future.delayed(const Duration(milliseconds: 500));
    // Verifica se já existe
    if (findCredentialByEmail(email) != null) {
      state = const Unauthenticated(
        'Este e-mail já está cadastrado. Tente fazer login.',
      );
      return false;
    }
    final user = UserEntity(
      email: email,
      name: name.isNotEmpty ? name : email.split('@').first,
      initials: _initials(name.isNotEmpty ? name : email.split('@').first),
      isAdmin: email.toLowerCase().contains('admin'),
      memberSince: DateTime.now(),
      loyaltyPoints: 100,
    );
    mockCredentials.add(
      MockCredential(
        user: user,
        password: password,
        addresses: const [],
        favoriteProductIds: const {},
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', email);
    state = Authenticated(user);
    return true;
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_email');
    state = const Unauthenticated();
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final current = state;
    if (current is! Authenticated) return;
    final updated = current.user.copyWith(name: name, phone: phone);
    state = Authenticated(updated);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  final state = ref.watch(authProvider);
  return state is Authenticated ? state.user : null;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is Authenticated;
});
