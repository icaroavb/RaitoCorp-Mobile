# Gera o app bundle de PRODUCAO.
#
# Base URL e API key de prod ja sao os defaults em lib/core/config/app_config.dart,
# entao os --dart-define abaixo sao redundantes — ficam explicitos pra deixar
# claro o ambiente do build e facilitar trocar a chave sem mexer no codigo.
#
# Uso:  .\scripts\build-prod.ps1

flutter build appbundle `
  --dart-define=N8N_BASE_URL=https://n8n.raitocorp.com.br `
  --dart-define=N8N_API_KEY=raito_81f96262486efad255c453798b769d0ce9c5eb057772f5c2 `
  --dart-define=N8N_WEBHOOK_PREFIX=/webhook
