# QA Report — v2.0.0 (2026-10-03)

Ambiente: Godot 4.5.1-stable (Linux headless + Xvfb/llvmpipe), OpenJDK 21, apksigner (apt), Kokoro-onnx 0.6.1.
Reprodução: `tools/run_checks.sh` · `tools/build_apk.sh` · previews: `godot --path game -- --segpreview=<dir>[:filtro]`.

## Resultado das execuções
| Verificação | Resultado |
|---|---|
| Lint (`gdlint src tests`) | 0 problemas |
| Parse de todos os scripts (`-- --checkscripts`) | 0 falhas |
| Testes unit + integração | **69 testes, 2073 asserts, 0 falhas** (inclui fluxo de missão, chefão, campanhas↔histórias/itens, figuras do banco de palavras) |
| Smoke v1 (telas legadas) projeto / pacote | PASS 79 passos / PASS 79 passos |
| **Smoke v2**: abertura → 12 missões pelo mapa → Desafio de Comandante → desafio da família → 9 estações | **PASS 52 passos, 0 erros de log, 0 falas sem áudio** (projeto e pacote exportado) |
| Smoke v2 errando de propósito (~30% das ações) | **PASS 51 passos** — nenhuma recuperação de erro trava |
| Adaptação | acertando tudo: contagem sobe ao nível 3, sílabas ao 2 |
| Voz | 529 falas, 6,0 MB; durações conferidas (sílaba ≈0,4 s; frase longa ≤6 s); fonemas checados (bá, guê, Víni, robô) |
| APK universal | 61 MB · arm64-v8a + armeabi-v7a · minSdk 24/target 35 · versionCode 3 · só VIBRATE · assinatura OK |
| APK arm64 | 37 MB · assinatura OK |
| SHA-256 universal | `51b57f7d24ba6c0a8850659e5cc7faa522196d4b09a1be813d09c66aa420fcbf` |
| SHA-256 arm64 | `34c02d15e55889687e77992da047690e5eed5e540dd2771b7976714ad05d4278` |

## Bugs encontrados e corrigidos na v2
1. Vários "Cannot infer type" (índice de array/dicionário com `:=`) — pegos pelo novo `--checkscripts` antes de rodar.
2. `Router.sky` nulo nos testes derrubava segmentos → `GameScreen.set_sky()` com guarda.
3. `_process` rodando antes de `build()` (nós nulos) → guardas no GameScreen/voo/planetário.
4. Portais sobrepostos e alvo novo após erro → espaçamento + repetir o MESMO alvo (andaime).
5. Peça encaixada voltava ao tamanho da bandeja (tween do encaixe sobrescrevia a escala) → `snap_to(final_scale)`.
6. Foguete desproporcional, aleta direita sem espelhar, peças descoladas → layout pelos viewBox.
7. Parâmetro `mode` do voo colidia com o `mode` da missão (comandante) → renomeado para `play`.
8. Estrelas da missão somavam (até 9) → média dos jogos, 1–3.
9. Cena sem falas terminava no mesmo frame → atraso mínimo.
10. Elogio personalizado ("Muito bem, Vini!") não achava o áudio → chave normaliza o nome de volta para `{name}`.
11. Lambdas `func(): if ...` aceitas pelo Godot mas não pelo gdtoolkit → métodos nomeados.
12. Quarto/troféus v1 dependiam de leitura → guarda-roupa e sala de troféus novos, sem texto.

## Não verificado aqui (precisa de você)
- Instalar no aparelho, abrir em modo avião, 60 FPS, vibração, volume real da voz vs. música.
- Se o Vini entende sozinho cada jogo e se diverte (Fun Gate). Sugestão: observar 15 min sem ajudar e anotar onde ele trava.

---

# QA Report — v1.1.0 (2026-10-03)

Ambiente: Godot 4.5.1-stable (Linux headless + Xvfb/llvmpipe para render), OpenJDK 21, apksigner 31 (apt).
Reprodução: `tools/run_checks.sh` (tudo) · `tools/build_apk.sh` (APK) · `tools/screenshots.sh` (telas).

## Resultado das execuções
| Verificação | Resultado |
|---|---|
| Lint (`gdlint src tests`) | 0 problemas |
| Testes unit + integração | **65 testes, 1911 asserts, 0 falhas** (inclui rasterizar toda a arte) |
| Todas as 399 atividades jogadas pelo minigame real (erro → dica → acerto) | 0 falhas, 0 erros de log |
| Smoke end-to-end no projeto | **PASS — 59 passos, 0 falhas, 0 erros de log** |
| Smoke end-to-end no **pacote exportado** (mesmos filtros do APK) | **PASS — 59 passos** |
| Sessão longa (40 missões seguidas) | memória 66,8 → 67,6 MB; nós estáveis (~92) |
| Boot (desktop, pacote exportado) | ~270 ms até a tela inicial |
| Layout 16:9, 20:9 (2400×1080), 4:3 (1024×768) | sem cortes/transbordo (screenshots) |
| APK | assinatura v2+v3 OK; minSdk 24/target 35; arm64-v8a + armeabi-v7a; **0 permissões**; allowBackup=false |
| SHA-256 do APK (v1.1.0) | `3b5b0b4a5b5f2c7d1de0fce286ea7d3884f061eeb8f075001114a21660f117dc` |

O smoke cobre: novo jogo → criar personagem → intro → nave → mapa → 3 planetas (missões) → erro proposital e
recuperação → os 7 jogos de habilidade → Desafio de Comandante → história ramificada até o fim → Sentimentos →
Laboratório (salvar planeta) → Observatório + Quiz → Troféus (equipar) → porta dos pais (resposta errada barra,
certa entra) → todas as abas do painel → criar desafio da família → música off/on → cumprir desafio →
"fechar e abrir" (cache descartado, relido do disco) → estrelas/progresso/avatar/histórico preservados →
todas as telas abrem.

## v1.1.0 — arte nova
- Ilustração vetorial em camadas (ADR-018). Revisão por galerias (`--artpreview`) e 30 screenshots.
- Bugs achados na integração e corrigidos: **Critical** crash (signal 11) ao adiar redesenho com
  `call_deferred` dentro de `_draw`; **High** textura liberada pelo cache LRU ainda em uso.
- Mesmo certificado de assinatura da 1.0.0 (SHA-256 126611cc…99001f7) → atualiza sem perder progresso.

## Bugs encontrados e corrigidos (por severidade)
**Critical**
- `lab_screen._set()` colidia com o virtual `Object._set` → tela do Laboratório não carregava (parse error).
- `gdformat` quebrou lambda multilinha do painel dos pais (parse error). Arquivo restaurado; criado teste
  "toda tela abre" que pegaria isso.

**High**
- Re-render com `queue_free` mantinha o nó antigo no frame; o novo homônimo era renomeado pelo engine
  → botões de história/painel "sumiam" para a navegação. Correção: `UI.clear()` remove na hora.
- Lambdas em timers capturando nós já liberados ao trocar de tela (splash/hub/runner/história/memória)
  → erros em runtime. Correção: `BaseScreen.after()` com Tween ligado ao nó.
- Números das respostas apareciam "4.0" (JSON devolve float).
- Sequência de Padrões com 7+ peças saía da tela.

**Medium**
- Toast/banner vazavam para a tela seguinte e cobriam a instrução; dois banners sobrepostos no fim da missão.
- Botões não cresciam com o texto (abas cortadas, letra solta, chips sobrepostos no painel).
- Terra invisível no Quiz (mesma cor do botão).
- Miniaturas de avatar com olhos fechados (piscar no t=0); item trancado parecia personagem de pele escura.
- Ícone de planeta parecia fone; Lua com polígono auto-intersectante (erro de triangulação).
- TTS no Linux sem speechd gerava erro a cada fala → re-tentativa limitada por tempo.

**Low**
- "Quantos estrelas" (concordância); "como ele está" para "estrelinha" (frase neutra).
- StyleBox alocado por chamada em todo frame → cache.

## Limitações conhecidas (não são bugs)
- **Não houve teste em aparelho físico nem emulador**: o ambiente não tem KVM/imagens Android (download do
  SDK do Google bloqueado). O que foi validado do APK: assinatura, manifest, conteúdo empacotado e o mesmo
  pacote de jogo rodando o smoke. Pendência para o responsável: instalar e rodar o roteiro abaixo.
- Narração depende da voz pt-BR do Android ("Serviços de fala do Google" + dados de voz em português).
  Sem ela, tudo aparece em texto (verificado nos testes com TTS indisponível).
- Desempenho medido em desktop; em celulares antigos (2 GB RAM) o esperado é boot de 1–3 s.

## Roteiro rápido no aparelho (5 min)
1. Instalar `dist/ViniComandante-v1.1.0.apk` (permitir "fontes desconhecidas").
2. Ativar modo avião. Abrir → JOGAR → criar astronauta → Pular intro.
3. Mapa → Marte → MISSÃO; errar uma de propósito (dica aparece) e concluir.
4. Fechar o app pelo multitarefa, abrir de novo: estrelas e traje novo continuam.
5. Segurar o ícone dos pais 2s → conta → conferir Resumo/Habilidades; desligar/ligar Música.
