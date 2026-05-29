# Gera docs/ARQUITETURA.docx a partir do conteudo de ARQUITETURA.md, com
# formatacao no padrao ABNT, via automacao COM do Word.
# Uso: powershell -ExecutionPolicy Bypass -File tool\gen_arquitetura_docx.ps1

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$out  = Join-Path $root 'docs\ARQUITETURA.docx'

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()

# ---- Configuracao da pagina (margens ABNT: esq/sup 3cm, dir/inf 2cm) ----
$cm = 28.3464567  # 1 cm em pontos
$ps = $doc.PageSetup
$ps.TopMargin    = 3 * $cm
$ps.BottomMargin = 2 * $cm
$ps.LeftMargin   = 3 * $cm
$ps.RightMargin  = 2 * $cm

# ---- Estilo base: Arial 12, entrelinha 1,5, justificado ----
$normal = $doc.Styles.Item("Normal")
$normal.Font.Name = "Arial"
$normal.Font.Size = 12
$normal.ParagraphFormat.LineSpacingRule = 1   # wdLineSpace1pt5
$normal.ParagraphFormat.SpaceAfter = 6
$normal.ParagraphFormat.Alignment = 3         # justificado

$sel = $word.Selection

# Constantes de alinhamento
$alignLeft = 0; $alignCenter = 1; $alignJustify = 3

function Add-Heading($text, $level) {
    $sel.Style = $doc.Styles.Item("Heading $level")
    $sel.ParagraphFormat.Alignment = $alignLeft
    $sel.Font.Name = "Arial"
    $sel.Font.Color = 0  # preto (ABNT nao usa azul)
    if ($level -eq 1) { $sel.Font.Size = 12; $sel.Font.Bold = $true; $sel.Font.AllCaps = $true }
    elseif ($level -eq 2) { $sel.Font.Size = 12; $sel.Font.Bold = $true; $sel.Font.AllCaps = $false }
    else { $sel.Font.Size = 12; $sel.Font.Bold = $false; $sel.Font.AllCaps = $false }
    $sel.TypeText($text)
    $sel.TypeParagraph()
    $sel.Style = $doc.Styles.Item("Normal")
    $sel.Font.AllCaps = $false
    $sel.Font.Bold = $false
}

function Add-Para($text) {
    $sel.Style = $doc.Styles.Item("Normal")
    $sel.ParagraphFormat.Alignment = $alignJustify
    $sel.ParagraphFormat.FirstLineIndent = 1.25 * $cm
    $sel.TypeText($text)
    $sel.TypeParagraph()
    $sel.ParagraphFormat.FirstLineIndent = 0
}

function Add-Caption($text) {
    # Legenda acima de figura/quadro: Arial 10, centralizado, sem recuo
    $sel.Style = $doc.Styles.Item("Normal")
    $sel.ParagraphFormat.Alignment = $alignCenter
    $sel.ParagraphFormat.FirstLineIndent = 0
    $sel.Font.Size = 10
    $sel.TypeText($text)
    $sel.TypeParagraph()
    $sel.Font.Size = 12
}

function Add-Source($text) {
    # "Fonte:" abaixo, Arial 10, centralizado
    $sel.Style = $doc.Styles.Item("Normal")
    $sel.ParagraphFormat.Alignment = $alignCenter
    $sel.ParagraphFormat.FirstLineIndent = 0
    $sel.Font.Size = 10
    $sel.TypeText($text)
    $sel.TypeParagraph()
    $sel.Font.Size = 12
}

function Add-Mono($lines) {
    # Bloco monoespacado (figuras ASCII), centralizado, Consolas 9
    $sel.Style = $doc.Styles.Item("Normal")
    $sel.ParagraphFormat.Alignment = $alignLeft
    $sel.ParagraphFormat.FirstLineIndent = 0
    $sel.Font.Name = "Consolas"
    $sel.Font.Size = 9
    $sel.ParagraphFormat.LineSpacingRule = 0  # simples
    foreach ($l in $lines) {
        $sel.TypeText($l)
        $sel.TypeText([char]11)  # quebra de linha leve (mesmo paragrafo)
    }
    $sel.TypeParagraph()
    $sel.Font.Name = "Arial"
    $sel.Font.Size = 12
    $sel.ParagraphFormat.LineSpacingRule = 1
}

function Add-Table($rows) {
    # $rows = array de arrays (linhas x colunas). 1a linha = cabecalho.
    $nRows = $rows.Count
    $nCols = $rows[0].Count
    $rng = $sel.Range
    $tbl = $doc.Tables.Add($rng, $nRows, $nCols)
    $tbl.Borders.Enable = $true
    $tbl.Range.Font.Name = "Arial"
    $tbl.Range.Font.Size = 10
    $tbl.Range.ParagraphFormat.LineSpacingRule = 0
    $tbl.Range.ParagraphFormat.FirstLineIndent = 0
    $tbl.Range.ParagraphFormat.SpaceAfter = 2
    $tbl.Range.ParagraphFormat.Alignment = $alignLeft
    for ($r = 0; $r -lt $nRows; $r++) {
        for ($c = 0; $c -lt $nCols; $c++) {
            $cell = $tbl.Cell($r + 1, $c + 1)
            $cell.Range.Text = [string]$rows[$r][$c]
            if ($r -eq 0) { $cell.Range.Font.Bold = $true }
        }
    }
    # move cursor para depois da tabela
    $word.Selection.EndKey(6) | Out-Null  # wdStory
    $sel.Style = $doc.Styles.Item("Normal")
    $sel.Font.Name = "Arial"; $sel.Font.Size = 12
    $sel.TypeParagraph()
}

# ============================ CONTEUDO ============================

# Titulo do documento
$sel.ParagraphFormat.Alignment = $alignCenter
$sel.Font.Bold = $true; $sel.Font.Size = 14
$sel.TypeText("DOCUMENTACAO TECNICA - ARQUITETURA E TECNOLOGIAS")
$sel.TypeParagraph()
$sel.Font.Size = 12
$sel.TypeText("Raito Corp Mobile - Aplicativo de E-commerce de Iluminacao")
$sel.TypeParagraph(); $sel.TypeParagraph()
$sel.Font.Bold = $false
$sel.Style = $doc.Styles.Item("Normal")

# ---- SUMARIO (manual, simples) ----
Add-Heading "SUMARIO" 1
$sumario = @(
  "1 INTRODUCAO",
  "2 VISAO GERAL DA ARQUITETURA",
  "3 CAMADA DE APRESENTACAO (APLICATIVO FLUTTER)",
  "4 CAMADA DE NEGOCIO (BACKEND EM N8N)",
  "5 CAMADA DE DADOS (POSTGRESQL)",
  "6 SERVICOS EXTERNOS",
  "7 CONSULTOR DE ILUMINACAO POR INTELIGENCIA ARTIFICIAL",
  "8 TECNOLOGIAS UTILIZADAS",
  "9 CONSIDERACOES FINAIS"
)
foreach ($s in $sumario) {
    $sel.Style = $doc.Styles.Item("Normal")
    $sel.ParagraphFormat.Alignment = $alignLeft
    $sel.ParagraphFormat.FirstLineIndent = 0
    $sel.TypeText($s); $sel.TypeParagraph()
}
$sel.InsertBreak(7)  # wdPageBreak

# ---- 1 INTRODUCAO ----
Add-Heading "1 INTRODUCAO" 1
Add-Para "Este documento descreve a arquitetura de software e as tecnologias empregadas no desenvolvimento do Raito Corp Mobile, um aplicativo de comercio eletronico especializado na venda de produtos de iluminacao. O objetivo e registrar, de forma estruturada, como o sistema foi concebido e construido, servindo como base para a apresentacao final do trabalho."
Add-Para "O sistema e composto por tres camadas independentes - aplicativo cliente, servidor de regras de negocio e banco de dados -, complementadas por servicos externos de armazenamento de imagens, autenticacao e inteligencia artificial. A principal caracteristica arquitetural do projeto e o desacoplamento entre o aplicativo e o banco de dados: o cliente nao realiza nenhuma operacao direta sobre a base, comunicando-se exclusivamente por meio de uma interface de programacao de aplicacoes (API) baseada em requisicoes HTTP."

# ---- 2 VISAO GERAL ----
Add-Heading "2 VISAO GERAL DA ARQUITETURA" 1
Add-Para "A arquitetura adotada e do tipo cliente-servidor em tres camadas (three-tier), descrita na Figura 1. O aplicativo Flutter constitui a camada de apresentacao; a plataforma de automacao n8n constitui a camada de negocio (regras e orquestracao); e o sistema gerenciador de banco de dados PostgreSQL constitui a camada de dados."
Add-Caption "Figura 1 - Visao geral da arquitetura"
Add-Mono @(
"  +-----------------+     HTTPS / JSON       +---------------------+",
"  |  APLICATIVO     |  X-API-Key + JWT       |  N8N                |",
"  |  (Flutter)      | ---------------------> |  (webhooks)         |",
"  |  Android / iOS  |                        |  regras de negocio  |",
"  |  / Web          | <--------------------- |  + autenticacao SQL |",
"  +-----------------+                        +----------+----------+",
"                                                        | SQL",
"                                                        v",
"                                             +---------------------+",
"                                             |  POSTGRESQL         |",
"                                             |  (persistencia)     |",
"                                             +---------------------+",
"                                                        ^",
"                    +-----------------------------------+",
"                    | HTTP (a partir do n8n)",
"          +---------+---------+----------------------+",
"          v                   v                      v",
"    +-----------+      +-------------+        +--------------+",
"    | Cloudinary|      | ModelScope  |        | Google OAuth |",
"    | (imagens) |      | (IA)        |        | (login)      |",
"    +-----------+      +-------------+        +--------------+"
)
Add-Source "Fonte: elaborado pelo autor."
Add-Para "O principio que orienta toda a solucao e a centralizacao das regras de negocio em uma unica camada. O aplicativo e deliberadamente desprovido de logica sensivel: nao conhece a estrutura do banco, nao armazena segredos do servidor e nao toma decisoes de autorizacao. Toda decisao dessa natureza ocorre no n8n. Essa separacao permite evoluir o backend sem necessidade de nova publicacao do aplicativo nas lojas, alem de concentrar a manutencao em um ponto unico."

# ---- 3 APRESENTACAO ----
Add-Heading "3 CAMADA DE APRESENTACAO (APLICATIVO FLUTTER)" 1
Add-Para "O aplicativo foi desenvolvido com o framework Flutter, utilizando a linguagem Dart, o que possibilita a geracao de versoes para Android, iOS e Web a partir de uma unica base de codigo."
Add-Heading "3.1 Organizacao do codigo: arquitetura orientada a funcionalidades" 2
Add-Para "Adotou-se a organizacao orientada a funcionalidades (feature-first), em contraposicao a organizacao por camadas tecnicas (layer-first). Nessa abordagem, cada funcionalidade do sistema e um diretorio autocontido que reune suas tres camadas internas, conforme o Quadro 1."
Add-Caption "Quadro 1 - Estrutura interna de uma funcionalidade"
Add-Table @(
  @("Camada","Conteudo"),
  @("data","repositorios - acesso a API por meio do ApiClient"),
  @("domain","entidades - modelos de dados puros (fromJson / toJson)"),
  @("presentation","providers (estado), screens (telas) e widgets")
)
Add-Source "Fonte: elaborado pelo autor."
Add-Para "A justificativa para essa escolha e a coesao: toda alteracao relativa a uma funcionalidade (por exemplo, 'pedidos') concentra-se em um unico diretorio, reduzindo o acoplamento entre partes nao relacionadas e facilitando a leitura, a remocao e a refatoracao do codigo. As funcionalidades implementadas sao: autenticacao, perfil, enderecos, catalogo, carrinho e checkout, pedidos, favoritos, notificacoes, painel administrativo e consultor de iluminacao por IA."
Add-Heading "3.2 Gerenciamento de estado" 2
Add-Para "O gerenciamento de estado utiliza a biblioteca Riverpod. O estado de cada funcionalidade e modelado por meio de StateNotifier combinado com classes seladas (sealed classes), o que torna o tratamento dos estados exaustivo em tempo de compilacao. Como exemplo, o estado de autenticacao possui tres variantes mutuamente exclusivas - carregando, nao autenticado e autenticado -, de modo que o compilador exige o tratamento de todas elas, eliminando uma classe comum de erros."
Add-Para "A escolha do Riverpod, em detrimento de alternativas como Bloc e Provider, fundamenta-se em dois fatores: a menor quantidade de codigo repetitivo (boilerplate) e a independencia em relacao ao contexto da arvore de widgets (BuildContext), o que permite separar de forma limpa a logica de negocio da interface grafica."
Add-Heading "3.3 Navegacao" 2
Add-Para "A navegacao emprega a biblioteca go_router, recurso oficial recomendado pela equipe do Flutter. Utiliza-se uma rota do tipo ShellRoute para manter a barra de navegacao inferior persistente entre as principais telas. As telas de autenticacao (login e cadastro) permanecem intencionalmente fora dessa estrutura, conferindo a percepcao de um 'modo dedicado' durante o processo de autenticacao. O redirecionamento apos o login e preservado por meio de parametros de consulta na rota."
Add-Heading "3.4 Comunicacao com o backend" 2
Add-Para "A comunicacao com o backend e centralizada em um componente unico, denominado ApiClient. Esse componente e o unico responsavel por montar as requisicoes HTTP, sendo encarregado de: (a) injetar o cabecalho X-API-Key em todas as chamadas; (b) injetar o token de autenticacao (Bearer JWT) quando ha sessao ativa; e (c) converter as respostas de erro do servidor em excecoes tipadas. Dessa forma, as camadas superiores (repositorios, providers e telas) nao manipulam detalhes do protocolo HTTP. As entidades de dominio permanecem puras, com metodos fromJson e toJson que correspondem exatamente ao formato de dados produzido pelos fluxos n8n."
Add-Heading "3.5 Persistencia local" 2
Add-Para "O aplicativo mantem tres conjuntos de dados localmente, conforme o Quadro 2."
Add-Caption "Quadro 2 - Persistencia local no aplicativo"
Add-Table @(
  @("Dado","Tecnologia","Motivacao"),
  @("Carrinho de compras","Hive","gravacoes frequentes; compativel com a Web"),
  @("Sessao (token JWT)","flutter_secure_storage","armazenamento seguro (Keystore / Keychain)"),
  @("Identificador da sessao do consultor","Hive","retomada da conversa entre aberturas")
)
Add-Source "Fonte: elaborado pelo autor."
Add-Para "O carrinho e persistido de modo a sobreviver ao recarregamento do aplicativo e a todo o fluxo de autenticacao, garantindo que o usuario nao perca sua selecao ao ser solicitado a efetuar login no momento da finalizacao da compra."

# ---- 4 NEGOCIO ----
Add-Heading "4 CAMADA DE NEGOCIO (BACKEND EM N8N)" 1
Add-Heading "4.1 O n8n como gateway de API" 2
Add-Para "O n8n e uma plataforma de automacao de fluxos de trabalho (workflow automation) baseada em programacao visual de baixo codigo (low-code). No presente projeto, ele desempenha o papel de gateway de API e de camada de regras de negocio, expondo um conjunto de webhooks que o aplicativo consome. O backend e composto por 33 fluxos de trabalho, todos ativos e publicados em ambiente de producao, sendo cada fluxo responsavel por um endpoint da API. Os endpoints abrangem autenticacao, perfil, enderecos, catalogo, favoritos, notificacoes, pedidos, administracao e consultor de IA."
Add-Heading "4.2 Padrao canonico dos fluxos de trabalho" 2
Add-Para "Todos os endpoints protegidos seguem a mesma topologia de nos, descrita na Figura 2. A uniformidade e proposital: compreender um fluxo equivale a compreender os demais."
Add-Caption "Figura 2 - Topologia padrao de um fluxo de trabalho"
Add-Mono @(
"  Webhook (recebe a requisicao)",
"      |",
"      v",
"  Condicao: chave de API valida?  -- nao -->  Resposta 401",
"      | sim",
"      v",
"  PostgreSQL (executeQuery)",
"      |   valida o token em SQL e executa a regra de negocio",
"      |   em uma unica expressao de tabela comum (CTE),",
"      |   retornando { codigo de status, corpo }",
"      v",
"  Condicao: codigo == 200?  -- nao -->  Resposta de erro (422/404/401)",
"      | sim",
"      v",
"  Resposta 200 (corpo)"
)
Add-Source "Fonte: elaborado pelo autor."
Add-Para "Um aspecto relevante de desempenho e de integridade e a concentracao da regra de negocio em uma unica consulta SQL, estruturada por meio de expressoes de tabela comuns (Common Table Expressions). No fluxo de criacao de pedido, por exemplo, uma mesma consulta valida o token, congela um retrato (snapshot) do endereco de entrega, gera o identificador do pedido, insere o pedido, seus itens, sua linha do tempo de status e a notificacao correspondente, e monta a resposta - tudo de forma atomica."
Add-Heading "4.3 Autenticacao e seguranca" 2
Add-Para "A autenticacao combina duas camadas. A primeira e uma chave de API estatica (X-API-Key), embutida no aplicativo, cuja funcao e restringir o acesso aos webhooks e permitir limitacao de taxa; ela nao identifica o usuario. A segunda e um token do tipo JSON Web Token (JWT), assinado com o algoritmo HMAC-SHA256 (HS256), emitido no momento do login e com validade de sete dias; e ele que identifica o usuario."
Add-Para "A verificacao tanto da senha quanto do token ocorre integralmente em SQL, por meio da extensao pgcrypto do PostgreSQL. As senhas sao armazenadas com o algoritmo bcrypt (fator de custo 12). A validacao do JWT consiste em recalcular a assinatura HMAC-SHA256 sobre o cabecalho e a carga util, compara-la com a assinatura recebida, decodificar a carga util (codificada em base64url) e verificar a data de expiracao. Apenas apos essa validacao o identificador do usuario e utilizado nas operacoes."
Add-Heading "4.4 Restricoes da instancia e decisoes delas decorrentes" 2
Add-Para "A instancia de n8n utilizada possui configuracoes de seguranca restritivas (hardened), que impuseram decisoes de projeto especificas, sintetizadas no Quadro 3."
Add-Caption "Quadro 3 - Restricoes da instancia e solucoes adotadas"
Add-Table @(
  @("Restricao","Solucao adotada"),
  @("Bloqueio de require('crypto') e do acesso a variaveis de ambiente em nos de codigo.","Autenticacao (bcrypt e JWT) feita inteiramente em SQL, via pgcrypto."),
  @("Parametro de substituicao da consulta e tratado como texto separado por virgula, descartando valores vazios.","Uso de um valor sentinela para campos vazios e de vetor (array) para valores que contem virgulas."),
  @("Parametros dinamicos de rota (:id) exigem identificador interno na URL.","Operacoes de escrita usam POST com o identificador no corpo; leituras por id usam parametro de consulta (?id=)."),
  @("Nos de IA (langchain) sao descartados na importacao via SDK.","O consultor de IA e implementado por requisicoes HTTP diretas aos modelos.")
)
Add-Source "Fonte: elaborado pelo autor."

# ---- 5 DADOS ----
Add-Heading "5 CAMADA DE DADOS (POSTGRESQL)" 1
Add-Para "A persistencia e realizada em um banco de dados relacional PostgreSQL, acessado exclusivamente pelos fluxos de trabalho do n8n. Sao utilizadas as extensoes pgcrypto (geracao de identificadores unicos, funcoes de hash e criptografia) e citext (tratamento de enderecos de correio eletronico sem distincao entre maiusculas e minusculas). As principais entidades do modelo de dados estao listadas no Quadro 4."
Add-Caption "Quadro 4 - Entidades do banco de dados"
Add-Table @(
  @("Tabela","Finalidade"),
  @("users","usuarios (credenciais, perfil, pontos de fidelidade)"),
  @("addresses","enderecos de entrega"),
  @("products","catalogo de produtos de iluminacao"),
  @("reviews","avaliacoes de produtos (com foto)"),
  @("orders","pedidos"),
  @("order_items","itens de cada pedido (com retrato dos dados na compra)"),
  @("order_timeline","eventos de status de cada pedido"),
  @("user_favorites","produtos favoritados por usuario"),
  @("notifications","notificacoes do usuario"),
  @("chat_sessions","sessoes de conversa com o consultor de IA"),
  @("chat_messages","mensagens trocadas com o consultor de IA"),
  @("preview_usage","controle de uso diario da pre-visualizacao por IA")
)
Add-Source "Fonte: elaborado pelo autor."
Add-Para "Destaca-se o uso de retratos de dados (snapshots) nos pedidos: tanto o endereco de entrega quanto os dados dos itens sao congelados no momento da compra, de modo que alteracoes futuras no cadastro do usuario ou no catalogo nao modifiquem pedidos historicos."

# ---- 6 SERVICOS EXTERNOS ----
Add-Heading "6 SERVICOS EXTERNOS" 1
Add-Heading "6.1 Cloudinary" 2
Add-Para "O Cloudinary e utilizado para o armazenamento e a entrega de imagens. O envio e feito por meio de uma predefinicao nao assinada (unsigned preset), o que dispensa o trafego de segredos. O servico atende as imagens de produtos (cadastradas no painel administrativo), as fotos das avaliacoes, as fotos do ambiente enviadas ao consultor e as imagens geradas pela pre-visualizacao por IA."
Add-Heading "6.2 Google OAuth 2.0" 2
Add-Para "O servico de identidade do Google e empregado para autenticacao social. O aplicativo obtem um token de identidade (id_token) do Google e o encaminha ao backend, que o valida e o converte em um JWT proprio do sistema. Na versao Web, recorre-se complementarmente a People API para a obtencao do nome e do endereco de correio eletronico do usuario."
Add-Heading "6.3 ModelScope" 2
Add-Para "A ModelScope, plataforma de inferencia de modelos de inteligencia artificial, prove os modelos que sustentam o consultor de iluminacao. Optou-se por essa plataforma em razao de duas limitacoes encontradas: a impossibilidade de importar nos de IA na instancia de n8n e as cotas restritivas de uso gratuito de outros provedores. Um unico token de acesso atende aos tres modelos utilizados, descritos na secao 7."

# ---- 7 CONSULTOR IA ----
Add-Heading "7 CONSULTOR DE ILUMINACAO POR INTELIGENCIA ARTIFICIAL" 1
Add-Para "O consultor de iluminacao constitui o principal diferencial do aplicativo. Trata-se de um assistente, restrito ao dominio de iluminacao, que opera em tres modalidades, sintetizadas no Quadro 5."
Add-Caption "Quadro 5 - Modalidades do consultor de IA"
Add-Table @(
  @("Modalidade","Endpoint","Modelo","Funcao"),
  @("Texto","/consultant/message","Qwen2.5-72B-Instruct","conversacao"),
  @("Imagem","/consultant/image","Qwen2.5-VL-72B-Instruct","visao"),
  @("Pre-visualizacao","/consultant/preview","Qwen-Image-Edit-2509","edicao de imagem")
)
Add-Source "Fonte: elaborado pelo autor."
Add-Heading "7.1 Recomendacao por texto" 2
Add-Para "Na modalidade de texto, o fluxo recupera o historico recente da conversa e um resumo do catalogo (incluindo atributos tecnicos como fluxo luminoso, temperatura de cor e ambientes ideais) e os fornece ao modelo de linguagem. A restricao ao tema de iluminacao e garantida por instrucao no prompt de sistema. Os identificadores de produtos sugeridos pelo modelo sao validados contra o catalogo antes de serem retornados ao aplicativo."
Add-Heading "7.2 Recomendacao por imagem" 2
Add-Para "Na modalidade de imagem, o usuario envia uma fotografia do ambiente, opcionalmente acompanhada de um texto. O modelo de visao classifica o ambiente segundo o comodo, a temperatura de cor e a intensidade desejadas; em seguida, uma consulta de pontuacao (scoring) seleciona os tres produtos mais adequados do catalogo."
Add-Heading "7.3 Pre-visualizacao do produto no ambiente" 2
Add-Para "Na modalidade de pre-visualizacao, o sistema gera uma imagem que simula o produto instalado no ambiente do usuario, com a iluminacao caracteristica daquele produto. Em razao de a geracao de imagem demandar de dois a quatro minutos - tempo superior ao limite de conexao imposto pela camada de borda da rede -, adotou-se um modelo de processamento assincrono com sondagem (polling), descrito na Figura 3."
Add-Caption "Figura 3 - Processamento assincrono da pre-visualizacao"
Add-Mono @(
"  1a chamada (sem identificador de tarefa):",
"      valida autenticacao, limite diario e fontes",
"      submete a tarefa ao modelo",
"      responde imediatamente com o identificador da tarefa",
"            |",
"            v  (o app reenvia o identificador a cada 30 segundos)",
"  Sondagem (com identificador de tarefa):",
"      consulta o estado da tarefa",
"          concluida  -> armazena a imagem e a retorna",
"          falhou     -> ressubmete e devolve novo identificador",
"          em curso   -> informa que ainda esta processando"
)
Add-Source "Fonte: elaborado pelo autor."
Add-Para "Aplica-se um limite de duas pre-visualizacoes por usuario por dia, computado no momento da submissao e efetivamente registrado apenas quando a imagem e gerada com sucesso."

# ---- 8 TECNOLOGIAS ----
Add-Heading "8 TECNOLOGIAS UTILIZADAS" 1
Add-Para "O Quadro 6 consolida as principais tecnologias empregadas no projeto, organizadas por camada."
Add-Caption "Quadro 6 - Tecnologias por camada"
Add-Table @(
  @("Camada / funcao","Tecnologia"),
  @("Linguagem do aplicativo","Dart"),
  @("Framework do aplicativo","Flutter"),
  @("Gerenciamento de estado","Riverpod"),
  @("Navegacao","go_router"),
  @("Persistencia local","Hive; flutter_secure_storage"),
  @("Notificacoes locais","flutter_local_notifications"),
  @("Backend / regras","n8n"),
  @("Banco de dados","PostgreSQL (extensoes pgcrypto e citext)"),
  @("Autenticacao","JWT (HS256); bcrypt; Google OAuth 2.0"),
  @("Armazenamento de imagens","Cloudinary"),
  @("Inteligencia artificial","ModelScope (Qwen2.5-72B, Qwen2.5-VL-72B e Qwen-Image-Edit)"),
  @("Servicos de apoio","ViaCEP e BrasilAPI (consulta de CEP)")
)
Add-Source "Fonte: elaborado pelo autor."

# ---- 9 CONSIDERACOES FINAIS ----
Add-Heading "9 CONSIDERACOES FINAIS" 1
Add-Para "A arquitetura proposta atingiu o objetivo de separar responsabilidades em camadas bem definidas, concentrando as regras de negocio no backend e mantendo o aplicativo restrito a apresentacao e a experiencia do usuario. O uso do n8n como camada de negocio mostrou-se adequado ao contexto academico, por dispensar a manutencao de um servidor de aplicacao tradicional e por oferecer um ambiente visual e versionavel para a orquestracao de fluxos. As restricoes da instancia utilizada, embora tenham exigido solucoes especificas - sobretudo a realizacao da autenticacao em SQL e a implementacao da inteligencia artificial por requisicoes HTTP diretas -, foram contornadas sem prejuizo as funcionalidades previstas."
Add-Para "Cabe registrar que algumas escolhas foram orientadas pelo carater academico do trabalho, com destaque para o armazenamento de segredos diretamente nos fluxos e a assinatura do aplicativo com chave de depuracao. Tais decisoes priorizaram o funcionamento integral do sistema e deveriam ser revistas em um eventual cenario de producao comercial."

# ---- Salvar ----
$wdFormatDocumentDefault = 16  # .docx
$outPath = [string]$out
$doc.SaveAs2($outPath, $wdFormatDocumentDefault)
$doc.Close()
$word.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sel) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
Write-Output "OK -> $out"
