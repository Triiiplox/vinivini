# Fases de nave: regras de design

As regras vêm de shmups (jogos de nave de tiro) consagrados e foram adaptadas para crianças de 4 a 6 anos. A pesquisa foi feita em 12/10. O motivo foi o feedback do Andro: "o mestre aparece e some como se eu tivesse vencido… a jogabilidade tá horrível".

## O bug do mestre que sumia

Na luta, o portal do **tiro especial** aparecia na metade da vida do mestre. Esse tiro fazia duas coisas:

- tirava 30% da vida do mestre;
- ligava 8 s de **modo poderoso**, que dispara 7 tiros de dano 2 a cada 0,1 s (cerca de 140 de dano/s).

O mestre tinha cerca de 100 de vida e caía em menos de 1 s. Pegar o RAIO antes da luta fazia o mesmo.

## Mestre (`ShmupBoss`)

Referências:

- **Touhou:** cada padrão de ataque tem um relógio.
- **Shippu Mahou Daisakusen:** teto de dano por tick.
- **R-Type** e **Sky Force:** fases e ponto fraco.
- **Guias de design de chefe** (Game Developer, shmups.system11):
  - a barra de vida é dividida em segmentos;
  - o chefe fica invulnerável na troca de fase.

Regras no jogo:

- **3 fases**, que trocam em 66% e 33% da vida. Cada fase tem o seu conjunto de ataques:
  - a 1ª usa os 2 primeiros;
  - a 2ª usa os do meio, mais rápidos;
  - a 3ª usa todos e é a mais rápida.

  A barra mostra as marcas das fases.
- **Escudo de 2 s** na entrada e em cada troca de fase:
  - o tiro faz "tink" e não tira vida;
  - os tiros do mestre que estão na tela viram estrelas;
  - a tela pisca e o Astro avisa.
- **O dano nunca atravessa a fase**: a vida para no limite e a fase seguinte só começa depois da troca.
- **Teto de dano por segundo** = vida ÷ 40 s. Nem o modo poderoso nem o tiro especial derrubam o mestre antes de cerca de 40 s. O tiro especial agora tira 10% da vida, e o teto também vale para ele.
- **Relógio de 25 s por fase**: se a criança não acerta, o mestre "cansa" e passa de fase. Na última fase, ele vira amigo. A luta nunca dura mais que cerca de 1,5 min, e a criança nunca fica presa.
- O teste `test_shmup_boss_lasts_and_has_phases` cobre isso:
  - fogo máximo dura de 38 a 85 s e passa pelas 3 fases;
  - sem dano nenhum, o mestre cansa em até 90 s.

## Robô gigante (mini-mestre)

- Teto de dano de cerca de 18 s de luta no mínimo, enchido em `ShmupFx.mini_tick`.

## Nave

- Depois de apanhar, a nave fica **2,2 s** piscando e sem levar dano. A pesquisa recomenda de 1 a 2,5 s para crianças.

## Ainda não feito (próximos passos da pesquisa)

- **Ritmo das ondas em "dente de serra":** pico de 8 a 12 s, respiro de 5 a 8 s, e o portal de conta sempre no respiro.
- **Ao levar dano, perder no máximo 1 nível de canhão.** O "P" perdido cai piscando e dá para pegar de volta.
- **Ajuda dinâmica:** se a criança apanha 2 vezes em 30 s, ganha escudo; se apanha, os tiros ficam 20% mais lentos por 20 s.
- **Ponto fraco ou partes destrutíveis no mestre**, como os canhões que caem em Sky Force.

## Fontes

- https://www.gamedeveloper.com/design/video-game-boss-design-for-shmups
- https://www.gamedeveloper.com/design/designing-smart-meaningful-shmups
- https://shmups.wiki/library/Boghog's_bullet_hell_shmup_101
- https://shmups.wiki/library/Shippu_Mahou_Daisakusen/Strategy
- https://shmups.wiki/library/R-Type/Strategy
- https://shmups.system11.org/viewtopic.php?t=44816
- https://itch.io/post/9107785
- https://developers.google.com/building-for-kids/designing-engaging-apps
