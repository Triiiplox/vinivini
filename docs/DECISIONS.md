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
