# Prompts de vídeo e música — Vini: Comandante das Estrelas

Regras para todo vídeo:
- **Formato:** 16:9 deitado, 1280×720 ou 1920×1080, 8 a 10 s, 24 ou 30 fps.
- **Sem texto na tela, sem fala e sem logo.** A voz e a música vêm do jogo.
- **Image-to-video:** use `art_src/vini/vini_v3_front.png` como quadro inicial (ou referência de personagem). Assim o rosto do Vini não muda entre as cenas.
- **Ciência real:** nada de planeta ou bicho inventado.
- **Entrega:** mande o `.mp4`. Eu converto para `.ogv` (Theora, o formato que o Godot toca) e encaixo no jogo. São uns 2–4 MB por clipe em 720p.

## Bloco do personagem (cole no início de TODOS os prompts)

```
Vini, a 4-year-old Brazilian boy, 3D animated feature-film style (Pixar-like), short curly light-brown hair,
big warm brown eyes, light-tan skin, round cheeks, friendly smile. White and navy-blue astronaut suit with
glowing cyan light lines, round shoulder pads, navy gloves and boots, a small golden star on the chest,
navy belt with a cyan buckle. In space he wears a clear glass bubble helmet so his face stays fully visible.
Same face and outfit in every shot. Soft cinematic lighting, vibrant but not neon, child-friendly, no text,
no logos, no speech, 16:9.
```

## Clipes

### 1. Abertura — `intro` (toca na tela inicial; o toque pula)

```
[character block] Night, Vini looks out of his bedroom window at the Moon, then turns to the camera and
smiles. Cut: he runs up the ramp into a white rocket on a launch pad at sunrise. The rocket lifts off with
real-looking smoke and flame, the camera tilts up following it into the blue sky that fades into black
space with stars. Gentle camera moves, 10 seconds.
```

### 2. Missão cumprida — `celebrate` (fim de campanha)

```
[character block] Inside a bright, clean spaceship cabin with round windows showing Earth, Vini jumps with
both arms up, celebrating. Small golden stars burst gently around him like confetti, a friendly small
round flying robot (similar to NASA's Astrobee cube robot) spins happily next to him. Warm, joyful,
8 seconds, loopable ending pose.
```

### 3. Chegada na Lua — campanha `lua`

```
[character block] Vini steps down from a small lander onto the grey surface of the real Moon: grey dust,
craters, black sky, Earth visible as a blue-and-white sphere in the sky. He leaves boot prints in the dust
and does a slow, floaty low-gravity hop. No crystals, no aliens, realistic lunar landscape in animated
style. 8 seconds.
```

### 4. Chegada em Marte — campanha `marte`

```
[character block] Vini on the surface of Mars: rusty red-orange ground and rocks, butterscotch-colored
sky, a six-wheeled rover similar to NASA's Perseverance parked nearby. Vini waves to the rover, the rover
turns its mast camera toward him. Light dust blowing. Realistic Mars in animated style, no aliens.
8 seconds.
```

### 5. Gigantes — campanha `gigantes` (Júpiter e Saturno)

```
[character block] Vini floats at the big round window of his spaceship as it passes Jupiter with its
orange-white cloud bands and the Great Red Spot, then the camera glides to Saturn and its wide rings made
of ice and rock pieces that sparkle in sunlight. Vini points at the rings, amazed. Realistic planets in
animated style. 10 seconds.
```

### 6. Planeta Terra — campanha `terra`

```
[character block] View from a space station orbiting Earth: blue oceans, white clouds, green and brown
continents, the sunrise line crossing the planet. Vini floats weightless inside the station next to a
window, a few water droplets float as spheres near him and he touches one gently. Calm, beautiful,
10 seconds.
```

### 7. Escola de Astronautas — campanha `escola`

```
[character block] A friendly astronaut training room inside the spaceship: Vini wearing the suit without
helmet sits at a round table with colorful number blocks and letter blocks, he places the last block of a
small tower and claps. A woman astronaut in an orange suit gives him a high five. Bright, warm,
encouraging. 8 seconds.
```

### 8. Hora de descansar — tela de limite de tempo

```
[character block] Inside the spaceship at night-time lighting, Vini yawns, takes off his gloves, and
climbs into a sleeping bag strapped to the wall, like real astronauts on the space station sleep. Earth
glows softly through the window, the lights dim. Calm and cozy. 8 seconds, ends on a still frame.
```

Dica: se a ferramenta deixar o rosto "fora do modelo", gere de novo usando a imagem como quadro inicial em vez de só referência. Clipe com dedo a mais, capacete atravessando o cabelo ou texto aparecendo: descarte.

## Música — "Comandante das Estrelas"

**Estilo** (cole no campo de estilo do gerador, ex.: Suno):

```
upbeat children's space pop, Brazilian Portuguese, warm female vocal with kids choir in the chorus,
112 BPM, bright synths, ukulele, hand claps, simple catchy chorus, very clear diction, joyful, for
4-year-olds, no rap, no autotune
```

Gere também a versão **Instrumental** (mesmo estilo). Ela vira o loop da nave e do mapa. A versão cantada entra na abertura e na celebração.

**Letra:**

```
[Intro]
Dez, nove, oito, sete, seis,
cinco, quatro, três, dois, um...
Decolar!

[Verso 1]
Coloquei meu capacete,
apertei o cinto, já!
O foguete faz tremer,
lá vou eu, vou voar!
Lá de cima a Terra é azul,
cheia de água e de mar,
é a nossa casa redonda
que gira sem parar.

[Refrão]
Vini, Vini, comandante das estrelas,
cada missão, uma nova descoberta!
Conta, lê, pensa e vai,
o universo está de porta aberta!
Vamos lá, tripulação!

[Verso 2]
Primeiro a Lua, cinza e quietinha,
cheia de crateras pra contar,
ela não tem luz sozinha,
é o Sol que faz ela brilhar.
Marte é vermelho, cor de ferrugem,
tem um robô lá a passear,
Saturno tem anéis de gelo e pedra
girando, girando sem parar.

[Ponte]
Mercúrio, Vênus, Terra, Marte,
Júpiter, Saturno, Urano, Netuno!
Oito planetas, uma família,
e o Sol, a estrela, no centro de tudo!

[Refrão]
Vini, Vini, comandante das estrelas,
cada missão, uma nova descoberta!
Conta, lê, pensa e vai,
o universo está de porta aberta!

[Final]
Se eu errar, eu tento de novo,
devagarinho eu chego lá,
comandante não desiste,
amanhã tem mais pra explorar!
Missão cumprida!
```

O que a letra ensina (tudo real):
- contagem regressiva de 10 a 0;
- a ordem dos 8 planetas;
- a Lua reflete a luz do Sol;
- Marte é vermelho por causa do óxido de ferro (ferrugem);
- os anéis de Saturno são de gelo e rocha;
- a Terra é azul por causa da água;
- errar e tentar de novo (mentalidade de crescimento).

**Entrega:** mande o `.mp3` ou o `.wav`. Eu corto o loop, normalizo o volume (o mesmo nível das outras faixas) e converto para `.ogg`.

## Personagens: Astro e o pet (substituem os desenhos em vetor)

Use o mesmo processo do Vini, para que eu recorte as peças e monte o rig (esqueleto de animação 2D) do mesmo jeito.
- **Gerador:** o mesmo que você usou para o Vini.
- **Referência de estilo:** anexe `art_src/vini/vini_character_sheet_v2.png` como imagem de referência.
- **Duas imagens por personagem, em 1536×1024:**
  1. A folha do personagem.
  2. A folha de peças.
- **Fundo:** cinza liso e sem texto nas peças. As legendas da folha 1 podem ficar.

### Astro (robô ajudante, quem mais fala no jogo)

Folha 1:
```
Character turnaround sheet, same 3D animated feature-film style and lighting as the reference image of
Vini. "Astro", a small friendly flying helper robot inspired by NASA's Astrobee free-flying robot on the
International Space Station: rounded cube body in white and navy blue with glowing cyan light lines and a
small golden star (matching Vini's suit), a rounded screen on the front that shows a simple cute face (two
big oval cyan eyes and a small smile, drawn as light on a dark screen), two short rounded arms with simple
three-finger grippers, a soft cyan propeller glow underneath instead of legs. Cute, round, not scary,
toddler-friendly. Views: FRONT, 3/4 FRONT, SIDE, BACK. Second row, 8 face-screen expressions: HAPPY, BIG
SMILE, CURIOUS, SURPRISED, SAD, THINKING, PROUD, TALKING. Plain light gray background, 1536x1024.
```
Folha 2:
```
Same robot "Astro", same style, exploded parts sheet for 2D animation on a plain light gray background,
every part separated with space around it, no overlap, no text: body without face, the empty face screen,
left arm, right arm (each as one rounded piece), the cyan propeller glow, then 8 separate face-screen
expressions (eyes + mouth only, cyan light on transparent/dark): happy, big smile, curious, surprised, sad,
thinking, proud, talking (mouth open), plus eyes closed (blink). 1536x1024.
```

### Pet (cachorrinho da tripulação)

Folha 1:
```
Character turnaround sheet, same 3D animated feature-film style and lighting as the reference image of
Vini. Vini's puppy: a small round fluffy light-brown puppy with floppy ears, big shiny dark eyes and a
short wagging tail, wearing a tiny white and navy-blue space vest with glowing cyan lines and a small
golden star (matching Vini's suit), and a cyan collar. Cute, chubby, toddler-friendly. Views: FRONT, 3/4
FRONT, SIDE (walking), BACK. Second row, 8 expressions: HAPPY, TONGUE OUT, CURIOUS (head tilt), SURPRISED,
SAD, SLEEPY, BARKING, LICKING NOSE. Plain light gray background, 1536x1024.
```
Folha 2:
```
Same puppy, same style, exploded parts sheet for 2D animation on a plain light gray background, every
part separated with space around it, no overlap, no text: side-view body with vest (no head, no legs),
head side view without ears, left ear, right ear, front left leg, front right leg, back left leg, back
right leg, tail, then 6 separate eye pairs (open, closed, happy arcs, surprised, sad, looking up) and 6
mouths (smile, tongue out, open bark, small o, sad, closed). 1536x1024.
```
