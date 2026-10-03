# PROJECT STATUS

## v2.0.0 (2026-10-03) — reconstrução após feedback
Status: **software pronto e testado automaticamente; falta validar no aparelho e com o Vini.**
APK: `dist/ViniComandante-v2.0.0.apk` (universal, 61 MB) · arm64: `build/ViniComandante-v2.0.0-arm64.apk` (37 MB)
Checagens: `tools/run_checks.sh` → TUDO OK (lint 0 · 69 testes · smoke v1 79 passos · smoke v2 52 passos
acertando e com erros de propósito · ambos também no pacote exportado · 0 falas sem áudio).
Status item a item do checklist do produto: **docs/CHECKLIST_STATUS.md** (inclui o que NÃO foi feito).

| Área | Status | Evidência |
|---|---|---|
| Fluxo sem leitura (abertura → nave → mapa → missão → baú) | PASS | smoke v2; screenshots `docs/screenshots/v2` |
| Voz natural offline (529 falas) | PASS | smoke v2: 0 falas sem áudio; ADR-020 |
| 12 missões / 4 campanhas / 13 tipos de jogo | PASS | robô joga todas, acertando e errando (ADR-022) |
| Dificuldade adaptativa | PASS | smoke v2: contagem chega ao nível 3 com acertos; testes v1 de subir/descer |
| Desafio de Comandante e da família | PASS | smoke v2 |
| Área dos pais, save, offline | PASS | testes v1 + smoke; APK sem INTERNET |
| Instalação/desempenho em aparelho real | PENDENTE | sem dispositivo no ambiente de build |
| Fun Gate (o Vini se diverte?) | PENDENTE | só com a criança |
| Itens ❌ do checklist (customização da nave, jardim, detetive, caça ao tesouro, escrita por traçado...) | NÃO FEITO | docs/CHECKLIST_STATUS.md |

## Histórico v1 (MVP 1.0/1.1)
Status geral: **FINALIZADO (MVP)** — pendência externa única: validação em aparelho Android físico
(ambiente de build sem dispositivo/emulador; ver docs/QA_REPORT.md → "Roteiro rápido no aparelho").

APK: `dist/ViniComandante-v1.1.0.apk` (arte vetorial nova) · Checagens: `tools/run_checks.sh` → TUDO OK

| Step | Nome | Status | Testes / evidência | Observações |
|---|---|---|---|---|
| 00 | Foundation | PASS | projeto abre/importa sem erro; `gdlint` 0 problemas; boot ~270 ms | docs/CONVENTIONS.md; GameLog com buffer |
| 01 | Product & Game Vision | PASS | fluxo principal coberto pelo smoke (59 passos) | docs/MVP_SCOPE.md |
| 02 | Core Architecture | PASS | engines puros testados isoladamente; backend injetável (MemoryStorage nos testes) | EventBus, 6 autoloads, repositories |
| 03 | Visual UX Foundation | PASS | 30 screenshots revisadas em 16:9, 20:9 e 4:3; teste "voltar nunca trava" | alvos ≥96 px lógicos; 1 decisão por tela |
| 04 | Character Creator | PASS | smoke: cria, salva, persiste após reload; teste de repositório | 6 tons de pele, 6 cabelos, 6 cores, trajes/capacetes/extras |
| 05 | Spaceship Hub | PASS | smoke + teste de navegação | 6 hotspots + porta dos pais + mensagem da família |
| 06 | Learning Engine | PASS | 13 testes unitários de regras | mastery, streak, tempo, apoio, revisão espaçada |
| 07 | Content Engine | PASS | 12 testes (inválido rejeitado com mensagem; exemplos do pacote validam) | 399 atividades, 2 histórias |
| 08 | Reading | PASS | 2 minigames, todas as atividades jogadas no teste | Sílabas (3 níveis) e Montar Palavra (3 níveis); narração |
| 09 | Math | PASS | 3 minigames; dificuldade variável testada | Contar, Somar (concreta), Comparar |
| 10 | Logic & Challenges | PASS | Padrões + Memória; Desafio de Comandante sem punição (teste) | |
| 11 | Story, Imagination & Emotions | PASS | 2 histórias ramificadas (todos os caminhos terminam — teste exaustivo); Sentimentos; Laboratório | |
| 12 | Space World & Science | PASS | 4 destinos (3 de habilidade + Nebulosa); fatos revisados; Quiz | Observatório com 10 corpos |
| 13 | Rewards & Inventory | PASS | 7 testes; todo item alcançável; equipar no smoke | 24 itens; celebração small/streak/big/epic |
| 14 | Adaptive Progression | PASS | integração: sobe para nível 2 e desce com erros; skills independentes | Cosmo sugere planeta |
| 15 | Parent Area | PASS | porta testada (errada barra/certa entra); todas as abas; desafio da família ponta a ponta | sem diagnóstico/comparação |
| 16 | Audio & Accessibility | PASS | toggles testados; TTS indisponível → texto (testado) | SFX/música sintetizados; ducking; fala não sobrepõe |
| 17 | Persistence & Offline | PASS | escrita atômica, backup, corrupção, migração v1→v2, reload no smoke | 0 permissões (sem INTERNET) |
| 18 | QA & Performance | PASS | 65 testes; soak 40 missões estável; 17 bugs corrigidos | docs/QA_REPORT.md |
| 19 | Android Build | PASS* | APK assinado v2+v3 verificado; manifest auditado | *instalação física pendente (externo) |
| 20 | Final Polish & Release | PASS* | DoD e release checklist preenchidos | *idem |
