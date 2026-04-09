# Raitõ Corp — Mobile E-commerce

Aplicativo de e-commerce de iluminação desenvolvido em Flutter. Cobre o ciclo completo de compra: navegação de produtos, carrinho persistente, checkout com seleção de endereço e método de pagamento, acompanhamento de pedidos e gestão de perfil.

---

## Índice

1. [Visão geral](#visão-geral)
2. [Stack e dependências](#stack-e-dependências)
3. [Arquitetura](#arquitetura)
4. [Design system](#design-system)
5. [Funcionalidades](#funcionalidades)
6. [Integrações externas](#integrações-externas)
7. [Autenticação](#autenticação)
8. [Navegação](#navegação)
9. [Persistência de dados](#persistência-de-dados)
10. [Dados mock](#dados-mock)
11. [Estrutura de pastas](#estrutura-de-pastas)
12. [Como rodar](#como-rodar)
13. [Decisões técnicas](#decisões-técnicas)

---

## Visão geral

A Raitõ Corp é uma loja especializada em iluminação. O app cobre:

- Catálogo de produtos com filtro por ambiente e busca textual
- Carrinho persistente (sobrevive a reloads e redirecionamentos de auth)
- Checkout completo com seleção de endereço, método de pagamento e cálculo de descontos
- Histórico de pedidos com timeline de status e cancelamento
- Perfil completo: dados pessoais, endereços, favoritos, avaliações, notificações e pontos de fidelidade
- Login com email/senha e Google Sign-In (web + Android + iOS)
- Consultor IA integrado
- Auto-preenchimento de endereço via CEP

> **Este projeto é uma demonstração.** Toda autenticação, pedidos e produtos são mockados em memória. Nenhum dado é enviado para um backend real.

---

## Stack e dependências

### Flutter / Dart

| Pacote | Versão | Função | Por quê |
|---|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management | API declarativa, sem boilerplate de `ChangeNotifier`, suporte a `StateNotifier` com sealed class, sem `BuildContext` nos providers |
| `go_router` | ^14.6.2 | Navegação declarativa | Suporte nativo a `ShellRoute` (bottom nav persistente), deep links, query params para redirect de auth |
| `google_fonts` | ^6.2.1 | Tipografia | DM Serif Display + DM Sans via CDN — sem necessidade de empacotar fontes no bundle |
| `phosphor_flutter` | ^2.1.0 | Ícones | Biblioteca coerente com estilo editorial, versões `fill`/`regular`/`bold` do mesmo ícone |
| `cached_network_image` | ^3.4.1 | Imagens de rede | Cache em disco automático, placeholder e error builder sem configuração extra |
| `hive_flutter` | ^1.1.0 | Persistência local | NoSQL key-value extremamente rápido, sem dependência de FFI, compatível com web |
| `shared_preferences` | ^2.3.3 | Sessão de auth | Armazenamento simples de string (email do usuário logado) |
| `flutter_animate` | ^4.5.0 | Animações | DSL fluente para animar widgets sem `AnimationController` manual |
| `shimmer` | ^3.0.0 | Loading skeleton | Efeito de carregamento padrão de mercado com uma linha de código |
| `intl` | ^0.19.0 | Formatação | Locale `pt_BR` para moeda e datas |
| `image_picker` | ^1.1.2 | Galeria/câmera | Seleção de foto de perfil |
| `equatable` | ^2.0.7 | Igualdade de entidades | Evita `==` manual em entidades de domínio |
| `google_sign_in` | ^6.2.1 | Login social | OAuth2 via Google, compatível com Android, iOS e Web |
| `http` | ^1.2.2 | Requisições HTTP | ViaCEP, BrasilAPI e People API (fallback do Google Sign-In web) |

### Firebase / Google Cloud

| Serviço | Uso |
|---|---|
| Google Cloud OAuth 2.0 | Client ID para autenticação web via `google_sign_in` |
| People API | Busca nome/email do usuário após login Google na web (fallback quando o token flow não popula o `GoogleSignInAccount`) |

---

## Arquitetura

### Feature-First + Clean Architecture simplificada

O projeto segue uma arquitetura **feature-first** onde cada feature encapsula suas camadas internamente:

```
lib/features/<feature>/
  domain/
    entities/        ← modelos de dados puros (sem Flutter)
  presentation/
    providers/       ← estado Riverpod (StateNotifier / Provider)
    screens/         ← páginas completas
    widgets/         ← widgets reutilizáveis da feature
```

**Por que feature-first e não layer-first?**

Em projetos de médio porte, organizar por camada (`models/`, `screens/`, `providers/`) cria acoplamento invisível entre features: uma mudança na entidade `Order` exige navegar por 4 pastas diferentes. Com feature-first, tudo que pertence a `orders` fica junto — facilita deleção, refatoração e onboarding.

**Por que Clean Architecture simplificada?**

Não há repositórios nem casos de uso porque não há backend real. Adicionar essas camadas agora seria over-engineering. A separação `domain/entities` + `presentation/providers` já dá o benefício principal: entidades de domínio sem dependência de Flutter, e estado desacoplado da UI.

### Camadas presentes

```
┌─────────────────────────────────────────────┐
│  Presentation (Screens + Widgets)            │
│  Riverpod Providers (StateNotifier)          │
├─────────────────────────────────────────────┤
│  Domain (Entities — Dart puro)               │
├─────────────────────────────────────────────┤
│  Infrastructure (Mock data + Services)       │
│  Hive · SharedPreferences · HTTP APIs        │
└─────────────────────────────────────────────┘
```

---

## Design system

Todos os tokens de design são centralizados em `lib/core/theme/`:

### Cores — `AppColors`

| Token | Hex | Uso |
|---|---|---|
| `obsidian` | `#111111` | Texto primário, botões principais, fundo de cards escuros |
| `cream` | `#F9F5EF` | Background geral — evoca papel kraft, referência editorial |
| `warmWhite` | `#FFFFFF` | Fundo de cards e sheets |
| `amber400` | `#F5A623` | Acento principal — evoca luz quente incandescente |
| `amber600` | `#C47D0E` | Texto amber sobre fundo claro (contraste WCAG AA) |
| `success` | `#2D7A4F` | Confirmações, frete grátis, check de CEP |
| `error` | `#DC2626` | Erros de login, cancelamento de pedido |
| `warmLight` | `#F5A623` | Barra de temperatura quente nos produtos |
| `coolLight` | `#A8C8E8` | Barra de temperatura fria nos produtos |

**Por que âmbar como acento?** A Raitõ Corp vende iluminação. Âmbar é a cor da luz quente — o acento reforça o posicionamento de marca em cada elemento da UI.

### Tipografia — `AppTypography`

- **Títulos e display:** DM Serif Display — fonte serifada com personalidade editorial, usada em logos e headings
- **Corpo e UI:** DM Sans — sans-serif geométrica, excelente legibilidade em tamanhos pequenos

Ambas as fontes são da mesma família de design (DM), garantindo harmonia visual sem conflito tipográfico.

### Espaçamento — `AppSpacing`

Sistema baseado em múltiplos de 4px:

```
xs=4  sm=8  md=12  lg=16  xl=20  xxl=24  xxxl=32  huge=48  page=20
```

`page` é o padding horizontal padrão de todas as telas — garantia de margens consistentes.

### Bordas — `AppRadius`

```
sm=8  md=12  lg=16  xl=20  full=999
```

---

## Funcionalidades

### Home

- Banner hero com CTA de destaque
- Seção "Mais vendidos" com cards horizontais roláveis
- Seção de categorias por ambiente (Quarto, Sala, Escritório...)
- Banner do Consultor IA com gradiente navy/âmbar
- Avatar de perfil no AppBar: exibe iniciais quando logado, ícone quando não logado

### Catálogo de produtos

- Lista completa de produtos com `ProductCard`
- **Busca textual** em tempo real por nome, descrição e tags
- **Filtro por ambiente** (chips horizontais): Quarto, Sala, Cozinha, Escritório, Externo, Comercial
- Contagem de resultados em tempo real
- Cada card exibe:
  - Imagem com cache em disco
  - Nome, preço atual e preço original (com tachado quando há desconto)
  - Barra de temperatura de cor (quente → neutro → frio)
  - Tags de característica (Bivolt, Fácil instalação, LED, etc.)
  - Badge "Mais vendido"
  - Botão de favorito (requer login — exibe SnackBar quando não logado)
  - Botão de adicionar ao carrinho

### Detalhe do produto

- Galeria de imagens (múltiplos ângulos)
- Especificações técnicas: potência (W), lúmens, temperatura de cor (K), dimensões, peso
- Certificações e garantia
- Porcentagem de economia de energia
- Seção de avaliações com nota média e lista de reviews
- Indicação de ambientes ideais
- CTA de adicionar ao carrinho com SnackBar de confirmação

### Carrinho

- Listagem de itens com imagem, nome, subtítulo, preço e quantidade
- Controle de quantidade (+ / −) com atualização em tempo real
- Botão "Remover" individual e "Limpar tudo" no AppBar
- Resumo do pedido: subtotal, frete (grátis), total
- **Persistência via Hive** — o carrinho sobrevive a:
  - Hot restart
  - Redirecionamento para tela de login
  - Fechamento e reabertura do app
- **Auth guard:** ao clicar em "Finalizar compra" sem login, exibe bottom sheet com:
  - Botão "Fazer login" → `/login?redirect=/checkout`
  - Botão "Criar conta" → `/register?redirect=/checkout`
  - O carrinho continua intacto durante todo o fluxo de auth

### Checkout

- **Seção de itens:** lista resumida do carrinho
- **Seleção de endereço:**
  - Exibe endereço padrão automaticamente
  - Botão "Trocar" (quando há mais de 1 endereço) abre picker em bottom sheet
  - Se não há endereço: botão para adicionar novo via `AddressFormSheet`
- **Método de pagamento:**
  - **Pix** — desconto automático de 5% sobre o subtotal + aprovação imediata
  - **Cartão de crédito** — até 10x sem juros
  - **Boleto** — vence em 2 dias úteis
- **Resumo financeiro:** subtotal, frete, desconto (se Pix), total
- Botão "Confirmar pedido · R$ X" desabilitado quando não há endereço selecionado
- Loading modal durante processamento (800ms simulado) com `rootNavigator: true`
- Ao confirmar: cria `OrderEntity`, adiciona ao histórico, limpa carrinho, navega para tela de sucesso

### Tela de sucesso do checkout

- Animação de check com `flutter_animate` (escala com `elasticOut`)
- Card com data estimada de entrega (+2 dias)
- Botão "Acompanhar pedido" → `/profile/orders`
- Botão "Voltar ao início" → `/home`

### Perfil — Hub

**Usuário não logado:**
- Ilustração e CTA de login/cadastro
- Link "Continuar sem conta"

**Usuário logado:**
- `_IdentityCard`: card obsidian com avatar de iniciais em âmbar, nome, email, badge "Admin" (quando aplicável), data de membro
- `_ActiveOrderCard`: card com pulsing ring animado (via `flutter_animate`) quando há pedido em andamento — link direto para o detalhe
- Menu de navegação com contadores (ex: "Endereços (2)")
- `_LoyaltyCard`: barra de progresso de pontos de fidelidade com tier atual
- Sino no AppBar com badge de notificações não lidas
- Botão de logout que abre `LogoutConfirmationSheet`

### Meus pedidos

- Lista de pedidos do usuário autenticado
- **Filtros por status:** Todos · Em andamento · Entregues · Cancelados
- Cada card: número do pedido, thumbnail do primeiro item, status badge colorido, data, valor total
- Status com cores semânticas: âmbar (em andamento), verde (entregue), vermelho (cancelado)

### Detalhe do pedido

- Card de status com ícone e cor contextual
- **Timeline vertical:** eventos com estados visuais distintos
  - Verde + check: etapa concluída
  - Âmbar: etapa ativa
  - Cinza: etapa futura
- Seção de itens, endereço de entrega e informações de pagamento
- Botão "Cancelar pedido" (pedidos canceláveis) → AlertDialog de confirmação com `rootNavigator: true`
- Botão "Avaliar este pedido" (pedidos entregues não avaliados)

### Meus dados

- Visualização de nome, email, telefone e data de nascimento
- Modo de edição inline (toggle por botão no AppBar)
- Salva via `authProvider.notifier.updateProfile()`
- Aviso de conformidade LGPD

### Endereços

- Lista com destaque visual no endereço padrão (borda âmbar + badge "PADRÃO")
- `PopupMenuButton` em cada card: "Definir como padrão" / "Excluir"
- FAB (+) abre `AddressFormSheet` com auto-preenchimento via CEP

### Favoritos

- Grid 2 colunas com produtos salvos
- Botão de remover favorito overlay no card
- Estado vazio com CTA para navegar ao catálogo

### Avaliações

- `TabController` com duas abas: "Para avaliar (N)" / "Já avaliados (N)"
- Sheet de avaliação: picker de estrelas (1–5) + campo de texto

### Notificações

- Lista agrupada por período: Hoje · Ontem · Esta semana · Mais antigas
- Swipe para deletar (`Dismissible`)
- "Marcar todas como lidas" no AppBar
- Ícone colorido por tipo (pedido, promoção, sistema, avaliação)
- Badge de não lidas no sino do perfil

---

## Integrações externas

### CEP — Auto-preenchimento de endereço

**Arquivo:** `lib/core/services/cep_service.dart`

```
Usuário digita 8 dígitos
        ↓
[1ª tentativa] ViaCEP
  GET https://viacep.com.br/ws/{cep}/json/
        ↓ (falha ou erro)
[Fallback] BrasilAPI
  GET https://brasilapi.com.br/api/cep/v2/{cep}
        ↓
Preenche: logradouro, bairro, cidade, UF
Foca automaticamente no campo "Número"
```

**Por que dois providers?** Nenhuma API pública tem 100% de uptime. ViaCEP e BrasilAPI têm infraestruturas independentes. Timeout de 6s por tentativa evita travamento da UI.

**UX implementada:**
- Máscara automática `XXXXX-XXX` enquanto digita
- Spinner inline durante a busca
- Ícone ✓ verde quando encontrado, ⚠ vermelho quando não encontrado
- Dropdown de UF com todos os 27 estados (substitui campo de texto livre)
- Foco automático no campo "Número" após preenchimento

---

## Autenticação

### Arquitetura de auth

```dart
sealed class AuthState {
  AuthLoading          // estado inicial — carregando SharedPreferences
  Unauthenticated(errorMessage?)
  Authenticated(user)
}
```

**Por que sealed class?** Força o `when`/`switch` a cobrir todos os estados em tempo de compilação. Impossível esquecer de tratar o estado de loading ou erro.

### Login com email/senha

- Validação contra `mockCredentials` (lista em memória)
- Persiste email em `SharedPreferences` para reidratação na próxima sessão
- Mensagem de erro inline no formulário
- `AuthLoading` exibe `CircularProgressIndicator` no botão

### Google Sign-In

**Configuração:**
- `android/app/google-services.json` com projeto Firebase real (`raitocorp-e46a7`)
- Plugin `com.google.gms.google-services:4.4.4` no Gradle
- `clientId` configurado via meta tag no `web/index.html`
- URL scheme configurado no `ios/Runner/Info.plist`

**Fluxo Web — tratamento especial:**

O plugin `google_sign_in_web` usa fluxo token OAuth2. Neste fluxo, o `GoogleSignInAccount` pode retornar `email` vazio porque o SDK web não popula esses campos automaticamente.

```dart
if (kIsWeb && email.isEmpty) {
  final auth = await account.authentication;
  final res = await http.get(
    'https://people.googleapis.com/v1/people/me'
    '?personFields=names,emailAddresses',
    headers: {'Authorization': 'Bearer ${auth.accessToken}'},
  );
  // extrai email e displayName do JSON da People API
}
```

**Por que não usar Firebase Auth SDK completo?** O projeto não tem backend real. Adicionar `firebase_core` + `firebase_auth` aumentaria o bundle em ~2MB para benefício zero neste contexto.

### Auth guard no checkout

```dart
void _proceedToCheckout(BuildContext context, WidgetRef ref) {
  if (!ref.read(isLoggedInProvider)) {
    _showLoginRequiredSheet(context);
    return;
  }
  context.push('/checkout');
}
```

O redirect é preservado via query param: `/login?redirect=/checkout`

O carrinho **nunca** é limpo durante o fluxo de auth — persistido em Hive.

### Usuários de teste

| Email | Senha | Perfil |
|---|---|---|
| `camila@email.com` | `123456` | Completo — 2 pedidos, 2 endereços, favoritos, 890 pts |
| `maria@email.com` | `123456` | Básico — 1 pedido entregue, 1 endereço, 320 pts |
| `joao@email.com` | `123456` | Novo — sem pedidos, sem endereço, 0 pts |
| `admin@raito.com` | `admin` | Admin — badge especial, 9999 pts |

---

## Navegação

### GoRouter com ShellRoute

```
GoRouter
├── ShellRoute (MainShell — bottom nav persistente)
│   ├── /home
│   ├── /products
│   │   └── :id
│   ├── /consultant
│   ├── /cart
│   ├── /profile
│   ├── /profile/orders
│   │   └── :id
│   ├── /profile/favorites
│   ├── /profile/reviews
│   ├── /profile/addresses
│   ├── /profile/my-data
│   ├── /profile/notifications
│   ├── /checkout
│   └── /checkout/success/:orderId
├── /login    (sem bottom nav — flow isolado)
└── /register (sem bottom nav — flow isolado)
```

**Por que todas as rotas de perfil e checkout dentro do ShellRoute?**

Na versão inicial essas rotas estavam fora do shell. Resultado: a bottom nav desaparecia ao navegar para pedidos ou checkout. Decisão: tudo com bottom nav fica dentro do shell; só login e registro ficam fora (intencionalmente — sem nav dá sensação de "modo dedicado" de auth).

### Transições de página

```dart
_fadePage(220ms)   // tabs principais — fade indica troca lateral de contexto
_slidePage(280ms)  // sub-páginas — slide indica aprofundamento hierárquico
```

### Navigator e rootNavigator

O `ShellRoute` introduz um navigator interno. `showDialog` e `showModalBottomSheet` empilham no navigator raiz. Se `Navigator.pop` não usa `rootNavigator: true`, tenta fechar a página do shell em vez do dialog.

Solução aplicada em todos os dialogs e loading modals:
```dart
Navigator.of(context, rootNavigator: true).pop()
```

---

## Persistência de dados

### Hive — Carrinho

Carrinho serializado como JSON em `Box<String>`. Hive foi escolhido sobre SQLite porque:
- Suporta listas de tamanho variável sem schema relacional
- Performance superior para escritas frequentes (atualizações de quantidade)
- Compatível com web sem FFI

### SharedPreferences — Sessão de auth

Armazena apenas o `email` do usuário logado. Na inicialização do `AuthNotifier`, reidrata o estado reconstruindo o `UserEntity` a partir da lista mock.

---

## Dados mock

Todo o conteúdo do app é mockado em `lib/core/mock/`:

### Produtos (`mock_products.dart`)

8 luminários com dados completos:

| Produto | Preço | Temperatura | Ambiente |
|---|---|---|---|
| Pendente Moderno | R$ 890 | Quente (2700K) | Sala de jantar |
| Arandela Externa | R$ 459 | Quente (3000K) | Externo |
| Luminária de Mesa | R$ 289 | Neutro (4000K) | Escritório |
| Spot Embutido LED | R$ 149 | Neutro (4000K) | Múltiplos |
| Abajur de Cabeceira | R$ 349 | Quente (2700K) | Quarto |
| Fita LED 5m RGB | R$ 129 | Frio (6500K) | Múltiplos |
| Luminária de Chão | R$ 699 | Quente (2700K) | Sala |
| Kit Iluminação de Palco | R$ 2.890 | Frio (6000K) | Comercial |

### Pedidos (`mock_orders.dart`)

Distribuídos para demonstrar todos os estados:
- **Camila:** 1 confirmado (em andamento) + 1 entregue
- **Maria:** 1 entregue
- **Admin:** 1 cancelado

---

## Estrutura de pastas

```
lib/
├── main.dart                        # Hive + intl + ProviderScope
├── app.dart                         # MaterialApp + tema + router
│
├── core/
│   ├── mock/                        # dados de demonstração
│   ├── router/app_router.dart       # GoRouter — toda a árvore de rotas
│   ├── services/cep_service.dart    # ViaCEP + BrasilAPI
│   ├── theme/                       # tokens de design (cores, espaços, raios, tipografia)
│   └── widgets/                     # widgets compartilhados (shell, nav, product card)
│
├── shared/
│   └── extensions/number_extensions.dart   # formatCurrency() em pt_BR
│
└── features/
    ├── auth/          # login, registro, Google Sign-In, AuthState sealed
    ├── cart/          # carrinho Hive, checkout, tela de sucesso
    ├── consultant/    # consultor IA
    ├── home/          # home screen
    ├── products/      # catálogo, detalhe, filtros, busca
    └── profile/       # hub, pedidos, endereços, favoritos,
                       # avaliações, notificações, meus dados
```

---

## Como rodar

### Pré-requisitos

- Flutter SDK `^3.11.4`
- Para web: Chrome ou Edge

### Instalação

```bash
git clone <repo>
cd raitocorp_mobile
flutter pub get
```

### Executar

```bash
# Web (porta fixa necessária para Google Sign-In)
flutter run -d chrome --web-port=5000

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Google Sign-In — configuração por plataforma

**Web:**
- `http://localhost:5000` deve estar nas "Origens JavaScript autorizadas" do cliente OAuth no Google Cloud Console (projeto `raitocorp`)
- `clientId` já configurado no `web/index.html`

**Android:**
- `android/app/google-services.json` com o projeto `raitocorp-e46a7` já incluído

**iOS:**
- Substituir `ios/Runner/GoogleService-Info.plist` pelo arquivo real do Firebase iOS
- Atualizar o URL scheme no `Info.plist` com o `REVERSED_CLIENT_ID`

---

## Decisões técnicas

### Por que Riverpod e não Bloc ou Provider?

- **Bloc** é excelente mas verboso: para cada feature seriam necessários `Event`, `State`, `Bloc`, `BlocProvider`, `BlocBuilder`. `StateNotifier` + sealed class dá o mesmo resultado com metade do código.
- **Provider (package)** não tem tipagem forte para estados de loading/error e tem limitações de escopo. Riverpod resolve nativamente.
- Riverpod não depende de `BuildContext` para leitura — lógica de negócio completamente separada da UI.

### Por que GoRouter e não Navigator 2.0 manual ou AutoRoute?

- GoRouter é o router oficial recomendado pela equipe Flutter.
- `ShellRoute` para bottom nav persistente seria muito complexo com Navigator 2.0 manual.
- AutoRoute gera código — adiciona passo de build no CI e arquivos gerados no repositório.

### Por que Hive para o carrinho e não SQLite?

- Estrutura simples (lista com primitivos) — não justifica schema relacional.
- Hive funciona em web sem FFI (SQLite/sqflite não funciona na web sem workarounds).
- Um dos storages mais rápidos para Flutter em benchmarks de read/write.

### Por que não usar Firebase Auth SDK completo?

O projeto não tem backend real. `firebase_core` + `firebase_auth` aumentariam o bundle ~2MB e exigiriam configuração de regras de segurança sem benefício concreto. O `google_sign_in` isolado cobre OAuth2 com muito menos dependências.

### Por que sealed class para AuthState?

```dart
// Sem sealed class — fácil esquecer estados
if (state.isLoading) { ... }
if (state.isAuthenticated) { ... }
// E o erro? E o estado inicial?

// Com sealed class — exaustivo em compile time
switch (state) {
  case AuthLoading()                         => LoadingWidget(),
  case Unauthenticated(:final errorMessage)  => ErrorWidget(errorMessage),
  case Authenticated(:final user)            => HomeWidget(user),
}
```

### Por que todas as rotas de perfil ficam dentro do ShellRoute?

Rotas fora do `ShellRoute` não recebem o wrapper `MainShell`, então a bottom nav desaparece. A solução correta é colocar **todas** as rotas com bottom nav dentro do shell. Apenas login e registro ficam fora — intencionalmente, para criar a sensação de "modo dedicado" de autenticação.

### Por que `rootNavigator: true` nos dialogs e loading modals?

O `ShellRoute` introduz um navigator interno para suas páginas. `showDialog` empilha no navigator raiz. Se `Navigator.pop` não usa `rootNavigator: true`, ele tenta fechar a página do shell em vez do dialog — causando `!_debugLocked` assertion e navegação inesperada para a tela anterior.

### Por que duas APIs de CEP (ViaCEP + BrasilAPI)?

Nenhuma API pública tem 100% de uptime. ViaCEP e BrasilAPI têm infraestruturas independentes — a falha de uma raramente coincide com a da outra. Timeout de 6s por tentativa garante que o usuário não espera mais de 12s no pior caso.

### Por que buscar dados do usuário Google via People API na web?

O plugin `google_sign_in_web` usa o fluxo token OAuth2 (o fluxo `signIn()` é deprecated mas ainda funcional). Neste fluxo o SDK web não popula `email` e `displayName` no `GoogleSignInAccount` automaticamente. A solução é usar o `access_token` retornado para fazer uma chamada à People API — que já estava habilitada no projeto Firebase — e extrair os dados. Alternativa descartada: migrar para `renderButton` (mudaria completamente o fluxo de UX com botão nativo do Google).
