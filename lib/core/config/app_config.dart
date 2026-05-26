/// Configuração de runtime do app.
///
/// Os valores reais são injetados em tempo de build via `--dart-define`:
///
/// ```
/// flutter run \
///   --dart-define=N8N_BASE_URL=https://n8n.raitocorp.com.br \
///   --dart-define=N8N_API_KEY=chave-publica-do-app
/// ```
///
/// Nada de segredo de servidor fica aqui — `N8N_API_KEY` é uma chave pública
/// embutida no app só pra rate-limit / bloquear curiosos no webhook. A
/// autenticação real do usuário é feita pelo JWT (ver `AuthStorage`). O
/// `JWT_SECRET` mora só no n8n, nunca no app.
///
/// Os defaults abaixo já apontam pra produção, então `flutter run` puro
/// funciona out-of-the-box (útil pra quem clona o repo). Pra dev/staging,
/// sobrescreva via `--dart-define` (ver `scripts/`).
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'N8N_BASE_URL',
    defaultValue: 'https://n8n.raitocorp.com.br',
  );

  static const String apiKey = String.fromEnvironment(
    'N8N_API_KEY',
    defaultValue: 'raito_81f96262486efad255c453798b769d0ce9c5eb057772f5c2',
  );

  /// Prefixo dos webhooks no n8n. Em prod normalmente é `/webhook`, em dev
  /// pode ser `/webhook-test` quando o workflow está em modo de teste.
  static const String webhookPrefix = String.fromEnvironment(
    'N8N_WEBHOOK_PREFIX',
    defaultValue: '/webhook',
  );

  /// Cloudinary — upload de imagens (produtos e fotos de avaliação). O preset
  /// é *unsigned*; nada secreto aqui (cloud name e preset são públicos por
  /// natureza, igual à API key). Ver `CloudinaryService`.
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dvt0gyhlr',
  );

  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'raitocorp-mobile',
  );

  static const Duration requestTimeout = Duration(seconds: 20);

  /// Garante que o app não suba em produção sem URL/chave configuradas.
  /// Chame em `main()` antes de `runApp()`.
  static void assertConfigured() {
    assert(
      baseUrl.isNotEmpty,
      'N8N_BASE_URL não configurado. Use --dart-define=N8N_BASE_URL=...',
    );
  }
}
