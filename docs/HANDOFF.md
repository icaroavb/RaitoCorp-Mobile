# HANDOFF — Estado do projeto (atualizado 2026-05-29)

> Documento de retomada. Leia isto primeiro ao continuar o trabalho.
> Contrato completo dos endpoints em [`N8N_API.md`](./N8N_API.md).
> Visão de arquitetura para a apresentação em [`ARQUITETURA.md`](./ARQUITETURA.md).

## Contexto geral

App Flutter (Raitõ — loja de iluminação), TCC. Backend **100% em n8n + Postgres**
— o app nunca fala direto com o banco, só via webhooks (`https://n8n.raitocorp.com.br/webhook/...`).
n8n roda na máquina de um colega via Cloudflare, acessível por **MCP** (sem
acesso ao host nem ao Postgres direto).

Arquitetura do app: feature-first (`lib/features/<feature>/{data,domain,presentation}`),
Riverpod pra estado, go_router pra navegação, `ApiClient` central
(`lib/core/api/`) injetando X-API-Key + Bearer JWT. Defaults de produção em
`app_config.dart` → `flutter run` puro já funciona, sem `--dart-define`.

## Credenciais / configs

| O quê | Valor |
|---|---|
| Cliente teste | `teste@raito.com` / `teste1234` |
| **Admin** | `admin@raito.com` / `admin1234` (is_admin=true) |
| APP_API_KEY (X-API-Key, pública) | `raito_81f96262486efad255c453798b769d0ce9c5eb057772f5c2` |
| JWT_SECRET (HS256, só no servidor) | `bj6VFq3FcdWYVl4Mv-3_fDSbGesnSfjHdVOq8VoFqfshrZo0W7x3tZPHTztc-3sl` |
| Cloudinary | cloud `dvt0gyhlr` · unsigned preset `raitocorp-mobile` |
| ModelScope (Consultor IA) | token `ms-ca592d9a-...` hardcoded nos workflows do consultor |

## Restrições da instância n8n (hardened) — regras que moldam tudo

- `$env` bloqueado em nós; `require('crypto')` bloqueado em Code. → Auth (bcrypt +
  JWT HS256) feito **100% em SQL via `pgcrypto`**, sem nó Code. Segredos hardcoded.
- `queryReplacement` do nó Postgres é CSV: **valor vazio é descartado** → erro
  "no parameter $N". Solução: sentinela `__NULL__` + `nullif($n,'__NULL__')`.
  Para valor que **contém vírgula** (ex: JSON do LLM), passar `queryReplacement`
  como **array** `={{ [a, b] }}` em vez de string CSV.
- Webhook com **path param `:id` exige o webhookId na URL** (que o app não tem).
  Solução: endpoints de mutação usam **POST + id no body** + path estático
  (ex: `/me/orders/cancel`, `/me/addresses/delete`, `/admin/products/update`);
  endpoints GET por id usam **query string** `?id=` (ex: `/products/detail`).
- **CTE única: INSERT irmão NÃO é visível ao SELECT final** (mesmo snapshot).
  Pra responder dados recém-inseridos, montar a resposta dos dados de ENTRADA,
  não relendo o banco. NÃO usar `SELECT INTO TEMP` (vaza entre requests no pool).
- **Nós langchain somem no import via SDK** (AI Agent, Guardrails, lmChat*,
  memory, tools). Por isso o Consultor IA usa **ModelScope via HTTP Request**
  (nó nativo), não nós langchain. `fetch` não existe no Code — usar
  `this.helpers.httpRequest(...)`.
- **`update_workflow` salva RASCUNHO** — o webhook de produção roda a versão
  antiga até chamar **`publish_workflow`**. Sempre publicar após atualizar.

## Postgres

- Credential no n8n: **`Postgres account`**. Extensions: `pgcrypto`, `citext`.
- Tabelas criadas: `users` (+ `google_sub`), `addresses`, `products`, `reviews`
  (+ `photo_url`), `orders`, `order_items`, `order_timeline`, `user_favorites`,
  `notifications`, `chat_sessions`, `chat_messages`, `preview_usage`.
- Seed: 4 produtos originais + **15 produtos novos** (variados, todas
  temperaturas/cômodos/bocais), 2 notifs do usuário teste.

## Workflows n8n — TODOS ativos e testados end-to-end

Auth: `login-raitocorp`, `register-raitocorp`, `auth-google-raitocorp`.
Perfil: `me-get`, `me-patch`. Endereços: `me-addresses-get/post/delete/default`.
Catálogo (público): `products-get`, `products-detail`, `products-reviews`.
Favoritos: `me-favorites-get/toggle`. Notificações: `me-notifications-get/read/readall/delete`.
Pedidos: `me-orders-get/post/cancel/review`.
Admin (valida is_admin no SQL): `admin-orders-get/advance`,
`admin-products-create/update/delete`.
**Consultor IA**: `consultant-message`, `consultant-image`, `consultant-preview`,
`consultant-sessions`, `consultant-clear` — todos ativos (ver abaixo).

Migrações temporárias já arquivadas (apagar de vez na UI do n8n, filtro Archived).

## App Flutter — completo

Todas as features cabeadas e batendo na API real: auth (incl. Google*), perfil,
endereços, catálogo, favoritos, notificações, pedidos, **hub admin** (CRUD de
produtos + avançar pedidos, em `lib/features/admin/`, gated por `is_admin` no
profile), **review do cliente** com foto (`review_order_screen.dart`),
**notificações locais** (status do pedido via `flutter_local_notifications`) e
**Consultor IA** (`lib/features/consultant/`). Upload de imagem via Cloudinary
(`lib/core/upload/cloudinary_service.dart`). `flutter analyze`: 0 erros.

\* Login Google: backend pronto, mas precisa de config no Google Cloud Console
(origin/SHA-1) — ver pendência abaixo.

## Consultor IA — pronto e funcionando (stack ModelScope)

Antes era a única pendência; **hoje está completo**. Toda a IA roda no
**ModelScope** (Alibaba, token único, sem cota de 20/dia do Gemini):

- **`/message`** — chat por texto. `Qwen2.5-72B-Instruct` (chat completions
  formato OpenAI). Guardrail por prompt de sistema ("só fale de iluminação").
  Recomenda usando `lumens`/`color_temperature_k`/`ideal_rooms` do catálogo.
- **`/image`** — recomendação por foto do ambiente (+ texto opcional).
  `Qwen2.5-VL-72B-Instruct` (visão) recebe a URL Cloudinary direto, classifica o
  ambiente nos enums do `ProductEntity`, faz scoring SQL e devolve top 3.
- **`/preview`** — "ver o produto no meu ambiente". `Qwen-Image-Edit-2509`
  (edição de imagem). **Assíncrono com polling** (o Cloudflare corta conexão
  síncrona em ~100s): a 1ª chamada submete e devolve `task_id`; o app reenvia o
  `task_id` a cada 30s (até 5 min). **Limite 2/dia por usuário** (tabela
  `preview_usage`, 429 com mensagem amigável). Resultado sobe pro Cloudinary.
- **`/sessions?id=`** — histórico da conversa (reabrir sessão; `session_id`
  persistido em Hive box `consultant_box`).
- **`/clear`** — apaga as mensagens da sessão (botão lixeira na AppBar).

Detalhes finos (gotchas de async, shrink de imagem, retry) em
[`N8N_API.md`](./N8N_API.md) §3.22–3.26.

## Build / distribuição

- Android SDK instalado em `C:\Users\Icaro\AppData\Local\Android\Sdk`
  (cmdline-tools + platform-tools + android-36 + build-tools 36.0.0). Java 21.
- APK release: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
  (~56 MB), assinado com debug key (instala em qualquer Android com "fontes
  desconhecidas").
- Nome do app: **RaitoCorp** (`android:label`). Ícone: lâmpada âmbar com glow e
  filamento em "R" (`tool/gen_icon.py` via PIL + `flutter_launcher_icons`).
- Core library desugaring habilitado no Gradle (exigido por
  `flutter_local_notifications`).

## Pendências

1. **Login Google** — `origin_mismatch`/SHA-1 no Google Cloud Console (projeto
   `raitocorp-e46a7`). Email/senha funciona; Google precisa dessa config externa.
2. **Fotos dos 15 produtos novos** — estão com placeholder; gerar imagens de
   produto (estilo e-commerce) e trocar o `image_urls` de cada um pelo painel
   admin do app ou via SQL.
3. **Testar no Chrome dá CORS** (`No 'Access-Control-Allow-Origin'`) — os
   webhooks n8n não liberam CORS. Testar sempre no **Android/emulador**.
4. **Segredos hardcoded e debug-signing**: OK pra TCC; trocar antes de prod real.
