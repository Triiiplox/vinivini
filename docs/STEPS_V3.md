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

## v4.0: Conteúdo de 1º/2º ano e evolução visível (feito)
O retorno do Andro (04/10) que originou esta etapa:
- o Vini terminou tudo em um dia;
- não dava para ver a evolução;
- era básico e raso demais.

Ele lê palavras inteiras e faz mais que contas até 20.

| Passo | O quê | Prova |
|---|---|---|
| 20 | Pesquisa de apps de referência e sequência de conteúdo (docs/PESQUISA_APPS_PROGRESSAO.md) | documento com fontes |
| 21 | Trilha por fases (lição × estágio), número e estrelas em cada fase, barra "feitas/total" (ADR-035) | teste test_stages; captura da trilha |
| 22 | Teste para pular: 5 perguntas, quem acerta quase tudo pula 3 fases | teste test_jump_test_skips_three_stages |
| 23 | 9 patentes por fases concluídas, medalha, promoção com festa e voz (ADR-036) | captura evolucao_promocao |
| 24 | 18 lições novas (matemática até tabuada, horas, dinheiro e frações; leitura com dígrafos, frases e textos; lógica) | conferência automática das respostas; 70 capturas revisadas |
| 25 | Ciências e astronomia: +84 perguntas com fatos verificáveis | — |

## v4.1: Próximo
| Passo | O quê | Depende de |
|---|---|---|
| 26 | Leitura com figuras: 100 palavras novas (ler palavra → figura; frases com mais objetos) | lote 2 de arte (docs/ARTE_LOTE_2_PALAVRAS.md) |
| 27 | Mais lógica: quebra-cabeça 4×4 com figuras, labirinto com setas, memória com mais pares | — |
| 28 | Álbum de coleção: um cartão por lição concluída (planeta, bicho, missão) | — |
| 29 | Nivelamento inicial por matéria: 8 perguntas que já colocam a criança na fase certa | — |
| 30 | Relatório para os pais: fases por matéria, erros mais comuns, tempo | — |
