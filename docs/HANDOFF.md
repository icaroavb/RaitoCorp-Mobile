# HANDOFF — Estado do projeto (atualizado 2026-05-25)

> Documento de retomada. Leia isto primeiro ao continuar o trabalho — evita
> redescobrir tudo do zero. Mantenha atualizado ao fim de cada sessão.

## Contexto geral

App Flutter (Raitõ — loja de iluminação) migrando de **dados mock → API real
via n8n**. O n8n é o gateway/regras de negócio entre o app e o Postgres; o app
nunca fala direto com o banco. Contrato completo em [`N8N_API.md`](./N8N_API.md).

- n8n: `https://n8n.raitocorp.com.br` (roda na máquina de um colega, via
  Cloudflare). Acessível por **MCP** (workflows/data tables) — **sem** acesso
  ao host nem ao Postgres direto.
- Repo: branch `main`, só existe o commit inicial. **Nada commitado ainda** —
  toda a migração está como working changes.

## ⚠️ Restrições críticas da instância n8n (hardened)

A instância bloqueia coisas que o desenho original assumia. **Três tentativas
falharam** antes de achar o caminho:

| Bloqueio | Sintoma | Consequência |
|---|---|---|
| `N8N_BLOCK_ENV_ACCESS_IN_NODE` | "access to env vars denied" | `$env` não funciona em nó IF/Code/expressão. Setar env var no host NÃO adianta. |
| `NODE_FUNCTION_ALLOW_BUILTIN` | "Module 'crypto' is disallowed" | nó Code não pode `require('crypto')`. |
| Header Auth credential | — | só injeta header em HTTP de saída; não dá pra ler valor cru em IF/Code. |

**Solução adotada:** verificação de senha (bcrypt) + geração de JWT (HS256)
**100% em SQL via `pgcrypto`** (`crypt`/`gen_salt('bf')`/`hmac`), num nó Postgres.
Sem nó Code. Segredos **hardcoded** nos workflows (temporário).

→ **Regra:** ao criar qualquer workflow de auth aqui, NÃO use `$env` nem
`require()` em Code. Faça crypto em SQL.

## Postgres

- Credential no n8n chama-se **`Postgres account`** (não "Raitocorp Postgres"
  como diz uma sticky antiga). Referenciar via `newCredential('Postgres account')`.
- Extensions habilitadas: `pgcrypto`, `citext`.
- Tabela `users` criada e verificada. Demais tabelas do schema (§2 do
  N8N_API.md) **ainda NÃO criadas**.

## Segredos (hardcoded temporariamente nos workflows)

```
APP_API_KEY = raito_81f96262486efad255c453798b769d0ce9c5eb057772f5c2
JWT_SECRET  = bj6VFq3FcdWYVl4Mv-3_fDSbGesnSfjHdVOq8VoFqfshrZo0W7x3tZPHTztc-3sl
```
- `APP_API_KEY` também precisa ir no build do app: `--dart-define=N8N_API_KEY=...`
- `JWT_SECRET` é segredo de servidor — nunca vai pro app.
- **Antes de prod:** mover pra tabela `app_secrets` (lida via Postgres) ou pedir
  ao admin liberar `$env`/`crypto`.

## Workflows n8n

| Workflow | ID | Estado |
|---|---|---|
| **login-raitocorp** (válido) | `6y56Z2bgqBERtPAr` | ✅ testado, **inativo** (falta publish) |
| chatbot RaitoCorp | `LkLWXSX81vteUD8q` | ativo (pré-existente, não mexido) |

**Login testado end-to-end:** cred correta → 200+JWT (assinatura verificada);
senha errada → 401; api key errada → 401. JWT HS256 válido.

**Usuário de teste:** `teste@raito.com` / `teste1234` (hash bcrypt na tabela).

### Workflows pra DELETAR pela UI do n8n
MCP só arquiva (não deleta permanente). Já arquivados — apagar de vez no painel
(filtro "Archived" → Delete). Manter SÓ o `6y56Z2bgqBERtPAr`.
- Logins antigos quebrados: `OnJsbboTT6q8uTy7`, `xfcAAb4qURUtt93n`
- Descartáveis: `fwOvpdon6Xkj2u9X` (setup-users), `1NYpFeEn3kZTrJ2E` (check-env),
  `TapN5bmyuk0Otl4t` (seed-user), `VmOifzym226Lq9hx` (probe-pgcrypto),
  `V4KRqUgeupnymRm7` (reseed-bcrypt), `WgfgwVKYTrZmku1E` (jwt-probe)

## Código Flutter (camada de API)

Já criado e compila limpo (`flutter analyze`: 0 erros, ~20 lints de estilo):
- `lib/core/config/app_config.dart` — config via `--dart-define`
- `lib/core/api/` — api_client, api_exception, api_providers, auth_storage (JWT)
- `lib/features/*/data/*_repository.dart` — repos de auth, consultant, products,
  profile (addresses/favorites/notifications/orders)
- Entities ganharam `fromJson`/`toJson`; providers consomem repos; mocks deletados.

## Próximos passos (em aberto)

1. **Ativar (publish)** o login-raitocorp quando quiser produção.
2. Criar workflow **register** (`POST /auth/register`) — mesmo padrão SQL/pgcrypto
   (INSERT com `crypt($3, gen_salt('bf',12))` + JWT em SQL).
3. Criar as **demais tabelas** do schema (§2 N8N_API.md) e os endpoints
   protegidos (`/me/*`, products, orders, etc.).
4. Resolver upload de imagem do consultor (§3.23 — TODO no contrato).
5. Mover segredos pra solução não-hardcoded.
6. Limitação conhecida: o nó Postgres do login usa `queryReplacement` separado
   por vírgula → email/senha não podem conter vírgula. Trocar por params reais
   se virar problema.
7. Commitar a migração (nada commitado ainda).

## Notas técnicas úteis

- base64url em SQL: `replace(replace(translate(encode(x,'base64'),'+/','-_'),'=',''), E'\n','')`
- Verificar JWT localmente: decodificar e comparar `hmac(header.payload, secret, sha256)`.
- O MCP `update_workflow` corrompeu o login uma vez (injetou `jwtAuth` no webhook,
  reverteu nós). **Preferir arquivar + recriar** a dar update em workflows críticos.
