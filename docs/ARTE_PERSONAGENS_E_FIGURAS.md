# Arte para criar: personagens e figuras

Este é o inventário completo do que hoje é desenhado em vetor no código e fica feio ao lado do Vini pintado. Levantei a lista em 04/10 a partir do conteúdo real: são as figuras que aparecem nas lições, nas missões e na nave.

## Como gerar (vale para tudo)
- **Gerador:** o mesmo do Vini. Anexe `art_src/vini/vini_character_sheet_v2.png` como referência de estilo em todas as imagens.
- **Tamanho:** 1536×1024, deitado.
- **Fundo:** cinza claro liso, sem textura e sem degradê. É isso que me deixa recortar automaticamente.
- **Sem texto** em cima dos objetos. Nas folhas de personagem, as legendas embaixo podem ficar.
- **Nada encostando:** cada objeto com espaço em volta. Se dois se tocam, o recorte leva pedaço do vizinho.
- **Um objeto por célula**, na ordem da lista: da esquerda para a direita, de cima para baixo. Se vier fora de ordem, não tem problema, eu identifico olhando. Só não pode faltar nem repetir.
- **Me mande o PNG original**, não print da tela.

Bloco de estilo para colar no começo de todo prompt de figura:
```
Same 3D animated feature-film style and soft lighting as the reference image (Vini character sheet):
rounded, toy-like, friendly, bright but not neon, clean shapes readable at small size on a phone.
Plain flat light gray background, no text, no labels, no shadows touching other objects.
```

---

## PRIORIDADE 0: 3 expressões que faltam no Vini (rosto corrigido, 04/10)
A folha `vini_v4_heads_sheet.png` entrou no jogo, mas não tem as caras **bravo**, **com medo** e **cansado**.
- Hoje "bravo" mostra a cara "pensando" e "com medo" mostra "surpreso".
- "Cansado" ainda é o rosto antigo.
- As lições de emoção pedem essas três.

Gere uma grade 3×1 com o mesmo rosto da folha corrigida (anexe a folha como referência). As regras:
- cabeça de frente, olhando reto;
- mesmo tamanho e enquadramento das outras;
- **espaço entre as cabeças**: na folha anterior o queixo de uma encostava no cabelo da de baixo e cortou o topo do cabelo.
```
Same boy, same face, hair and lighting as the reference expression sheet. A 3 columns x 1 row grid of 3
heads only (no body), front view, looking straight at the camera, same size, with big empty space between
heads, transparent or plain light gray background: 1 GRUMPY/ANGRY (frowning brows, pouting lips, cute not
scary), 2 SCARED (eyes wide, eyebrows up, mouth small and tense), 3 TIRED/SLEEPY (heavy half-closed eyes,
small yawn).
```

## PRIORIDADE 1: personagens que aparecem o tempo todo

### 1. Astro, o robô ajudante (2 imagens)
- **Onde aparece:** em quase toda lição e missão. Ele fala, aponta, comemora e se preocupa.
- **Também vai substituir** o robô das lições de emoções, que hoje usa outro boneco feio. Por isso entraram as expressões "bravo" e "com medo".
- **Ciência real:** baseado no Astrobee, o robô voador da NASA que trabalha na Estação Espacial.

Folha 1 (personagem):
```
[bloco de estilo] Character turnaround sheet. "Astro", a small friendly flying helper robot inspired by
NASA's Astrobee free-flying robot on the International Space Station: rounded cube body in white and navy
blue with glowing cyan light lines and a small golden star (matching Vini's suit), a rounded screen on the
front showing a simple cute face (two big oval cyan eyes and a small mouth, drawn as light on a dark
screen), two short rounded arms with simple three-finger grippers, a soft cyan propeller glow underneath
instead of legs. Cute, not scary. Top row: FRONT, 3/4 FRONT, SIDE, BACK. Bottom row, 10 face-screen
expressions: HAPPY, BIG SMILE, CURIOUS, SURPRISED, SAD, THINKING, PROUD, TALKING, GRUMPY (angry but cute),
SCARED.
```
Folha 2 (peças):
```
[bloco de estilo] Same robot "Astro", exploded parts sheet for 2D animation, every part separated with
space around it, no overlap: body without face, the empty dark face screen, left arm, right arm, the cyan
propeller glow; then 11 separate face-screen expressions (eyes + mouth only, cyan light on dark): happy,
big smile, curious, surprised, sad, thinking, proud, talking (mouth open), grumpy, scared, eyes closed.
```

### 2. Bip, o cachorrinho do Vini (2 imagens)
- **Onde aparece:** segue o Vini pela nave e pula quando é tocado.

Folha 1:
```
[bloco de estilo] Character turnaround sheet. Vini's puppy "Bip": a small round fluffy light-brown puppy
with floppy ears, big shiny dark eyes and a short tail, wearing a tiny white and navy-blue space vest with
glowing cyan lines and a small golden star (matching Vini's suit) and a cyan collar. Chubby and cute. Top
row: FRONT, 3/4 FRONT, SIDE (walking), BACK. Bottom row, 8 expressions: HAPPY, TONGUE OUT, CURIOUS (head
tilt), SURPRISED, SAD, SLEEPY, BARKING, JUMPING.
```
Folha 2:
```
[bloco de estilo] Same puppy "Bip", exploded parts sheet for 2D animation, every part separated, no
overlap: side-view body with vest (no head, no legs, no tail), head side view without ears, left ear,
right ear, front left leg, front right leg, back left leg, back right leg, tail; then 6 eye pairs (open,
closed, happy arcs, surprised, sad, looking up) and 6 mouths (smile, tongue out, open bark, small o, sad,
closed).
```

### 3. Robô Reciclador (1 imagem)
- **Onde aparece:** no jogo das sílabas. Ele pede uma sílaba, a criança arrasta o cartão até a boca dele, ele "mastiga" e, se não for a certa, cospe.
```
[bloco de estilo] A friendly round recycling robot for a toddler game, looks like a chubby trash-can-
shaped robot in green and white with cyan lights, big round eyes and a big mouth hatch on the front. Show
4 separate poses side by side, same size and position: MOUTH CLOSED (smiling), MOUTH WIDE OPEN (waiting
for food), CHEWING (cheeks puffed, happy), SPITTING (mouth open, eyes squinting, a small card flying out).
```


### 3b. Rover, o robozinho do jogo das setas (1 imagem)
- **Onde aparece:** no jogo de programar. A criança monta as setas, aperta play e ele anda.
- **Hoje:** é o mesmo robô genérico feio. Vai virar um jipinho inspirado nos rovers reais de Marte (Curiosity e Perseverance).
```
[bloco de estilo] A cute small six-wheeled rover robot inspired by NASA's Mars rovers (Curiosity /
Perseverance): white and navy body with cyan lights and a small golden star, a mast with a friendly
"head" camera that has two big round lens-eyes, six chunky wheels. Show 5 separate poses, same size:
FRONT, SIDE facing right (driving), BACK, HAPPY (head tilted up, lights bright), BUMPED (head shaking,
small dust puff).
```

### 3c. Gato da tripulação (pet de 30 estrelas, 1 imagem)
- **Hoje:** usa a figura parada do gato da folha de palavras. Como pet, precisa andar e reagir.
```
[bloco de estilo] Character sheet of the crew's cat: a small chubby orange tabby cat wearing a tiny white
and navy space vest with cyan lines and a golden star. Poses side by side, same size: SITTING FRONT,
WALKING SIDE facing right, JUMPING, HAPPY (eyes closed purring), SURPRISED (ears up, big eyes).
```

### 3d. Astronautas da tripulação (1 imagem)
- **Onde aparecem:** a cozinha da estação (eles fazem os pedidos), as histórias (a astronauta Ana), as cenas das missões, a tripulação na nave e o professor do Planeta Hello (inglês).
- **Hoje:** usam o corpo do Vini com a viseira abaixada. São adultos do tamanho de uma criança de 4 anos e sem rosto, por isso não convencem.
```
[bloco de estilo] Two friendly adult astronauts, realistic proportions but cartoon style, in modern white
NASA-like spacesuits WITHOUT helmet so faces are visible: 1 "Ana", a Brazilian woman with dark curly hair
in a bun and an orange suit; 2 a man with short dark hair, glasses and a blue suit. For EACH astronaut,
5 poses in one row, same size: FRONT standing, WAVING, TALKING (mouth open, hand gesture), HAPPY (thumbs
up), THINKING (hand on chin). Two rows total, big space between figures.
```

---

## PRIORIDADE 2: figuras das lições (o que a criança lê e conta)
Essas são as figuras mais vistas. Bola aparece em 38 perguntas, lua em 24 e gato em 21.

### 4. Folha de palavras: 20 figuras, grade de 5 colunas × 4 linhas
Cada figura tem que ser a versão mais óbvia do objeto, a que uma criança de 4 anos reconhece na hora. Tem que ser um objeto só, de frente ou em 3/4, sem cenário.
```
[bloco de estilo] A 5 columns x 4 rows grid of 20 single objects, each centered in its own equal cell
with lots of space around it, in this exact order:
1 a red and white ball (bola), 2 a round birthday cake with frosting (bolo), 3 a small house with red
roof and door (casa), 4 a drinking glass with water (copo), 5 a white die showing dots (dado),
6 a yellow five-pointed star (estrela), 7 a tall white rocket (foguete), 8 an orange cat sitting (gato),
9 a crescent moon, pale gray-yellow (lua), 10 a suitcase with handle (mala),
11 a space shuttle orbiter seen from the side (nave), 12 a white chicken egg (ovo), 13 a yellow duck
(pato), 14 an orange fish (peixe), 15 a diamond-shaped Brazilian kite with tail (pipa),
16 a classic toy robot with antenna and square head, gray and blue (robô), 17 a green frog sitting
(sapo), 18 a smiling-free yellow sun with rays, no face (sol), 19 a bunch of purple grapes (uva),
20 a black and white cow standing (vaca).
```
**Conferir:** o sol sem rosto, porque é ciência. A nave tem que ser diferente do foguete. O robô não pode parecer o Astro.

### 5. Folha de comidas: 10 figuras, grade de 5 × 2
- **Onde aparece:** na contagem, na cesta de juntar e tirar e na cozinha da estação.
```
[bloco de estilo] A 5 columns x 2 rows grid of 10 single food items, each centered in its own cell:
1 red apple, 2 strawberry, 3 white mushroom, 4 wedge of yellow cheese, 5 carrot,
6 white egg, 7 red tomato, 8 banana, 9 loaf of bread, 10 small milk carton.
```

### 6. Folha de ciência: 16 figuras, grade de 4 × 4
Hoje são desenhos simples demais. Todas têm que ser cientificamente corretas.
```
[bloco de estilo] A 4 columns x 4 rows grid of 16 separate small scenes, each in its own cell, each with a
small brown soil strip or no ground as described:
1 a seed in soil, 2 a tiny sprout with two leaves in soil, 3 a young plant with several leaves in soil,
4 a plant with pink flowers in soil, 5 a plant with flowers and small red tomatoes in soil,
6 sunny sky icon (sun, no face), 7 a gray cloud with rain drops, 8 a cloud with snowflakes,
9 a dark storm cloud with lightning, 10 an ice cube, 11 a glass of liquid water, 12 a pot with steam
rising, 13 a comet with a long bright tail (icy nucleus, real-looking), 14 a satellite with blue solar
panels, 15 a black hole: black center with a glowing orange ring (like the real Event Horizon Telescope
image), 16 a spiral galaxy seen from above, blue-white with a bright yellow center.
```

---

## PRIORIDADE 3: cenário e missões

### 7. Folha de objetos de missão: 12 figuras, grade de 4 × 3
```
[bloco de estilo] A 4 columns x 3 rows grid of 12 single objects, each centered in its own cell:
1 a glowing cyan energy battery cell, 2 a gray moon rock sample, 3 a gold star coin token,
4 a small signpost, 5 a closed round spaceship door (sliding hatch), 6 the same door open,
7 a lumpy gray asteroid with craters, 8 a white spaceship seen from the side (small, cute, with windows),
9 a round metal food bowl, 10 a glowing cyan reactor core in a metal frame,
11 a small potted green space-garden plant, 12 a leafy plant in a hydroponic tray (like on the ISS).
```

### 8. Peças de montar foguete e jipe: 8 figuras, grade de 4 × 2
- **Onde aparece:** na oficina, onde a criança encaixa as peças. Elas precisam se encaixar umas nas outras.
```
[bloco de estilo] A 4 columns x 2 rows grid of 8 separate parts of a toy rocket and a toy moon rover, all
in the same white/navy/cyan colors and the same scale, flat side view, each centered in its cell:
1 rocket nose cone, 2 rocket body tube (cylinder with a round window), 3 one rocket fin, 4 rocket engine
nozzle, 5 a rover wheel (side view), 6 a small antenna dish, 7 a blue solar panel, 8 a rover body
(box with no wheels, side view).
```

---

## O que você NÃO precisa criar
- **Vini:** pronto, com todas as expressões, inclusive bravo, calmo, com medo e cansado.
- **Astronautas da tripulação** (cozinha e histórias): usam o rig do Vini com outra cor de traje e a viseira dourada abaixada, igual à dos astronautas reais.
- **Planetas e Sol:** já são texturas reais.
- **Fases da Lua, constelações, dia e noite, sombra:** ficam desenhadas pelo código. Precisam de posição exata, e um gerador de imagem erra estrela e fase.
- **Formas, cores, números, letras e ícones de botão:** ficam em vetor. São símbolos, e vetor fica nítido em qualquer tamanho.
- **Robô Ajudante (pet de 15 estrelas):** eu faço a partir do Astro em outra cor. A NASA tem três Astrobees de cores diferentes: Bumble, Honey e Queen.
- **Personagens das atividades de emoção** (alien, estrela com cara, robô): vou trocar pelos rostos do Vini. Rosto de criança real ensina emoção melhor que bicho inventado.
- **Robô das lições de emoção e o robozinho acessório:** viram o Astro.

## Ordem sugerida
| # | Imagem | Quantas | Onde aparece |
|---|---|---|---|
| 0 | Vini: bravo, com medo, cansado | 1 | Lições de emoção |
| 1 | Astro (folha do personagem + folha de peças) | 2 | Quase tudo e as emoções |
| 2 | Palavras (20) | 1 | Toda a leitura |
| 3 | Bip, o cachorrinho (folha do personagem + folha de peças) | 2 | Nave, segue o Vini |
| 4 | Astronautas da tripulação (Ana e colega) | 1 | Cozinha, histórias, cenas, inglês |
| 5 | Comidas (10) | 1 | Matemática e cozinha |
| 6 | Robô Reciclador | 1 | Jogo das sílabas |
| 7 | Rover das setas | 1 | Jogo de programar |
| 8 | Ciência (16) | 1 | Ciências |
| 9 | Gato da tripulação | 1 | Pet de 30 estrelas |
| 10 | Objetos de missão (12) | 1 | Missões |
| 11 | Peças de montar (8) | 1 | Oficina |

São 14 imagens no total. Mande na ordem que conseguir: cada uma que chega eu recorto, encaixo, tiro print e julgo antes de subir.
