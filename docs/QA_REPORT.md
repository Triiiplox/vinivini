# QA Report — v1.0.0 (2026-10-03)

Ambiente: Godot 4.5.1-stable (Linux headless + Xvfb/llvmpipe para render), OpenJDK 21, apksigner 31 (apt).
Reprodução: `tools/run_checks.sh` (tudo) · `tools/build_apk.sh` (APK) · `tools/screenshots.sh` (telas).

## Resultado das execuções
| Verificação | Resultado |
|---|---|
| Lint (`gdlint src tests`) | 0 problemas |
| Testes unit + integração | **62 testes, 1591 asserts, 0 falhas** |
| Todas as 399 atividades jogadas pelo minigame real (erro → dica → acerto) | 0 falhas, 0 erros de log |
| Smoke end-to-end no projeto | **PASS — 59 passos, 0 falhas, 0 erros de log** |
| Smoke end-to-end no **pacote exportado** (mesmos filtros do APK) | **PASS — 59 passos** |
| Sessão longa (40 missões seguidas) | memória 63,5 → 64,2 MB; nós estáveis (~92) |
| Boot (desktop, pacote exportado) | ~270 ms até a tela inicial |
| Layout 16:9, 20:9 (2400×1080), 4:3 (1024×768) | sem cortes/transbordo (screenshots) |
| APK | assinatura v2+v3 OK; minSdk 24/target 35; arm64-v8a + armeabi-v7a; **0 permissões**; allowBackup=false |
| SHA-256 do APK | `3c1eeeb786ba788f5651675e15e49506930a12b437985c0ae8001b6d94f9ae9d` |

O smoke cobre: novo jogo → criar personagem → intro → nave → mapa → 3 planetas (missões) → erro proposital e
recuperação → os 7 jogos de habilidade → Desafio de Comandante → história ramificada até o fim → Sentimentos →
Laboratório (salvar planeta) → Observatório + Quiz → Troféus (equipar) → porta dos pais (resposta errada barra,
certa entra) → todas as abas do painel → criar desafio da família → música off/on → cumprir desafio →
"fechar e abrir" (cache descartado, relido do disco) → estrelas/progresso/avatar/histórico preservados →
todas as telas abrem.

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
1. Instalar `dist/ViniComandante-v1.0.0.apk` (permitir "fontes desconhecidas").
2. Ativar modo avião. Abrir → JOGAR → criar astronauta → Pular intro.
3. Mapa → Marte → MISSÃO; errar uma de propósito (dica aparece) e concluir.
4. Fechar o app pelo multitarefa, abrir de novo: estrelas e traje novo continuam.
5. Segurar o ícone dos pais 2s → conta → conferir Resumo/Habilidades; desligar/ligar Música.
