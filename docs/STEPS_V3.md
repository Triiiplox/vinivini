# Passos da v3 — do "está horrível" ao "pronto"

O feedback do Andro (S23 e S10e, 04/10) que originou esta lista:
- a jogabilidade não agrada;
- deslizar o dedo não faz nada;
- tocar não faz nada;
- não dá para ver quando uma fase está trancada;
- não está claro o que fazer;
- as lições são fracas;
- não está fluido;
- não dá para escolher leitura ou contas;
- o cachorrinho e o robô são feios e não fazem nada.

Cada passo abaixo só fecha quando passou em três provas:
1. teste automático;
2. teste de toque real (`--touchcheck`, numa tela de 2340×1080);
3. captura da tela revisada a olho.

## v3.0 — Navegação (feito)
| Passo | O quê | Prova |
|---|---|---|
| 1 | Toque chega ao jogo. O host das telas não engole o toque, e a posição vem do evento (ADR-028). | touchcheck: tocar no Vini abre a missão. |
| 2 | Tela principal com botões grandes por matéria (ADR-026). | touchcheck: Leitura → trilha. |
| 3 | Trilha por matéria com desbloqueio e cadeado grande (ADR-027). | touchcheck: a próxima lição abre; captura das 6 trilhas. |
| 4 | Deslizar com inércia na trilha, no mapa, na biblioteca e na nave (ADR-029). | touchcheck: a câmera anda mais de 100 px. |
| 5 | Mapa: fase trancada apagada com cadeado dourado, a próxima pulsa, um toque inicia a missão. | captura do mapa |
| 6 | Fundo cobre telas largas (ADR-031). | captura em 2340×1080 |
| 7 | Cachorrinho e Astro reagem ao toque na nave. | teste manual |
| 8 | Transições mais curtas e Vini mais rápido. | — |

## v3.1 — Lições fortes (em andamento)
| Passo | O quê |
|---|---|
| 9 | Traçar letra bastão com o dedo: vogais e 13 consoantes. Pontos de controle e bolinha verde de início (ADR-030). |
| 10 | Contar tocando, com a voz contando junto e o total no fim. |
| 11 | Juntar e tirar com a cesta, com contagem guiada e total falado. |
| 12 | Montar palavras com sílabas: tocar faz ouvir o som, arrastar forma a palavra. |
| 13 | "Eu faço, você faz": a mão demonstra o gesto na primeira rodada de cada tipo. |
| 14 | Trilhas novas na ordem pedagógica. Leitura: vogais → escrever vogais → consoantes → escrever letras → som → montar palavras → ler palavras. Matemática: contar tocando → juntar → … → tirar com objetos. |
| 15 | Validador e robô de testes conhecem os tipos novos. Toda fala nova tem áudio. |

## v3.2 — Polimento (próximo)
| Passo | O quê |
|---|---|
| 16 | Ronda de capturas de todas as telas em 2340×1080, com revisão crítica e correções (ADR-033). |
| 17 | Arte do Astro e do cachorrinho no estilo pintado do Vini. Depende de imagens; os prompts ficam em `docs/PROMPTS_VIDEO_E_MUSICA.md`. |
| 18 | Explicar o porquê do erro nas perguntas de matemática (campo `why` por pergunta). |
| 19 | Mais conteúdo por trilha: pelo menos 8 lições por matéria. |
