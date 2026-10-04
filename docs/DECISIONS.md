# Architecture Decision Log

## ADR-001 - Godot 4.x
Escolhido por ser engine dedicada a jogos, ótima para 2D, animações, cenas e mobile.

## ADR-002 - GDScript
Menor atrito com Godot e bom ciclo de desenvolvimento.

## ADR-003 - Offline-first
Jogo principal não depende de rede.

## ADR-004 - Data-driven content
Atividades e histórias devem ser desacopladas do código quando possível.

## ADR-005 - 2D/2.5D
Mais rápido, leve e adequado ao MVP que 3D completo.

## ADR-006 - Godot 4.5.1 + renderer GL Compatibility
Versão estável mais recente disponível. Compatibility (OpenGL ES 3) roda em mais aparelhos Android antigos
que Vulkan (Mobile) e é suficiente para 2D desenhado. minSdk 24 (Android 7), targetSdk 35.

## ADR-007 - Arte 100% procedural (desenhada em código)
Sem assets de terceiros: planetas, avatar, personagens, ícones e objetos são desenhados com a API 2D
(`_draw`). Vantagens: zero risco de licença, APK menor, fácil variar expressões/cores por dados.
Áudio também é sintetizado (`tools/gen_audio.py`). Fontes: Andika (SIL, criada para alfabetização:
"a" e "g" na forma escolar) e Comfortaa (títulos), ambas OFL.

## ADR-008 - UI montada em código, telas como scripts
Cada tela é um script (`BaseScreen`) instanciado pelo `Router` com `params`. Facilita testes
automatizados (sem depender de cenas .tscn editadas à mão) e diffs legíveis. Main.tscn é a única cena.

## ADR-009 - Persistência: StorageBackend -> VersionedStore -> Repositories
`JsonFileStorage` (escrita atômica .tmp -> .bak -> .json, recuperação por backup) e `MemoryStorage` (testes).
`VersionedStore` aplica envelope `{schema_version, saved_at, data}`, migração (`SaveMigrations`) e
preenchimento/correção de tipos por padrão. O jogo só conhece Profile/Progress/Inventory/SettingsRepository.
Salva a cada evento relevante e ao pausar/fechar o app.

## ADR-010 - Regras do Learning Engine
Ganho por acerto de primeira (+0,15 rápido ≤8s / +0,10), acerto após erro (+0,04, persistência conta),
perda pequena (-0,05) só com 3+ tentativas. 2 rodadas seguidas com erro -> modo apoio (dica/representação
alternativa: sílaba colorida, objetos em fileiras, contagem guiada, demonstração mais lenta). 3 seguidas -> desce
nível. Sobe nível com domínio ≥0,8 e 3 acertos de primeira seguidos. Revisão espaçada 1-2-4-8-14 dias; erro
agenda revisão imediata. Desafio de Comandante nunca penaliza.

## ADR-011 - Narração por TTS do sistema (offline)
Usa `DisplayServer.tts_*` com voz pt-BR do Android (motor do Google funciona offline com o pacote de voz
instalado). Toda fala também está em texto na tela; botão de alto-falante repete. Se não houver voz pt,
o jogo segue só com texto e o painel dos pais informa. Fala nova interrompe a anterior (sem sobreposição) e
a música abaixa (ducking) durante a fala.

## ADR-012 - Estrelas não monetárias e desbloqueio por marco
Estrelas só acumulam; não existem loja, gasto, perda nem compras. Itens cosméticos liberam por marcos
(estrelas, missões por área, desafio, história, criação, desafio da família). Nenhum streak diário,
nenhuma punição por não jogar.

## ADR-013 - Porta dos pais
Segurar o botão por 2s + multiplicação 6..9 × 6..9 digitada. Barreira suficiente para 4 anos sem exigir
senha que o adulto esqueça.

## ADR-014 - Assinatura de sideload versionada
`game/android/vini-sideload.keystore` (senha `vinisideload`) fica no repositório de propósito: atualizações
do APK precisam da MESMA assinatura, senão o Android exige desinstalar e o progresso da criança é apagado.
NÃO é chave de loja. Para Play Store: gerar chave nova, guardar fora do repo e usar Play App Signing.

## ADR-015 - Sem backup em nuvem e sem permissões
`allowBackup=false` e nenhuma permissão no manifest (inclusive sem INTERNET). O app é fisicamente incapaz
de acessar rede — modo avião é o estado natural.

## ADR-016 - Export sem Gradle; toolchain mínima
Export "pré-compilado" do Godot (template APK) + `apksigner`/`zipalign`/`adb` do apt. Dispensa Android
Studio/SDK completo (o download do SDK oficial foi bloqueado no ambiente de build). Reproduzível com
`tools/setup_env.sh` + `tools/build_apk.sh`.

## ADR-017 - Ideias novas incluídas (dentro do escopo)
- Laboratório de Planetas: criação aberta; o nome do planeta é montado com sílabas (leitura sem pressão).
- Desafio da família: responsável cria desafio (habilidade, nível, rodadas, mensagem) que aparece na nave.
- Lembrete de pausa opcional (desligado por padrão), gentil e sem bloquear o jogo.
- Cosmo sugere o planeta cuja habilidade mais precisa de prática (seleção adaptativa visível).
- Histórias registram finais descobertos ("Finais: 1 de 3") — incentivo a reler e explorar escolhas.

## ADR-018 - Arte vetorial em camadas (substitui as primitivas da v1.0.0)
Feedback do responsável: personagem e desenhos com qualidade baixa. Nova pipeline:
`tools/gen_art.py` gera `game/assets/art/art.json` com ilustrações SVG em camadas (contorno cartoon,
volume por gradiente, brilhos, proporção chibi, 6 expressões + piscar + fala). Em runtime, `SvgArt`
resolve as cores (pele/cabelo/traje/planeta) e rasteriza com o ThorVG do Godot na resolução real da tela.
- Personalização intacta: cores e peças continuam paramétricas; nenhum PNG por combinação.
- Cache LRU (200) + orçamento de 4 rasterizações por frame: telas com muitas miniaturas carregam
  progressivamente em vez de travar em aparelho fraco.
- Cada nó guarda referência às texturas que desenhou (o LRU não pode liberar textura em uso).
- Redesenho adiado via `process_frame` (CONNECT_ONE_SHOT); `call_deferred(queue_redraw)` dentro de
  `_draw` causava crash (signal 11) no Godot 4.5.1.
- ThorVG não aceita cor hex com alfa (#rrggbbaa): usar fill-opacity/stroke-opacity.
- Ícones de UI seguem chapados (brancos sobre botões coloridos), por legibilidade.

## ADR-019 - v2: a criança não lê → nada no caminho dela depende de texto
Feedback: "o Vini não sabe ler e o jogo espera decisões onde ele tem que ler". Regra nova:
toda instrução é **falada** (voz pré-gerada), toda escolha é **figura/forma/cor + som**, toda tela tem
botão "ouvir de novo" e uma mão-guia aparece após 6 s parado. Texto só existe como objeto de aprendizagem
(sílabas, numerais) e sempre tocável para ouvir. As telas v1 (hub, mapa, planeta, atividade, criador,
troféus, biblioteca, laboratório, observatório) ficaram fora do fluxo da criança; continuam no código
(testes e smoke v1) e são candidatas a remoção. A área dos pais continua com texto (é para adultos).

## ADR-020 - Voz natural pré-gerada offline (Kokoro), sem TTS do sistema
Opções: TTS do Android (genérico, depende de dados instalados, varia por aparelho), serviço de voz na
nuvem (exige internet/conta — o jogo é offline e sem rede), modelo neural local no build. Escolha:
**Kokoro-82M (ONNX) no build** gerando OGG mono 24 kHz; vozes `pf_dora` (narradora), `pm_alex` com leve
aumento de tom e eco (Cosmo) e `pm_santa` (NPCs). `tools/gen_voice.py` varre `Lines.n/Lines.c`, frases de
diálogo nas constantes dos segmentos e todo o conteúdo JSON; chave = md5("quem|texto-modelo"), igual a
`VoiceService.key_for`, então só falas novas são sintetizadas. "{name}" vira "Víni" (acento força a
pronúncia certa); sílabas isoladas usam vogal acentuada ("bá") para não serem soletradas.
Custo: 529 falas ≈ 6 MB. Limitação: o nome é sempre "Víni" — mudar o nome na área dos pais não muda a voz.

## ADR-021 - Missões = sequência de segmentos (telas de jogo) definidos em JSON
`content/campaign/campaigns.json` define campanhas e missões; cada missão é uma lista de segmentos
(`cutscene`, `flight`, `explore`, `build`, `cook`, `monster`, `word`, `robot`, `memory`, `pattern`,
`story`, `planetarium`, `creature`, `boss`) com parâmetros. `MissionFlow` executa, junta estrelas (média,
1–3) e desbloqueia a próxima. Cada segmento é um `GameScreen` (mundo 2D + câmera + HUD sem texto +
roteamento de toque/arraste) e registra "momentos de aprendizagem" no Learning Engine por tarefa,
não por tela. O mesmo segmento roda como missão, brincadeira livre (estação da nave), Desafio de
Comandante (+1 nível) ou desafio da família (nível escolhido pelo adulto).
O parâmetro de modo de voo chama-se `play` (e não `mode`) porque `mode` é reservado ao MissionFlow.

## ADR-022 - QA por "robô jogador"
Para não aceitar "funciona" sem prova, `src/debug/autoplay.gd` resolve cada segmento lendo o estado interno
(como uma criança que acerta) e, com `--mistakes`, erra de propósito ~30% das ações (peça a mais, sílaba
errada, portal errado, programa errado, servir prato vazio...). `--smoke2` joga a abertura e as 12 missões
pelo mapa, abre cada estação da nave, o Desafio de Comandante e o desafio da família; falha se algo travar,
se houver erro de log ou fala sem áudio. Roda no projeto e no pacote exportado (`tools/run_checks.sh`).

## ADR-023 - Tamanho do APK
Motor Godot (arm64) já ocupa 23,6 MB comprimido; voz 6 MB; música recodificada para OGG q0 (≈2,5 MB).
Resultado: arm64 37 MB, universal (arm64+armv7) 61 MB. Não cabe no limite de anexo do chat (≈30 MB) sem
cortar a voz; por isso o APK vai versionado em `dist/` no GitHub. Reduzir mais exigiria compilar o motor
sem módulos (fora do escopo agora).

## ADR-024 - Permissão VIBRATE
Haptics leves (encaixe, portal certo, estrelas) pedem `android.permission.VIBRATE` (permissão "normal",
sem diálogo para o usuário). Continua sem INTERNET; `build_apk.sh` falha se aparecer qualquer outra.
Vibração desligável em Ajustes (área dos pais).

## ADR-025 - Rig e animação de personagens 100% Godot (sem Spine), custo R$ 0
Decisão do responsável (Andro). Personagens montados por partes em Skeleton2D + Bone2D, deformação por
Polygon2D com pesos, AnimationPlayer + AnimationTree (state machine, BlendSpace1D), IK nativo (TwoBoneIK/LookAt),
movimento secundário por SkeletonModification2DJiggle (experimental no Godot 4) com fallback de mola procedural,
rosto em slots e lip-sync por markers. Skins por slot + recolor por shader. Synfig só para cinemática especial,
se precisar. Spine e DragonBones descartados. Classes conferidas no Godot 4.5.1 do projeto.
Trade-off: mais trabalho manual de rig; a qualidade visual exigida pelas pranchas não muda.
Detalhes: `v3/arte/RIG_GODOT.md`.

## ADR-026 - Tela principal por matérias (botões grandes), nave andável vira passeio
Contexto: no teste com o Andro (S23/S10e), escolher "leitura" ou "contas" exigia andar pela nave até a Escola,
escolher a área e depois a lição — passos demais para 4 anos. Decisão: a raiz do jogo (`Router.home()`) é a tela
`home`: 10 botões grandes (Leitura, Números, Lógica, Ciências, Espaço, Sentimentos, Inglês, Criar, Missões, Nave),
ícone + voz, um toque abre. A nave continua como passeio opcional. Consequência: todo "voltar ao início" vai para
`home`; testes de navegação esperam `home`.

## ADR-027 - Trilha linear por matéria com desbloqueio sequencial
Cada matéria abre numa trilha (`academy` com `params.area`): lições na ordem do conteúdo; a primeira não feita
brilha e pulsa; feitas mostram estrelas; as seguintes ficam apagadas com cadeado grande e, ao toque, a voz explica e
a mão aponta a próxima. Progressão clara substitui a grade de cartões soltos. A ordem das lições no
`tools/build_lessons.py` É a progressão pedagógica (ex.: vogais → escrever vogais → consoantes → escrever letras →
som das letras → montar palavras → ler palavras).

## ADR-028 - Entrada por toque: nada pode "consumir" o toque antes do mundo; posição vem do evento
Bug real (v1–v2.3.5): o `ScreenHost` (Control com MOUSE_FILTER_STOP) engolia todo toque que atravessava as telas
de jogo (que são IGNORE e tratam o dedo em `_unhandled_input`). Decisão: raiz e host com IGNORE; o ponto do mundo
vem de `event.position` transformado pela câmera (`GameScreen._event_point`), não do cursor do mouse.
Obrigatório: `tools/run_checks.sh` roda `--touchcheck` (toques/arrastos reais via `Input.parse_input_event`, tela
2340×1080) — teste que dispara sinais por código não conta como teste de toque.

## ADR-029 - Gestos permitidos: tocar, arrastar e deslizar na horizontal (com inércia)
Para 4 anos: tocar e arrastar são os gestos confiáveis; deslizar horizontal rola trilha/mapa/nave/biblioteca
(`GameScreen.swipe_scroll`, limiar 18 px, inércia com decaimento). Nada de pinça, dois dedos ou toque longo para a
criança (toque longo só no cadeado dos pais). Alvos de toque grandes (raio ≥ 70 px no mundo 1280×720).

## ADR-030 - Lições "mão na massa" e "eu faço, você faz"
Rodadas novas no motor `seg_lesson`: `trace` (traçar letra bastão com o dedo, pontos de controle, ≥ 85%),
`count` (tocar em cada objeto; a voz conta), `join`/`take` (arrastar para dentro/fora da cesta; depois contagem
guiada item a item e o total falado), `build` (arrastar sílabas para formar a palavra; tocar na sílaba faz ouvir o
som). Na primeira rodada de cada tipo, a mão demonstra o gesto depois da fala. Erro nunca é punido: o item volta,
balança, e na 2ª tentativa a mão mostra.

## ADR-031 - Telas largas (19,5:9) com stretch "expand"
Celulares atuais mostram mais que 1280 px de largura. Fundos e céu precisam cobrir o viewport visível
(`SkyLayer._fit_painted`); conteúdo jogável fica dentro de 1280×720 para funcionar também em 16:9.

## ADR-032 - Vídeos de apresentação podem ter fantasia; o conteúdo ensinado não
Os vídeos de abertura/momentos (Gemini/Grok, editados) são apresentação e podem ter elementos de fantasia
(decisão do Andro). Lições, missões e textos ensinados continuam só com ciência real.

## ADR-033 - Validação visual obrigatória antes de cada APK
Toda entrega passa por captura de todas as telas no formato 2340×1080 (`--segpreview`, `--touchcheck`) e revisão
crítica tela a tela (o que está feio, confuso ou cortado) antes de gerar o APK.

## ADR-034 - Pular o que a criança já sabe
O Vini já conhece letras e números (informação do Andro, 04/10). Lições só de apresentar ("Essa é a letra A",
contar até 10) cansam e passam a sensação de jogo fraco. Elas ganharam `"basic": true` no conteúdo
(`vogais`, `consoantes`, `tracar_vogais`, `contar_tocando`) e saem da trilha e da recomendação quando a chave
"Já conhece letras e números" da área dos pais está ligada (padrão: ligada). Leitura começa em escrever letras,
depois sons, sílabas e palavras; matemática começa em juntar e tirar com objetos. Desligar a chave traz tudo de volta.

## ADR-035 - Trilha por fases (lição × estágio) e teste para pular
O Vini terminou todo o conteúdo em um dia: 56 lições com cerca de 340 perguntas e 3 níveis por habilidade. Os apps de referência têm de 700 a 5.000 atividades em 8 a 50 etapas visíveis, com nivelamento e teste para pular (docs/PESQUISA_APPS_PROGRESSAO.md).
- **Fases:** cada lição tem N estágios (`levels`, ou o maior `lvl` das perguntas), e cada par lição × estágio é uma fase da trilha (`id@estágio`).
- **Progresso:** fica em `progress.stages_done`, guardando a melhor nota (1 a 3 estrelas).
- **Migração:** lição já feita antes conta como o estágio 1 feito.
- **Perguntas da fase:** saem do próprio estágio, mais ~25% de revisão do estágio anterior (revisão espaçada).
- **Teste para pular:** é o botão dourado da trilha. São 5 perguntas tiradas das próximas 3 fases; quem erra no máximo uma pula as 3 com 2 estrelas. É o que resolve o "muito básico" para uma criança adiantada sem tirar o conteúdo de quem precisa dele.
- **Desempenho:** a trilha só monta os cartões perto da fase atual, porque pode ter centenas de fases.

## ADR-036 - Evolução visível: patentes e nível por matéria
- **Patentes:** 9 (Cadete Espacial → Comandante das Estrelas), ganhas por **fases concluídas**, ou seja, por mestria. Nunca por tempo de jogo nem por compra.
- **Insígnia:** escudo com 1 a 9 estrelas, que se lê sem saber ler. Promoção = tela própria com festa e fala do Astro.
- **Tela principal:** mostra a patente com a barra até a próxima, e o número de fases feitas em cada matéria (ele já lê números).
- **Na trilha:** cada fase mostra seu número e as estrelas ganhas, com uma barra "feitas / total".
- **Sem padrões manipulativos (Radesky 2022):** sem sequência diária que pune quem falta, sem contagem regressiva, sem personagem que cobra.

## ADR-037 - Conteúdo de 1º/2º ano gerado com conferência automática
O Andro informou que o Vini lê palavras inteiras e faz mais que contas até 20. O conteúdo novo (`tools/content_v4.py`) cobre:
- **Matemática:** reta numérica até 100 (de 2, 5 e 10), dezenas e centenas com blocos, comparar até 999, somar e subtrair (com "vai um"), número escondido, multiplicar (grupos e tabuadas), dividir, metade e dobro, horas (inteira, meia e quartos), dinheiro em real (moedas, notas e troco), frações e problemas.
- **Lógica:** sequências e "pensar e descobrir".
- **Leitura:** escrita certa (dígrafos, encontros consonantais, nasais), frases com posição, montar frases e textos curtos com fatos reais.

Como foi feito:
- **Figuras desenhadas no código** (`MathFigures`, cena com posição): número e posição exatos.
- **Fala genérica nas contas** ("Quanto dá essa conta?"), com a conta escrita na tela. Ele lê números, e isso segura o tamanho do APK.
- **Conferência automática:** toda resposta marcada como certa é recalculada antes de gerar o APK, e perguntas repetidas são removidas.
