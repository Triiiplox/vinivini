# Planeta Hello — currículo e anatomia das lições

Banco: `banco_ingles_seed.json` — 30 unidades, 304 palavras (285 únicas), 84 frases-chave, 97 comandos de
corpo (TPR) e 30 canções/cantigas. As unidades 1–19 estão completas. As 21–30 têm palavras, frases e
comandos, mas faltam letra de canção e história, a escrever no STEP 34. A 30 é a revisão final.
Meta de longo prazo: cobrir a lista Cambridge Pre A1 Starters (~500 palavras).

## Mapa (estilo trilha, como o Duolingo, mas sem ler)
- 3 galáxias:
  - **Galáxia 1**: unidades 1–10 (eu, cores, números, animais, corpo, comida, brinquedos, espaço, ações, família);
  - **Galáxia 2**: 11–20;
  - **Galáxia 3**: 21–30.
- Cada unidade é um planeta com 5 paradas na trilha. Total: **150 lições** de 5–7 min.
  1. **Conhecer**: apresentação das palavras.
  2. **Brincar**: jogo de ouvir e tocar + TPR.
  3. **Missão**: um jogo da nave em modo inglês.
  4. **Cantar e contar**: canção + história interativa.
  5. **Desafio do Hoppy**: miniboss que mistura tudo e revisa unidades anteriores.
- Baú a cada planeta, um item do Hoppy (chapéu, mochila de alien) e a planta da constância na nave.

## Anatomia de uma lição (5–7 min)
| Momento | Duração | O que acontece | Por quê |
|---|---|---|---|
| Aquecimento | 30–45 s | 3 palavras antigas devolvidas pelo motor espaçado: "Find the **cat**!" | Recuperação espaçada |
| Conhecer | 1 min | Hoppy mostra o objeto vivo, diz a palavra 3× em contexto ("A cat! The cat is sleeping. Meow, cat!"). Na 1ª exposição, o Cosmo sussurra "gato" | Entrada compreensível; apoio em português que vai sumindo |
| Ouvir e tocar | 1–1,5 min | 2 → 3 → 4 figuras: "Touch the **dog**". Errou: o objeto tocado diz o próprio nome ("I'm a cat!") e o certo pisca | Compreensão antes da fala; erro vira aprendizado |
| Fazer (TPR) | 1 min | "Jump like a frog!": o avatar faz quando a criança toca nele, e no modo corpo o adulto confirma | Movimento e linguagem juntos |
| Jogar | 1–2 min | Jogo da nave em modo inglês (lista abaixo) | Usar a palavra para resolver algo |
| Falar (opcional) | 30–60 s | Hoppy pede "Say *cat*!"; grava e devolve a voz; o adulto pode marcar ✓ | Produção sem julgamento automático |
| Fechar | 30 s | Trecho da canção + festa + baú/planta | Afeto e ritual |

## Jogos da nave em modo inglês (reaproveitamento barato e robusto)
| Jogo existente | Modo inglês |
|---|---|
| Restaurante de Marte | Clientes pedem "I want **three** **apples**, please!" (inglês + matemática) |
| Construção | "Give me the **wheel**!" / "Four wheels, please!" |
| Pilotagem | "Fly through the **blue** portal!", "Faster!", "Up! Down!" |
| Robô programável | Comandos falados "**up**, **down**, **go**, **stop**" ligados às setas |
| Planetas cantores | Cada planeta canta uma cor/número em inglês; repetir a sequência |
| Trilha de luzes | Padrões de formas e cores com nome em inglês |
| Criador de criaturas | "Give it **two eyes** and **four legs**!" |
| Exploração | "Find the **cat**!", "Open the **door**!", "Where's the **ball**? Under the **table**!" |
| Monstro comilão | "Feed me the **banana**!" |
| Planetário | "Touch the **moon**!", "Where's the **sun**?" |
| Histórias | Versões curtas em inglês com escolhas por figura |

## Motor de repetição espaçada (por palavra)
- Caixas: nova → 1 dia → 2 → 4 → 7 → 14 → 30.
- Acerto de primeira sobe uma caixa; erro volta para a caixa 1 (sem aviso de erro para a criança).
- Cada lição puxa até 3 revisões vencidas no aquecimento e mistura mais 2–3 no jogo.
- "Palavra conhecida" = acerto de primeira em 3 dias diferentes, último intervalo ≥ 7 dias. É o que o painel
  dos pais conta.

## Regras de produção de conteúdo
- Figuras do mesmo estilo da bíblia de arte. Uma figura por palavra; verbos com animação curta.
- Áudio: palavra isolada (normal e lenta), palavra em 2 frases de contexto, frases-chave, comandos e canções.
- Toda unidade precisa de: ≥ 8 palavras com figura, ≥ 3 frases-chave, ≥ 3 comandos TPR, 1 canção, 1 história,
  2 jogos em modo inglês, 1 miniboss.
- Validação automática no `ContentValidator`: figura, áudio, unidade completa.
