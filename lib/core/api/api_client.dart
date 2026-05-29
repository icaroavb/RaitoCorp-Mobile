import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'auth_storage.dart';

typedef JsonMap = Map<String, dynamic>;

/// Cliente HTTP único pra falar com o n8n.
///
/// Centraliza headers (X-API-Key + Bearer JWT), timeout, parse de JSON e
/// tradução de status code → `ApiException` tipada. Os repositórios só
/// chamam `getJson` / `postJson` / `patchJson` / `deleteJson` e recebem
/// `Map`/`List` prontos.
class ApiClient {
  ApiClient({http.Client? httpClient, AuthStorage? authStorage})
      : _http = httpClient ?? http.Client(),
        _auth = authStorage ?? AuthStorage();

  final http.Client _http;
  final AuthStorage _auth;

  /// Callback chamado em 401 — o `AuthNotifier` registra pra deslogar
  /// quando o token expira.
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(AppConfig.baseUrl);
    final fullPath = '${AppConfig.webhookPrefix}$path';
    return base.replace(
      path: base.path.isEmpty
          ? fullPath
          : '${base.path.replaceAll(RegExp(r'/$'), '')}$fullPath',
      queryParameters: query?.map((k, v) => MapEntry(k, v?.toString())),
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey,
    };
    if (auth) {
      final token = await _auth.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    return _send(() async {
      return _http
          .get(_uri(path, query), headers: await _headers(auth: auth))
          .timeout(AppConfig.requestTimeout);
    });
  }

  /// `timeout` sobrescreve o padrão para chamadas lentas (ex.: o preview do
  /// consultor gera imagem no ModelScope e leva 1-2 min — ver `ConsultantRepository`).
  Future<dynamic> postJson(
    String path, {
    Object? body,
    bool auth = true,
    Duration? timeout,
  }) async {
    return _send(() async {
      return _http
          .post(
            _uri(path),
            headers: await _headers(auth: auth),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout ?? AppConfig.requestTimeout);
    });
  }

  Future<dynamic> patchJson(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    return _send(() async {
      return _http
          .patch(
            _uri(path),
            headers: await _headers(auth: auth),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout);
    });
  }

  Future<dynamic> deleteJson(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    return _send(() async {
      final req = http.Request('DELETE', _uri(path))
        ..headers.addAll(await _headers(auth: auth));
      if (body != null) req.body = jsonEncode(body);
      final streamed =
          await _http.send(req).timeout(AppConfig.requestTimeout);
      return http.Response.fromStream(streamed);
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request();
    } on TimeoutException {
      throw const NetworkException('Tempo de resposta excedido.');
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }
    return _parse(res);
  }

  dynamic _parse(http.Response res) {
    final status = res.statusCode;
    final body = res.body.isEmpty ? null : _tryDecode(res.body);

    if (status >= 200 && status < 300) return body;

    final msg = _extractMessage(body) ?? 'Erro ${res.statusCode}';

    switch (status) {
      case 401:
        onUnauthorized?.call();
        throw UnauthorizedException(msg);
      case 403:
        throw ForbiddenException(msg);
      case 404:
        throw NotFoundException(msg);
      case 400:
      case 422:
        throw ValidationException(msg, _extractFieldErrors(body));
      default:
        throw ServerException(status, msg);
    }
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String? _extractMessage(dynamic body) {
    if (body is Map) {
      return (body['message'] ?? body['error'] ?? body['detail'])?.toString();
    }
    return null;
  }

  Map<String, String> _extractFieldErrors(dynamic body) {
    if (body is Map && body['errors'] is Map) {
      return (body['errors'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    return const {};
  }

  void close() => _http.close();
}
