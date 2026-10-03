# Pacote v3 — rumo ao 10/10

Este pacote continua o projeto a partir da **v2.0.0** (commit `d81007c`). Ele foi escrito para ser entregue
a um agente de código (Claude Code) **e** para o Andro (responsável) acompanhar.

**Verdade antes de tudo:** nenhum prompt garante 10/10. O que este pacote garante é que **ninguém pode
declarar 10/10 sem prova**: a `RUBRICA_10.md` define o que é 10 em cada área com critérios medíveis, e os
gates bloqueiam a release enquanto a evidência não existir. Parte das evidências só o Andro e o Vini
produzem (playtest, aparelho real, opinião da fonoaudióloga). Isso está explícito em cada step.

## Ordem de uso
1. Cole `MASTER_PROMPT_V3.md` no início da sessão do agente.
2. Execute os steps **na ordem** (`steps/STEP_21` … `STEP_37`). Cada step tem um bloco "Prompt pronto"
   para colar, critérios de aceite medíveis e as evidências obrigatórias.
3. Ao final de cada step, o agente atualiza `PROJECT_STATUS.md`, `CHANGELOG.md`, `docs/DECISIONS.md` e
   a planilha de notas em `docs/RUBRICA_PROGRESSO.md` (criada no STEP 21).
4. Release só com `STEP_37` aprovado (todos os gates com evidência).

## Entradas que só o Andro tem (o agente deve pedir, não inventar)
| Entrada | Usada em | Por quê |
|---|---|---|
| Modelo do celular/tablet do Vini | 21, 32 | meta de desempenho é medida nesse aparelho |
| Região/sotaque da família (ex.: carioca, paulistano, interior de SP/MG) | 28–30 | "r" e "s" no fim da sílaba variam por região e **não são erro** |
| 3–5 gravações curtas do Vini falando (ou a lista das trocas que você ouve: "sapéu", "dato"…) | 28 | define os sons-alvo reais em vez de chutar |
| Se existe fonoaudióloga acompanhando | 28–31 | ela valida banco de palavras e alvos; o app vira "lição de casa" dela |
| Concepts: Weave ligado na conta **ou** imagens geradas por você | 22–23 | a arte segue as pranchas de `arte/referencias/` |
| Renomear Cosmo → Astro (elenco da marca) | 22, 24 | o design system manda |
| Vídeos de referência de movimento (`arte/PEDIDO_DE_VIDEOS.md`) | 24 | timing das animações |
| Voz: manter voz neural ou gravar voz humana (você/atriz) | 31 | voz humana é o teto de qualidade |

## Mapa dos steps
| Step | Tema | Dono da evidência |
|---|---|---|
| 21 | Linha de base: playtest com o Vini + medição honesta | Andro + agente |
| 22 | Direção de arte congelada a partir do **design system obrigatório** (`arte/`), tokens, character sheets, telas-chave 16:9 | agente + aprovação Andro |
| 22B | Biblioteca de UI real (9-slice, estados, motion, SFX, haptics) | agente |
| 23 | Pipeline de assets: concept → camadas → atlas → Godot | agente (+ concepts do Andro/Weave) |
| 23B | Cenários vivos, partículas, shaders, níveis de qualidade | agente |
| 24 | Personagens: rig 100% Godot (Skeleton2D/Bone2D/Polygon2D/AnimationTree, R$ 0), expressões, lip-sync, animações | agente + vídeos de referência do Andro |
| 24B | Câmera, cinemáticas, transições com warp, recompensa proporcional | agente |
| 25 | Profundidade: 3 jogos-âncora excelentes | agente + playtest |
| 26 | Nave 2.0 (salas de verdade + customização) | agente |
| 27 | Escala de conteúdo (40+ missões, variedade, chefões) | agente |
| 28 | **Planeta Eco — fundamentos de fala** (pesquisa → especificação → triagem para pais) | agente + fono |
| 29 | **Planeta Eco — ouvir e diferenciar sons** | agente |
| 30 | **Planeta Eco — falar com o Eco** (microfone, gravar/ouvir, adulto julga) | agente + Andro |
| 31 | Voz 2.0 (revisão de ouvido, opção de voz humana) | Andro + agente |
| 32 | Desempenho no aparelho real | Andro + agente |
| 33 | Área dos pais 2.0 (PIN, relatórios, modo fono) | agente |
| 34 | **Planeta Hello (inglês)** — currículo, voz nativa, repetição espaçada, trilha de 150 lições | agente |
| 35 | **Planeta Hello** — lições interativas e jogos da nave em modo inglês | agente |
| 36 | **Planeta Hello** — canções, falar em inglês, painel dos pais | agente + Andro |
| 37 | Gates finais e release | todos |

O módulo de fala chama **Planeta Eco** dentro do jogo (nada de "fonoaudiologia" para a criança).
Base científica e limites: `fala/REFERENCIAS_FALA.md`. Banco inicial: `fala/banco_fala_seed.json` — 13 famílias de sons,
353 palavras, 77 pares mínimos reais, 45 formas trocadas, 48 frases e 12 mini-histórias (não validado por fono).

O inglês chama **Planeta Hello** (personagem Hoppy, que só fala inglês). Pesquisa: `ingles/REFERENCIAS_INGLES.md`.
Currículo e anatomia da lição: `ingles/CURRICULO_INGLES.md`. Banco: `ingles/banco_ingles_seed.json` — 30 unidades,
304 palavras, 84 frases-chave, 97 comandos de corpo, 30 canções (originais ou domínio público).
