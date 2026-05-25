/// Erros tipados da camada de rede.
///
/// As telas devem capturar `ApiException` (ou subtipos) e nunca
/// `http.ClientException` direto, pra manter a apresentação desacoplada.
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Sem conexão / timeout / DNS — tipicamente recuperável tentando de novo.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Sem conexão. Tente novamente.']);
}

/// 401 — token expirado ou inválido. O `AuthNotifier` deve deslogar.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Sessão expirada.']);
}

/// 403 — autenticado mas sem permissão pro recurso.
class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Acesso negado.']);
}

/// 404 — recurso não existe.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Não encontrado.']);
}

/// 422 / 400 com payload de validação do n8n.
class ValidationException extends ApiException {
  final Map<String, String> fieldErrors;
  const ValidationException(super.message, [this.fieldErrors = const {}]);
}

/// 5xx — erro do servidor / workflow do n8n.
class ServerException extends ApiException {
  final int statusCode;
  const ServerException(this.statusCode, [super.message = 'Erro no servidor.']);
}
