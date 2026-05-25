# Roda o app contra um n8n LOCAL em modo de teste.
# Workflows precisam estar em "listen" no editor pro /webhook-test responder.
#
# Uso:  .\scripts\run-dev.ps1
# (10.0.2.2 = host da maquina visto de dentro do emulador Android)

flutter run `
  --dart-define=N8N_BASE_URL=http://10.0.2.2:5678 `
  --dart-define=N8N_API_KEY=dev-key `
  --dart-define=N8N_WEBHOOK_PREFIX=/webhook-test
