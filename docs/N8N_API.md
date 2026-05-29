# Contrato da API n8n — Raitõ Mobile

Este documento define todos os webhooks que o app Flutter espera consumir.
O n8n age como API gateway e camada de regras de negócio entre o app e o
Postgres — **o app nunca conecta direto no banco**.

> Base URL (produção): `https://n8n.raitocorp.com.br`
> Prefixo padrão dos webhooks: `/webhook`
> Em modo de teste do n8n use `/webhook-test` (configurável em [app_config.dart](../lib/core/config/app_config.dart) via `--dart-define=N8N_WEBHOOK_PREFIX`)

---

## 1. Autenticação

### Estratégia

Duas camadas somadas:

1. **`X-API-Key`** — chave estática, embutida no build do app via
   `--dart-define=N8N_API_KEY=...`. Bloqueia tráfego curioso e permite
   rate-limit. Não autentica usuário.
2. **`Authorization: Bearer <JWT>`** — emitido pelo próprio n8n no login,
   assinado com HS256 e secret guardado em Credentials do n8n. Identifica
   o usuário (`sub = user.id`). TTL recomendado: 7 dias.

Cada webhook protegido deve ter, antes do nó Postgres:

1. Nó `IF` checando `headers['x-api-key'] == <APP_API_KEY>` → senão `401`.
2. Validação do JWT + extração do `user_id` pra usar nas queries.

> ⚠️ **Restrições desta instância n8n** (descobertas em 2026-05-25):
> Esta instância está *hardened* e bloqueia três coisas que o desenho
> original assumia:
> - **`$env` em nós** (`N8N_BLOCK_ENV_ACCESS_IN_NODE`): não dá pra ler
>   `$env.APP_API_KEY` / `$env.JWT_SECRET` em nó IF, Code ou expressão.
> - **`require('crypto')` em nós Code** (`NODE_FUNCTION_ALLOW_BUILTIN`):
>   o nó Code não importa módulos built-in do Node.
> - Por isso a verificação de senha e a geração de JWT são feitas
>   **inteiramente em SQL via `pgcrypto`** (ver §3.2), e os segredos
>   `APP_API_KEY` / `JWT_SECRET` estão **hardcoded** nos workflows
>   (temporário). Para produção: pedir ao admin liberar `$env`/`crypto`,
>   ou mover os segredos pra uma tabela `app_secrets` lida via Postgres.

### Endpoints públicos (sem JWT)

| Método | Path | Descrição | Status |
|---|---|---|---|
| POST | `/auth/register` | Cria conta com email/senha + devolve JWT | ✅ `register-raitocorp` |
| POST | `/auth/login` | Valida credenciais + devolve JWT | ✅ `login-raitocorp` |
| POST | `/auth/google` | Troca id_token do Google por JWT Raitõ | ✅ `auth-google-raitocorp` |
| GET | `/products` | Lista pública do catálogo |
| GET | `/products/:id` | Detalhe público |
| GET | `/products/:id/reviews` | Reviews públicas |

### Endpoints protegidos (JWT obrigatório)

Todos sob `/me/*` e `/consultant/*`.

---

## 2. Schema Postgres sugerido

```sql
-- Habilite as extensions necessárias
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- emails case-insensitive

-- ── Usuários ─────────────────────────────────────────────────────────────
CREATE TABLE users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           CITEXT UNIQUE NOT NULL,
  name            TEXT NOT NULL,
  password_hash   TEXT,                       -- bcrypt via pgcrypto crypt(); NULL para contas só-Google
  google_sub      TEXT UNIQUE,                -- 'sub' do id_token Google
  phone           TEXT,
  birth_date      DATE,
  is_admin        BOOLEAN NOT NULL DEFAULT FALSE,
  loyalty_points  INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Endereços ────────────────────────────────────────────────────────────
CREATE TABLE addresses (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label         TEXT NOT NULL,
  street        TEXT NOT NULL,
  number        TEXT NOT NULL,
  complement    TEXT,
  neighborhood  TEXT NOT NULL,
  city          TEXT NOT NULL,
  state         CHAR(2) NOT NULL,
  zip_code      TEXT NOT NULL,
  is_default    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON addresses (user_id);

-- ── Catálogo ─────────────────────────────────────────────────────────────
CREATE TABLE products (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                   TEXT NOT NULL,
  description            TEXT NOT NULL,
  price                  NUMERIC(10,2) NOT NULL,
  original_price         NUMERIC(10,2),
  image_urls             TEXT[] NOT NULL DEFAULT '{}',
  light_temperature      TEXT NOT NULL,       -- warm | neutral | cool
  socket_type            TEXT NOT NULL,
  is_bivolt              BOOLEAN NOT NULL DEFAULT TRUE,
  is_easy_install        BOOLEAN NOT NULL DEFAULT FALSE,
  energy_saving_percent  INT NOT NULL DEFAULT 0,
  lifespan_years         INT NOT NULL DEFAULT 0,
  brightness_level       TEXT NOT NULL,       -- soft | medium | intense
  ideal_rooms            TEXT[] NOT NULL DEFAULT '{}',
  power_watts            INT NOT NULL,
  lumens                 INT NOT NULL,
  color_temperature_k    INT NOT NULL,
  dimensions             TEXT,
  weight_kg              NUMERIC(6,2),
  certifications         TEXT[] NOT NULL DEFAULT '{}',
  warranty_years         INT NOT NULL DEFAULT 1,
  rating                 NUMERIC(3,2) NOT NULL DEFAULT 0,
  review_count           INT NOT NULL DEFAULT 0,
  sold_count             INT NOT NULL DEFAULT 0,
  is_best_seller         BOOLEAN NOT NULL DEFAULT FALSE,
  category               TEXT NOT NULL,       -- pendant | lamp | wallLamp | spot | strip | floorLamp | smart
  tags                   TEXT[] NOT NULL DEFAULT '{}',
  active                 BOOLEAN NOT NULL DEFAULT TRUE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE reviews (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id       UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id          UUID REFERENCES users(id) ON DELETE SET NULL,
  author_name      TEXT NOT NULL,
  rating           INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment          TEXT NOT NULL,
  room             TEXT,
  has_photo        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Pedidos ──────────────────────────────────────────────────────────────
CREATE TABLE orders (
  id                 TEXT PRIMARY KEY,        -- ex: short id legível "12847"
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status             TEXT NOT NULL,           -- confirmed | preparing | shipped | delivered | cancelled
  address_id         UUID NOT NULL REFERENCES addresses(id),
  address_snapshot   JSONB NOT NULL,          -- congela o endereço no momento da compra
  subtotal           NUMERIC(10,2) NOT NULL,
  shipping           NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount           NUMERIC(10,2) NOT NULL DEFAULT 0,
  payment_method     TEXT NOT NULL,
  estimated_delivery TIMESTAMPTZ,
  reviewed           BOOLEAN NOT NULL DEFAULT FALSE,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON orders (user_id, created_at DESC);

CREATE TABLE order_items (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id       TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id     UUID NOT NULL REFERENCES products(id),
  product_name   TEXT NOT NULL,               -- snapshot
  image_url      TEXT NOT NULL,
  subtitle       TEXT,
  price          NUMERIC(10,2) NOT NULL,
  quantity       INT NOT NULL CHECK (quantity > 0)
);
CREATE INDEX ON order_items (order_id);

CREATE TABLE order_timeline (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  timestamp    TIMESTAMPTZ,
  completed    BOOLEAN NOT NULL DEFAULT FALSE,
  active       BOOLEAN NOT NULL DEFAULT FALSE,
  description  TEXT,
  position     INT NOT NULL
);
CREATE INDEX ON order_timeline (order_id, position);

-- ── Favoritos ────────────────────────────────────────────────────────────
CREATE TABLE user_favorites (
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, product_id)
);

-- ── Notificações ─────────────────────────────────────────────────────────
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL,                  -- order | promotion | system | review
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  read        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON notifications (user_id, created_at DESC);

-- ── Chat / Consultor IA ──────────────────────────────────────────────────
CREATE TABLE chat_sessions (
  id           TEXT PRIMARY KEY,              -- gerado pelo app
  user_id      UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE chat_messages (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id                  TEXT NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
  author                      TEXT NOT NULL,  -- user | bot
  type                        TEXT NOT NULL,  -- text | image | productRecommendation
  text                        TEXT,
  image_path                  TEXT,
  product_recommendations     UUID[] NOT NULL DEFAULT '{}',
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ON chat_messages (session_id, created_at);
```

---

## 3. Endpoints

Formato comum:
- Request/response sempre `application/json`.
- Datas: ISO 8601 UTC (`2026-04-08T11:32:00Z`).
- IDs: string (UUID ou short id).
- Erros: `{ "message": "...", "errors": { "campo": "msg" } }` com status apropriado.

### 3.1 `POST /auth/register`

Public.

**Request:**
```json
{ "name": "João Silva", "email": "joao@email.com", "password": "..." }
```

**Response 200:**
```json
{
  "token": "eyJhbGciOi...",
  "user": {
    "email": "joao@email.com",
    "name": "João Silva",
    "initials": "JS",
    "is_admin": false,
    "member_since": "2026-05-24T12:00:00Z",
    "loyalty_points": 100
  }
}
```

**Workflow n8n** (tudo em SQL — sem nó Code, ver restrições na §1):
1. Webhook `POST /auth/register`
2. `IF` X-API-Key válida (comparação com literal hardcoded)
3. Postgres numa query só:
   - checa duplicidade; se email existe → `statusCode 422`
   - senão `INSERT INTO users(email,name,password_hash)
     VALUES ($1,$2, crypt($3, gen_salt('bf',12))) RETURNING *`
     (bcrypt cost 12 via `pgcrypto`)
   - monta o JWT HS256 no próprio SQL (ver §3.2)
4. `IF` decide 200/422 pelo `statusCode`
5. Respond `{ token, user }`

### 3.2 `POST /auth/login`

**Request:** `{ "email": "...", "password": "..." }`
**Response:** mesmo formato do register.
**401** se credencial inválida.

**Implementado (workflow `login-raitocorp`, id `6y56Z2bgqBERtPAr`):**
verificação de senha + geração de JWT feitas inteiramente em SQL via
`pgcrypto`, sem nó Code. Esqueleto da query do nó "Authenticate":

```sql
WITH input AS (
  SELECT $1::text AS in_email, $2::text AS in_password,
         '<JWT_SECRET>'::text AS secret
),
found AS (
  SELECT u.*, i.in_password, i.secret,
    (u.password_hash IS NOT NULL
     AND u.password_hash = crypt(i.in_password, u.password_hash)) AS pw_ok
  FROM input i LEFT JOIN users u ON u.email = i.in_email
),
-- monta header.payload (base64url) e assina com hmac(..., secret, 'sha256')
-- base64url(x) = replace(replace(translate(encode(x,'base64'),'+/','-_'),'=',''), E'\n','')
token AS ( ... )  -- token = header_b64 || '.' || payload_b64 || '.' || sig
SELECT
  CASE WHEN pw_ok THEN 200 ELSE 401 END AS "statusCode",
  CASE WHEN pw_ok
    THEN json_build_object('token', jwt_token, 'user', json_build_object(...))
    ELSE json_build_object('message','Credenciais invalidas')
  END AS body
FROM token;
```

- Senha: bcrypt via `crypt(senha, hash)` (o `gen_salt('bf',12)` é usado no register).
- JWT: `hmac(header.payload, secret, 'sha256')` + base64url, 100% compatível
  com qualquer verificador HS256 (testado: assinatura confere).
- ⚠️ O nó Postgres usa `queryReplacement` separado por vírgula, então email
  e senha **não podem conter vírgula** com esse método. Trocar pra parâmetros
  reais se isso virar problema.

### 3.3 `POST /auth/google` ✅ implementado (`auth-google-raitocorp`)

**Request:** `{ "id_token": "<google id_token>" }`

**Workflow:**
1. HTTP node: `GET https://oauth2.googleapis.com/tokeninfo?id_token={{$json.body.id_token}}` (`neverError`).
2. Valida `aud == client_id` do app (`250510478199-...apps.googleusercontent.com`) no SQL.
3. Upsert em `users` por `email` (grava `google_sub`); cria com 100 pontos se primeiro login.
4. Devolve `{ token, user }` igual ao login. **401** "Login Google invalido" se token inválido.

> Erros testados via curl (id_token falso → 401, sem api key → 401). O caminho
> feliz precisa de um id_token real do Google → validar rodando o app.

### 3.4 `GET /me` *(JWT)* ✅ implementado (`me-get-raitocorp`)

Reidrata sessão. Response = `user` (mesmo formato do `auth.user`).
JWT validado 100% em SQL (recalcula HMAC, decodifica payload base64url, checa `exp`).

### 3.5 `PATCH /me` *(JWT)* ✅ implementado (`me-patch-raitocorp`)

Atualiza nome/telefone.

**Request:** `{ "name": "...", "phone": "..." }` (campos opcionais)
**Response 200:** user atualizado.

### 3.6 `GET /products`

Public.

**Response 200:** array de produtos no formato:
```json
[
  {
    "id": "uuid",
    "name": "Pendente Moderno",
    "description": "...",
    "price": 890.00,
    "original_price": null,
    "image_urls": ["https://..."],
    "light_temperature": "warm",
    "socket_type": "E27",
    "is_bivolt": true,
    "is_easy_install": true,
    "energy_saving_percent": 80,
    "lifespan_years": 15,
    "brightness_level": "medium",
    "ideal_rooms": ["diningRoom", "living", "kitchen"],
    "power_watts": 9,
    "lumens": 800,
    "color_temperature_k": 3000,
    "dimensions": "Ø 50cm × Alt. 30cm",
    "weight_kg": 1.2,
    "certifications": ["INMETRO"],
    "warranty_years": 5,
    "rating": 4.8,
    "review_count": 47,
    "sold_count": 312,
    "is_best_seller": true,
    "category": "pendant",
    "tags": ["Luz quente", "Fácil instalar"]
  }
]
```

**SQL:** `SELECT * FROM products WHERE active = TRUE ORDER BY is_best_seller DESC, name`
✅ implementado (`products-get-raitocorp`). Arrays TEXT[] viram arrays JSON via `to_jsonb`.

### 3.7 `GET /products/detail?id=` ✅ implementado (`products-detail-raitocorp`)

> ⚠️ Era `GET /products/:id` — path param `:id` não funciona no n8n sem
> webhookId. Virou path estático + **query string** `?id=`.

Public. Response = um produto. **404** se não existe/inativo (id malformado também cai em 404, sem erro).

### 3.8 `GET /products/reviews?id=` ✅ implementado (`products-reviews-raitocorp`)

> ⚠️ Era `GET /products/:id/reviews` — mesmo motivo. Query string `?id=`.

Public. `author_initials` calculado no SQL; coluna `created_at` mapeada pra `date`.

```json
[
  {
    "id": "uuid",
    "author_name": "Mariana S.",
    "author_initials": "MS",
    "rating": 5,
    "comment": "...",
    "date": "2026-03-10T00:00:00Z",
    "room": "bedroom",
    "has_photo": false
  }
]
```

### 3.9 `GET /me/orders` *(JWT)* ✅ implementado (`me-orders-get-raitocorp`)

Lista pedidos do usuário do token. Cada pedido com `items[]` e `timeline[]`.

```sql
SELECT
  o.*,
  (SELECT json_agg(i) FROM order_items i WHERE i.order_id = o.id) AS items,
  (SELECT json_agg(t ORDER BY t.position) FROM order_timeline t WHERE t.order_id = o.id) AS timeline
FROM orders o
WHERE o.user_id = $jwt.sub
ORDER BY o.created_at DESC;
```

O n8n deve montar `address` a partir de `address_snapshot` (que é o endereço congelado no momento da compra).

### 3.10 `POST /me/orders` *(JWT)* ✅ implementado (`me-orders-post-raitocorp`)

**Request:**
```json
{
  "items": [
    { "product_id": "uuid", "product_name": "...", "image_url": "...",
      "subtitle": "...", "price": 890.00, "quantity": 1 }
  ],
  "address_id": "uuid",
  "payment_method": "Pix",
  "subtotal": 890.00,
  "shipping": 0,
  "discount": 89
}
```

**Workflow:**
1. Valida JWT.
2. Postgres: `SELECT * FROM addresses WHERE id=$1 AND user_id=$jwt.sub` (snapshot).
3. Gera short id (`SELECT lpad((floor(random()*100000))::text, 5, '0')` ou contador).
4. Insere `orders`, `order_items[]`, `order_timeline[]` (5 eventos: Confirmado✓, Pagamento, Em preparo, Saiu, Entregue).
5. Insere notificação "Pedido confirmado".
6. Retorna o pedido completo (mesmo formato do `GET /me/orders`).

### 3.11 `POST /me/orders/cancel` *(JWT)* ✅ implementado (`me-orders-cancel-raitocorp`)

> ⚠️ Era `PATCH /me/orders/:id/cancel` — path param `:id` não funciona no n8n. Virou POST + `id` no body.

**Request:** `{ "id": "<order id>" }`
**Workflow:**
1. `UPDATE orders SET status='cancelled' WHERE id=$1 AND user_id=sub AND status IN ('confirmed','preparing','shipped')`.
2. Insere evento "Cancelado" em `order_timeline`.
3. Retorna pedido atualizado (timeline já inclui Cancelado). **422** se não cancelável.

### 3.12 `GET /me/addresses` *(JWT)* ✅ implementado (`me-addresses-get-raitocorp`)

Array de addresses do usuário (default primeiro). `[]` se nenhum.

### 3.13 `POST /me/addresses` *(JWT)* ✅ implementado (`me-addresses-post-raitocorp`)

**Request:** body do `AddressEntity.toJson()` sem `id`.
**Response 200:** address criado (com `id` gerado).

Lógica especial: se for o primeiro endereço, marca `is_default=true`.

### 3.14 `POST /me/addresses/delete` *(JWT)*

> ⚠️ Era `DELETE /me/addresses/:id`, mas webhook n8n com path param dinâmico
> (`:id`) exige o `webhookId` aleatório na URL — o app não tem como montar isso
> de forma limpa. Virou **POST com path estático + `id` no body**.

**Request:** `{ "id": "uuid" }`
Remove. Se o removido era o default e ainda há outros, promove o mais antigo.
**Response 200:** `{ "message": "ok", "deleted": 1, "promoted": 0|1 }`. **401** se não autorizado.
Implementado: `me-addresses-delete-raitocorp`.

### 3.15 `POST /me/addresses/default` *(JWT)*

> ⚠️ Era `PATCH /me/addresses/:id/default` — mesmo motivo do §3.14.

**Request:** `{ "id": "uuid" }`
Transação: zera `is_default` de todos do user, marca `id=true`.
**Response 200:** `{ "message": "ok", "updated": 1 }`. **401** se não autorizado.
Implementado: `me-addresses-default-raitocorp`.

### 3.16 `GET /me/favorites` *(JWT)* ✅ implementado (`me-favorites-get-raitocorp`)

Retorna **array de product_ids** (strings):
```json
["uuid1", "uuid2", "uuid3"]
```

### 3.17 `POST /me/favorites/toggle` *(JWT)* ✅ implementado (`me-favorites-toggle-raitocorp`)

**Request:** `{ "product_id": "uuid" }`

**Workflow:**
```sql
INSERT INTO user_favorites (user_id, product_id)
VALUES ($jwt.sub, $1)
ON CONFLICT (user_id, product_id) DO DELETE
RETURNING xmax = 0 AS favorited;
```
*(ou usa duas queries: SELECT pra decidir, depois INSERT/DELETE)*

**Response:** `{ "favorited": true }` ou `{ "favorited": false }`

### 3.18 `GET /me/notifications` *(JWT)* ✅ implementado (`me-notifications-get-raitocorp`)

Array de notificações do usuário ordenado por `created_at DESC`. `user_email` via join.

### 3.19 `POST /me/notifications/read` *(JWT)* ✅ implementado (`me-notifications-read-raitocorp`)

> ⚠️ Era `PATCH /me/notifications/:id/read`. Virou POST + `id` no body.
`UPDATE notifications SET read=true WHERE id=$1 AND user_id=sub`

### 3.20 `POST /me/notifications/read-all` *(JWT)* ✅ implementado (`me-notifications-readall-raitocorp`)

`UPDATE notifications SET read=true WHERE user_id=sub AND read=false`

### 3.21 `POST /me/notifications/delete` *(JWT)* ✅ implementado (`me-notifications-delete-raitocorp`)

> ⚠️ Era `DELETE /me/notifications/:id`. Virou POST + `id` no body.

### 3.22 `POST /consultant/message` *(JWT)*

**Request:**
```json
{ "session_id": "sess-123", "text": "Como ilumino meu quarto?" }
```

**Workflow:**
1. Upsert `chat_sessions(id, user_id)`.
2. Insert `chat_messages` (author=user).
3. Busca histórico recente (últimas 10 msgs) pra contexto.
4. Chama LLM (OpenAI/Anthropic) com prompt do "Consultor Raitõ" + histórico + lista resumida do catálogo.
5. Parse resposta — se contém recomendações, extrai product_ids.
6. Insert `chat_messages` (author=bot).
7. Retorna a mensagem do bot:
```json
{
  "id": "uuid",
  "author": "bot",
  "type": "text",
  "text": "Para o quarto, recomendo luz quente 3000K...",
  "product_recommendations": ["uuid1"],
  "created_at": "2026-05-24T13:00:00Z"
}
```

**Implementado (`consultant-message-raitocorp`, id `gPCSDVibMq8ZEsfI`):**
Decisão de arquitetura — virou **AI Agent** (a montar na UI; ver nota abaixo).
A casca (auth + log + Save bot msg + respond) está no SDK; o **Railguards**
(Guardrails classify: jailbreak + nsfw + topical alignment "só iluminação") e o
**AI Agent** (Gemini Chat + Postgres Chat Memory + Postgres Tool catálogo +
Output Parser `{reply, product_ids}`) precisam ser arrastados no editor entre
`Authorized?` e `Save bot msg` — esta instância **descarta nós langchain no
import via SDK**. O `Save bot msg` já lê `$node["Consultor Raito"].json.output`.

### 3.23 `POST /consultant/image` *(JWT)* ✅ implementado (`consultant-image-raitocorp`)

Estratégia de upload definida: **Cloudinary** (Opção A). O app sobe a foto pro
Cloudinary (`CloudinaryService`) e manda a `secure_url` no `image_path`. O n8n
baixa a URL, manda a imagem inline pro **Gemini 2.5 Flash** classificar o
ambiente nos enums do `ProductEntity` (`room`/`light_temperature`/
`brightness_level`), faz scoring SQL e recomenda **top 3** (nunca vazio). Se a
foto não der pra classificar, devolve os top-rated + texto pedindo contexto.

**Request:** `{ "session_id": "...", "image_path": "<url Cloudinary>" }`
**Response:** `MessageEntity` (`type: productRecommendation`).

### 3.24 `GET /consultant/sessions?id=` *(JWT)* ✅ implementado (`consultant-sessions-raitocorp`)

> ⚠️ Era `/consultant/sessions/:id` — path param `:id` não funciona no n8n.
> Virou **query string** `?id=`.

Histórico de uma sessão (pra retomar conversa). Array de `MessageEntity`.

### 3.25 `POST /consultant/preview` *(JWT)* ✅ implementado (`consultant-preview-raitocorp`)

Preview "produto no meu ambiente": funde a **última foto do ambiente** da sessão
com a foto do **produto** usando o **Gemini 2.5 Flash Image (nano banana)** e
sobe o resultado pro Cloudinary. **Limite de 2/dia por usuário** (tabela
`preview_usage`, reset à meia-noite UTC).

**Request:** `{ "session_id": "...", "product_id": "uuid" }`
**Response 200:** `MessageEntity` (`type: image`, `image_path` = URL do preview).
- **429** se o usuário já usou 2 previews hoje (mensagem amigável no body).
- **422** se a sessão não tem foto de ambiente ("manda uma foto primeiro").
- **404** se o produto não existe.

O app trata 429/422/404 exibindo a `message` do body como mensagem do bot.

---

## 4. Convenções de erro

| Status | Significado | App reage como |
|---|---|---|
| 400/422 | Validação | `ValidationException` — mostra erro de campo |
| 401 | Token inválido/expirado | Limpa storage + redireciona pra `/login` |
| 403 | Sem permissão | Snackbar "Acesso negado" |
| 404 | Recurso inexistente | Tela vazia / "Não encontrado" |
| 5xx | Erro do servidor | Snackbar genérica + manter estado anterior |

Sempre devolva JSON, mesmo em erro:
```json
{ "message": "E-mail já cadastrado", "errors": { "email": "Em uso" } }
```

---

## 5. Boas práticas de segurança

- **HTTPS only** (Cloudflare ou nginx na frente do n8n).
- **JWT secret** com no mínimo 32 bytes random. Hoje está **hardcoded** no
  workflow (temporário, ver §1); o ideal é `$env`/Credentials/tabela secreta.
- **Senhas**: usamos **bcrypt cost 12** via `pgcrypto` (`crypt()` + `gen_salt('bf',12)`),
  direto no Postgres — não precisa de nó community nem de `crypto` no Code.
- **Rate-limit no `/auth/login`**: nó "Wait" + memória, ou Cloudflare WAF (5 tentativas/min por IP).
- **CORS**: restringe `Access-Control-Allow-Origin` ao bundle id do app na build mobile; no web, ao domínio do site.
- **Logs sem PII**: nunca logue senha, token completo ou número de cartão.

---

## 6. Build do app pra cada ambiente

```bash
# dev (n8n local)
flutter run \
  --dart-define=N8N_BASE_URL=http://10.0.2.2:5678 \
  --dart-define=N8N_API_KEY=dev-key \
  --dart-define=N8N_WEBHOOK_PREFIX=/webhook-test

# staging
flutter build apk \
  --dart-define=N8N_BASE_URL=https://n8n-staging.raitocorp.com.br \
  --dart-define=N8N_API_KEY=$STAGING_KEY

# prod
flutter build appbundle \
  --dart-define=N8N_BASE_URL=https://n8n.raitocorp.com.br \
  --dart-define=N8N_API_KEY=$PROD_KEY
```

Crie scripts em `scripts/run-dev.ps1`, `scripts/build-prod.ps1` quando quiser parar de digitar tudo isso.
