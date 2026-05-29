DOCUMENTAÇÃO TÉCNICA — ARQUITETURA E TECNOLOGIAS
Raitõ Corp Mobile — Aplicativo de E-commerce de Iluminação


SUMÁRIO

1 INTRODUÇÃO
2 VISÃO GERAL DA ARQUITETURA
3 CAMADA DE APRESENTAÇÃO (APLICATIVO FLUTTER)
   3.1 Organização do código: arquitetura orientada a funcionalidades
   3.2 Gerenciamento de estado
   3.3 Navegação
   3.4 Comunicação com o backend
   3.5 Persistência local
4 CAMADA DE NEGÓCIO (BACKEND EM N8N)
   4.1 O n8n como gateway de API
   4.2 Padrão canônico dos fluxos de trabalho
   4.3 Autenticação e segurança
   4.4 Restrições da instância e decisões delas decorrentes
5 CAMADA DE DADOS (POSTGRESQL)
6 SERVIÇOS EXTERNOS
   6.1 Cloudinary
   6.2 Google OAuth 2.0
   6.3 ModelScope
7 CONSULTOR DE ILUMINAÇÃO POR INTELIGÊNCIA ARTIFICIAL
   7.1 Recomendação por texto
   7.2 Recomendação por imagem
   7.3 Pré-visualização do produto no ambiente
8 TECNOLOGIAS UTILIZADAS
9 CONSIDERAÇÕES FINAIS


1 INTRODUÇÃO

Este documento descreve a arquitetura de software e as tecnologias empregadas no
desenvolvimento do Raitõ Corp Mobile, um aplicativo de comércio eletrônico
especializado na venda de produtos de iluminação. O objetivo é registrar, de
forma estruturada, como o sistema foi concebido e construído, servindo como base
para a apresentação final do trabalho.

O sistema é composto por três camadas independentes — aplicativo cliente,
servidor de regras de negócio e banco de dados — complementadas por serviços
externos de armazenamento de imagens, autenticação e inteligência artificial. A
principal característica arquitetural do projeto é o desacoplamento entre o
aplicativo e o banco de dados: o cliente não realiza nenhuma operação direta sobre
a base, comunicando-se exclusivamente por meio de uma interface de programação de
aplicações (API) baseada em requisições HTTP.


2 VISÃO GERAL DA ARQUITETURA

A arquitetura adotada é do tipo cliente-servidor em três camadas (three-tier),
descrita na Figura 1. O aplicativo Flutter constitui a camada de apresentação; a
plataforma de automação n8n constitui a camada de negócio (regras e orquestração);
e o sistema gerenciador de banco de dados PostgreSQL constitui a camada de dados.

Figura 1 — Visão geral da arquitetura

    +-------------------+      HTTPS / JSON       +----------------------+
    |  APLICATIVO       |  X-API-Key + JWT        |  N8N                 |
    |  (Flutter)        | ----------------------> |  (webhooks)          |
    |  Android / iOS /  |                         |  regras de negócio   |
    |  Web              | <---------------------- |  + autenticação SQL  |
    +-------------------+                         +----------+-----------+
                                                             | SQL
                                                             v
                                                  +----------------------+
                                                  |  POSTGRESQL          |
                                                  |  (persistência)      |
                                                  +----------------------+
                                                             ^
                          +----------------------------------+
                          | HTTP (a partir do n8n)
            +-------------+-------------+----------------------+
            v                           v                      v
      +-----------+              +-------------+        +--------------+
      | Cloudinary|              | ModelScope  |        | Google OAuth |
      | (imagens) |              | (IA)        |        | (login)      |
      +-----------+              +-------------+        +--------------+

Fonte: elaborado pelo autor.

O princípio que orienta toda a solução é a centralização das regras de negócio em
uma única camada. O aplicativo é deliberadamente desprovido de lógica sensível: não
conhece a estrutura do banco, não armazena segredos do servidor e não toma decisões
de autorização. Toda decisão dessa natureza ocorre no n8n. Essa separação permite
evoluir o backend sem necessidade de nova publicação do aplicativo nas lojas, além
de concentrar a manutenção em um ponto único.


3 CAMADA DE APRESENTAÇÃO (APLICATIVO FLUTTER)

O aplicativo foi desenvolvido com o framework Flutter, utilizando a linguagem Dart,
o que possibilita a geração de versões para Android, iOS e Web a partir de uma única
base de código.

3.1 Organização do código: arquitetura orientada a funcionalidades

Adotou-se a organização orientada a funcionalidades (feature-first), em
contraposição à organização por camadas técnicas (layer-first). Nessa abordagem,
cada funcionalidade do sistema é um diretório autocontido que reúne suas três
camadas internas, conforme o Quadro 1.

Quadro 1 — Estrutura interna de uma funcionalidade

    lib/features/<funcionalidade>/
      data/         repositórios — acesso à API por meio do ApiClient
      domain/       entidades — modelos de dados puros (fromJson / toJson)
      presentation/ providers (estado), screens (telas) e widgets

Fonte: elaborado pelo autor.

A justificativa para essa escolha é a coesão: toda alteração relativa a uma
funcionalidade (por exemplo, "pedidos") concentra-se em um único diretório,
reduzindo o acoplamento entre partes não relacionadas e facilitando a leitura, a
remoção e a refatoração do código. As funcionalidades implementadas são:
autenticação, perfil, endereços, catálogo, carrinho e checkout, pedidos,
favoritos, notificações, painel administrativo e consultor de iluminação por IA.

3.2 Gerenciamento de estado

O gerenciamento de estado utiliza a biblioteca Riverpod. O estado de cada
funcionalidade é modelado por meio de StateNotifier combinado com classes seladas
(sealed classes), o que torna o tratamento dos estados exaustivo em tempo de
compilação. Como exemplo, o estado de autenticação possui três variantes mutuamente
exclusivas — carregando, não autenticado e autenticado —, de modo que o compilador
exige o tratamento de todas elas, eliminando uma classe comum de erros.

A escolha do Riverpod, em detrimento de alternativas como Bloc e Provider,
fundamenta-se em dois fatores: a menor quantidade de código repetitivo (boilerplate)
e a independência em relação ao contexto da árvore de widgets (BuildContext), o que
permite separar de forma limpa a lógica de negócio da interface gráfica.

3.3 Navegação

A navegação emprega a biblioteca go_router, recurso oficial recomendado pela equipe
do Flutter. Utiliza-se uma rota do tipo ShellRoute para manter a barra de navegação
inferior persistente entre as principais telas. As telas de autenticação (login e
cadastro) permanecem intencionalmente fora dessa estrutura, conferindo a percepção
de um "modo dedicado" durante o processo de autenticação. O redirecionamento após o
login é preservado por meio de parâmetros de consulta na rota.

3.4 Comunicação com o backend

A comunicação com o backend é centralizada em um componente único, denominado
ApiClient. Esse componente é o único responsável por montar as requisições HTTP,
sendo encarregado de: (a) injetar o cabeçalho X-API-Key em todas as chamadas;
(b) injetar o token de autenticação (Bearer JWT) quando há sessão ativa; e
(c) converter as respostas de erro do servidor em exceções tipadas. Dessa forma, as
camadas superiores (repositórios, providers e telas) não manipulam detalhes do
protocolo HTTP. As entidades de domínio permanecem puras, com métodos fromJson e
toJson que correspondem exatamente ao formato de dados produzido pelos fluxos n8n.

3.5 Persistência local

O aplicativo mantém três conjuntos de dados localmente, conforme o Quadro 2.

Quadro 2 — Persistência local no aplicativo

    Dado                       Tecnologia                Motivação
    Carrinho de compras        Hive                      gravações frequentes;
                                                         compatível com a Web
    Sessão (token JWT)         flutter_secure_storage    armazenamento seguro
                                                         (Keystore / Keychain)
    Identificador da sessão    Hive                      retomada da conversa
    do consultor                                         entre aberturas

Fonte: elaborado pelo autor.

O carrinho é persistido de modo a sobreviver ao recarregamento do aplicativo e a
todo o fluxo de autenticação, garantindo que o usuário não perca sua seleção ao ser
solicitado a efetuar login no momento da finalização da compra.


4 CAMADA DE NEGÓCIO (BACKEND EM N8N)

4.1 O n8n como gateway de API

O n8n é uma plataforma de automação de fluxos de trabalho (workflow automation)
baseada em programação visual de baixo código (low-code). No presente projeto, ele
desempenha o papel de gateway de API e de camada de regras de negócio, expondo um
conjunto de webhooks que o aplicativo consome. O backend é composto por 33 fluxos de
trabalho, todos ativos e publicados em ambiente de produção, sendo cada fluxo
responsável por um endpoint da API. Os endpoints abrangem autenticação, perfil,
endereços, catálogo, favoritos, notificações, pedidos, administração e consultor de
IA.

4.2 Padrão canônico dos fluxos de trabalho

Todos os endpoints protegidos seguem a mesma topologia de nós, descrita na Figura 2.
A uniformidade é proposital: compreender um fluxo equivale a compreender os demais.

Figura 2 — Topologia padrão de um fluxo de trabalho

    Webhook (recebe a requisição)
        |
        v
    Condição: chave de API válida?  --- não --->  Resposta 401
        | sim
        v
    PostgreSQL (executeQuery)
        |   valida o token em SQL e executa a regra de negócio
        |   em uma única expressão de tabela comum (CTE),
        |   retornando { código de status, corpo }
        v
    Condição: código de status == 200?  --- não --->  Resposta de erro (422/404/401)
        | sim
        v
    Resposta 200 (corpo)

Fonte: elaborado pelo autor.

Um aspecto relevante de desempenho e de integridade é a concentração da regra de
negócio em uma única consulta SQL, estruturada por meio de expressões de tabela
comuns (Common Table Expressions). No fluxo de criação de pedido, por exemplo, uma
mesma consulta valida o token, congela um retrato (snapshot) do endereço de entrega,
gera o identificador do pedido, insere o pedido, seus itens, sua linha do tempo de
status e a notificação correspondente, e monta a resposta — tudo de forma atômica.

4.3 Autenticação e segurança

A autenticação combina duas camadas. A primeira é uma chave de API estática
(X-API-Key), embutida no aplicativo, cuja função é restringir o acesso aos webhooks
e permitir limitação de taxa; ela não identifica o usuário. A segunda é um token do
tipo JSON Web Token (JWT), assinado com o algoritmo HMAC-SHA256 (HS256), emitido no
momento do login e com validade de sete dias; é ele que identifica o usuário.

A verificação tanto da senha quanto do token ocorre integralmente em SQL, por meio
da extensão pgcrypto do PostgreSQL. As senhas são armazenadas com o algoritmo bcrypt
(fator de custo 12). A validação do JWT consiste em recalcular a assinatura
HMAC-SHA256 sobre o cabeçalho e a carga útil, compará-la com a assinatura recebida,
decodificar a carga útil (codificada em base64url) e verificar a data de expiração.
Apenas após essa validação o identificador do usuário é utilizado nas operações.

4.4 Restrições da instância e decisões delas decorrentes

A instância de n8n utilizada possui configurações de segurança restritivas
(hardened), que impuseram decisões de projeto específicas, sintetizadas no Quadro 3.

Quadro 3 — Restrições da instância e soluções adotadas

    Restrição                              Solução adotada
    Bloqueio de require('crypto') e do     Autenticação (bcrypt e JWT) feita
    acesso a variáveis de ambiente em      inteiramente em SQL, via pgcrypto.
    nós de código.

    Parâmetro de substituição da consulta  Uso de um valor sentinela para campos
    é tratado como texto separado por      vazios e de vetor (array) para valores
    vírgula, descartando valores vazios.   que contêm vírgulas.

    Parâmetros dinâmicos de rota (:id)      Operações de escrita usam método POST
    exigem identificador interno na URL.   com o identificador no corpo; leituras
                                           por id usam parâmetro de consulta (?id=).

    Nós de IA (langchain) são descartados   O consultor de IA é implementado por
    na importação via SDK.                  requisições HTTP diretas aos modelos.

Fonte: elaborado pelo autor.


5 CAMADA DE DADOS (POSTGRESQL)

A persistência é realizada em um banco de dados relacional PostgreSQL, acessado
exclusivamente pelos fluxos de trabalho do n8n. São utilizadas as extensões pgcrypto
(geração de identificadores únicos, funções de hash e criptografia) e citext
(tratamento de endereços de correio eletrônico sem distinção entre maiúsculas e
minúsculas). As principais entidades do modelo de dados estão listadas no Quadro 4.

Quadro 4 — Entidades do banco de dados

    Tabela            Finalidade
    users             usuários (credenciais, perfil, pontos de fidelidade)
    addresses         endereços de entrega
    products          catálogo de produtos de iluminação
    reviews           avaliações de produtos (com foto)
    orders            pedidos
    order_items       itens de cada pedido (com retrato dos dados na compra)
    order_timeline    eventos de status de cada pedido
    user_favorites    produtos favoritados por usuário
    notifications     notificações do usuário
    chat_sessions     sessões de conversa com o consultor de IA
    chat_messages     mensagens trocadas com o consultor de IA
    preview_usage     controle de uso diário da pré-visualização por IA

Fonte: elaborado pelo autor.

Destaca-se o uso de retratos de dados (snapshots) nos pedidos: tanto o endereço de
entrega quanto os dados dos itens são congelados no momento da compra, de modo que
alterações futuras no cadastro do usuário ou no catálogo não modifiquem pedidos
históricos.


6 SERVIÇOS EXTERNOS

6.1 Cloudinary

O Cloudinary é utilizado para o armazenamento e a entrega de imagens. O envio é
feito por meio de uma predefinição não assinada (unsigned preset), o que dispensa o
tráfego de segredos. O serviço atende às imagens de produtos (cadastradas no painel
administrativo), às fotos das avaliações, às fotos do ambiente enviadas ao consultor
e às imagens geradas pela pré-visualização por IA.

6.2 Google OAuth 2.0

O serviço de identidade do Google é empregado para autenticação social. O
aplicativo obtém um token de identidade (id_token) do Google e o encaminha ao
backend, que o valida e o converte em um JWT próprio do sistema. Na versão Web,
recorre-se complementarmente à People API para a obtenção do nome e do endereço de
correio eletrônico do usuário.

6.3 ModelScope

A ModelScope, plataforma de inferência de modelos de inteligência artificial, provê
os modelos que sustentam o consultor de iluminação. Optou-se por essa plataforma em
razão de duas limitações encontradas: a impossibilidade de importar nós de IA na
instância de n8n e as cotas restritivas de uso gratuito de outros provedores. Um
único token de acesso atende aos três modelos utilizados, descritos na seção 7.


7 CONSULTOR DE ILUMINAÇÃO POR INTELIGÊNCIA ARTIFICIAL

O consultor de iluminação constitui o principal diferencial do aplicativo. Trata-se
de um assistente, restrito ao domínio de iluminação, que opera em três modalidades,
sintetizadas no Quadro 5.

Quadro 5 — Modalidades do consultor de IA

    Modalidade       Endpoint                  Modelo                    Função
    Texto            /consultant/message       Qwen2.5-72B-Instruct      conversação
    Imagem           /consultant/image         Qwen2.5-VL-72B-Instruct   visão
    Pré-visualização /consultant/preview       Qwen-Image-Edit-2509      edição de
                                                                         imagem

Fonte: elaborado pelo autor.

7.1 Recomendação por texto

Na modalidade de texto, o fluxo recupera o histórico recente da conversa e um
resumo do catálogo (incluindo atributos técnicos como fluxo luminoso, temperatura de
cor e ambientes ideais) e os fornece ao modelo de linguagem. A restrição ao tema de
iluminação é garantida por instrução no prompt de sistema. Os identificadores de
produtos sugeridos pelo modelo são validados contra o catálogo antes de serem
retornados ao aplicativo.

7.2 Recomendação por imagem

Na modalidade de imagem, o usuário envia uma fotografia do ambiente, opcionalmente
acompanhada de um texto. O modelo de visão classifica o ambiente segundo o cômodo, a
temperatura de cor e a intensidade desejadas; em seguida, uma consulta de pontuação
(scoring) seleciona os três produtos mais adequados do catálogo.

7.3 Pré-visualização do produto no ambiente

Na modalidade de pré-visualização, o sistema gera uma imagem que simula o produto
instalado no ambiente do usuário, com a iluminação característica daquele produto.
Em razão de a geração de imagem demandar de dois a quatro minutos — tempo superior
ao limite de conexão imposto pela camada de borda da rede —, adotou-se um modelo de
processamento assíncrono com sondagem (polling), descrito na Figura 3.

Figura 3 — Processamento assíncrono da pré-visualização

    1a chamada (sem identificador de tarefa):
        valida autenticação, limite diário e fontes
        submete a tarefa ao modelo
        responde imediatamente com o identificador da tarefa
              |
              v  (o aplicativo reenvia o identificador a cada 30 segundos)
    Sondagem (com identificador de tarefa):
        consulta o estado da tarefa
            concluída  -> armazena a imagem e a retorna
            falhou     -> ressubmete e devolve novo identificador
            em curso   -> informa que ainda está processando

Fonte: elaborado pelo autor.

Aplica-se um limite de duas pré-visualizações por usuário por dia, computado no
momento da submissão e efetivamente registrado apenas quando a imagem é gerada com
sucesso.


8 TECNOLOGIAS UTILIZADAS

O Quadro 6 consolida as principais tecnologias empregadas no projeto, organizadas
por camada.

Quadro 6 — Tecnologias por camada

    Camada / função          Tecnologia
    Linguagem do aplicativo  Dart
    Framework do aplicativo  Flutter
    Gerenciamento de estado  Riverpod
    Navegação                go_router
    Persistência local       Hive; flutter_secure_storage
    Notificações locais      flutter_local_notifications
    Backend / regras         n8n
    Banco de dados           PostgreSQL (extensões pgcrypto e citext)
    Autenticação             JWT (HS256); bcrypt; Google OAuth 2.0
    Armazenamento de imagens Cloudinary
    Inteligência artificial  ModelScope (modelos Qwen2.5-72B, Qwen2.5-VL-72B
                             e Qwen-Image-Edit)
    Serviços de apoio        ViaCEP e BrasilAPI (consulta de CEP)

Fonte: elaborado pelo autor.


9 CONSIDERAÇÕES FINAIS

A arquitetura proposta atingiu o objetivo de separar responsabilidades em camadas
bem definidas, concentrando as regras de negócio no backend e mantendo o aplicativo
restrito à apresentação e à experiência do usuário. O uso do n8n como camada de
negócio mostrou-se adequado ao contexto acadêmico, por dispensar a manutenção de um
servidor de aplicação tradicional e por oferecer um ambiente visual e versionável
para a orquestração de fluxos. As restrições da instância utilizada, embora tenham
exigido soluções específicas — sobretudo a realização da autenticação em SQL e a
implementação da inteligência artificial por requisições HTTP diretas —, foram
contornadas sem prejuízo às funcionalidades previstas.

Cabe registrar que algumas escolhas foram orientadas pelo caráter acadêmico do
trabalho, com destaque para o armazenamento de segredos diretamente nos fluxos e a
assinatura do aplicativo com chave de depuração. Tais decisões priorizaram o
funcionamento integral do sistema e deveriam ser revistas em um eventual cenário de
produção comercial.
