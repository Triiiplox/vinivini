# CHANGELOG

## v2.0.0 — 2026-10-03 — Jogo de verdade (sem precisar ler)
Resposta ao feedback "o Vini não sabe ler, jogabilidade e desenhos ruins, pouca variedade".
### Adicionado
- **Fluxo novo da criança, 100% por voz/figura/toque**: abertura cinematográfica → nave explorável →
  mapa da galáxia → missões → baú de recompensa. As telas v1 com texto saíram do caminho da criança.
- **Voz natural pré-gerada offline** (Kokoro, pt-BR): narradora, Cosmo com timbre de robô e NPCs;
  529 falas (`tools/gen_voice.py`), sem TTS do sistema. Música (10 trilhas), SFX e ambiências com
  instrumentos reais via FluidSynth (`tools/gen_music.py`); buses, crossfade e ducking.
- **12 jogos (segmentos)**: exploração com porta de contagem e resgate; pilotagem com portais e chefão;
  construção (foguete, jipe, reator) com teste; Restaurante de Marte (contar, somar, dois pratos);
  Monstro das Sílabas (leitura pelo som); montar palavra no foguete; robô programável; planetas cantores
  (memória); trilha de luzes (padrões); histórias animadas com escolhas por figura; planetário com
  Sistema Solar em órbita; criador de criaturas; cenas curtas.
- **4 campanhas, 12 missões** data-driven com desbloqueio em cadeia; Desafio de Comandante (coroa no mapa).
- Nave-hub com 9 estações, mascote dragãozinho, criaturas criadas passeando; guarda-roupa; sala de
  troféus (medalhas, criaturas, desenhos); ateliê de desenho.
- Visual: céu em shader com nebulosas, planetas 3D girando (shader), parallax, partículas GPU,
  transição em íris, personagens com esqueleto procedural (andar, pular, comemorar, falar).
- Desafio da família (área dos pais) chega como presente na nave e abre o jogo v2 da habilidade escolhida.
- QA: "robô jogador" (`src/debug/autoplay.gd`) joga as 12 missões de ponta a ponta, também errando de
  propósito; `--checkscripts`; previews visuais por segmento (`--segpreview`).
- 122 elogios contextuais; banco de sílabas e palavras com pronúncia.
### Alterado
- versionCode 3 / 2.0.0 (instala por cima mantendo o progresso). Permissão única: VIBRATE (feedback tátil).
- Botão Home volta à nave (não mais ao hub v1). TTS do sistema desligado.
### Removido
- Áudio sintetizado v1 (`assets/audio`, `tools/gen_audio.py`).

## v1.1.0 — 2026-10-03 — Arte nova
### Alterado
- Toda a arte de personagens e cenário refeita em ilustração vetorial (SVG em camadas, rasterizada na
  resolução da tela): astronauta chibi com contorno, volume e brilhos; Cosmo, robozinho, alien,
  estrelinha Lumi e Bip redesenhados com 6 expressões, piscar e boca falando; planetas com sombreamento
  esférico, anéis com profundidade e crateras/faixas/continentes; objetos de contagem e peças de
  padrão com volume; fundo com nebulosas.
- versionCode 2 / 1.1.0 (instala por cima da 1.0.0 mantendo o progresso).
### Adicionado
- `tools/gen_art.py`, `SvgArt` (cache LRU + orçamento por frame), galeria `--artpreview`.
- Teste que rasteriza todas as combinações de avatar, personagens × expressões, planetas, tokens.
### Corrigido
- Crash (signal 11) ao adiar redesenho com `call_deferred` dentro de `_draw`.
- Textura liberada pelo cache enquanto ainda estava em uso por um nó.

## v1.0.0 — 2026-10-03 — MVP
### Adicionado
- Projeto Godot 4.5.1 (GL Compatibility), Android landscape, minSdk 24, arm64 + armv7, 0 permissões.
- Arquitetura em camadas: EventBus, Router com histórico, GameLog; engines puros (Learning, Adaptive,
  Content/Validator, Story, Reward, Praise); persistência por repositories com envelope versionado,
  escrita atômica e backup; autoloads de serviço.
- Conteúdo data-driven (399 atividades em 9 habilidades × até 3 níveis; 2 histórias com 5 finais; 10 fatos;
  24 itens; elogios por contexto) gerado por `tools/gen_content.py` e validado no boot e nos testes.
- 9 minigames: Sílabas, Montar Palavra, Contar, Somar, Comparar, Padrões, Memória, Quiz do Espaço, Sentimentos.
- Telas: início, criador/oficina, intro do Cosmo, nave, mapa, planeta, atividade, resultado, biblioteca,
  história, laboratório de planetas, observatório, troféus, porta dos pais, painel dos pais.
- Adaptação: nível por habilidade sobe/desce; modo apoio com representação alternativa e dicas;
  revisão espaçada; Desafio de Comandante (+1 nível, sem punição); Cosmo sugere destino.
- Recompensas: estrelas não monetárias, itens por marco, celebração calibrada, elogios variados
  (simples, sequência, persistência, estratégia, desafio).
- Painel dos pais: resumo, habilidades observáveis, histórico, desafio da família, ajustes
  (música/efeitos/voz, nome, lembrete de pausa, apagar progresso).
- Áudio sintetizado (SFX + música em loop) e narração TTS pt-BR offline com fallback em texto.
- Arte 100% procedural; fontes Andika/Comfortaa (OFL); ícone adaptativo.
- Ferramentas: `setup_env.sh`, `run_checks.sh`, `build_apk.sh`, `screenshots.sh`, geradores.
- Testes: 62 (unit + integração), smoke end-to-end (projeto e pacote exportado), soak de 40 missões.
### Corrigido durante o QA
- Ver docs/QA_REPORT.md (2 critical, 4 high, 6 medium, 2 low).
