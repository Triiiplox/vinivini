# Status dos personagens

## Vini — v3 (atual)

| Arquivo (em `art_src/vini/`) | Status | Uso |
|---|---|---|
| `vini_character_sheet_v2.png` | **APROVADO**: referência oficial | Toda arte do Vini deve bater com esta ficha |
| `vini_v3_front.png` (1086×1448) | **EM USO**: corpo | `cut_figure.py` recorta em camadas: cabeça, ombreiras, braço/antebraço, coxa/canela, tronco. Master a 60% (~840 px) |
| `vini_v3_heads.png` (9 cabeças de frente) | **EM USO**: expressões, bocas de fala e piscar (cabeça 9, olhos fechados) | `faces.py` alinha pela distância entre pupilas e pela linha dos olhos |
| `vini_v3_think.png` / `vini_v3_point.png` | **EM USO**: poses "pensar" e "apontar" | O tronco e o braço pintados substituem o braço do rig durante a ação. Os dedos que passam na frente do queixo ficam numa camada acima da cabeça |

**Curadoria:**
- Nada de rosto montado com peças soltas; cada humor é uma cabeça pintada inteira.
- O alfa "quase 255" da IA é normalizado.
- O cabelo não passa por defringe (a limpeza de cor da borda), porque ela listrava os fios.
- Todas as poses e expressões foram conferidas ampliadas no render do Godot (`--charpreview`), sobre fundo escuro.

**Pipeline:**
1. `cd art_src/vini && python3 cut_figure.py [debug.png] && python3 faces.py && python3 layout.py`
2. `python3 tools/build_character_rig.py vini`
3. Conferir com `--charpreview=<dir>:vini`.

**Pendências:**
- A cabeça "curious" e a "thinking" olham para cima ou para o lado. Na troca de humor o olhar muda junto, como esperado.
- A emenda da coxa no quadril aparece levemente durante o "run".

## Cenários e elenco (em `art_src/scenes/` e `art_src/cast/`)

| Arquivo | Status |
|---|---|
| `scenes/space_sky.png` | Aprovado, vira fundo do espaço |
| `scenes/moon_ground.png` | Aprovado, mas não emenda dos lados; pedida a versão emendável |
| `scenes/ship_interior.png` | Aprovado para tela fixa da nave (está em perspectiva) |
| `scenes/props_v2.png` | Aprovado: pedras sem musgo, cristais, planta e bandeira; recortados em `game/assets/scenes/props/` |
| `cast/cast_alien_astro_food.png` | Referência. É cartoon com contorno, fora do estilo 3D do Vini; pedida a versão 3D |

## Arte que falta para o visual ficar 100% coerente (tudo funciona hoje com arte provisória)

| Prioridade | O quê | Onde aparece |
|---|---|---|
| 1 | Astro em 3D (corpo + 9 rostos de tela) | Em todas as telas |
| 2 | Robôs (explorador, reciclador, robozinho voador) em 3D | Missões, sílabas, mascote |
| 3 | Comidas em 3D (maçã, banana, morango, cenoura, queijo, ovo, leite, pão, tomate, cogumelo) e tigela | Cozinha da estação, lições |
| 4 | Figuras das lições em 3D: animais (gato, pato, vaca, peixe, sapo), objetos (bola, casa, copo, dado, mala, pipa, bolo, ovo, uva), foguete, nave, estrela | Escola de astronautas, leitura |
| 5 | Chão e céu de Marte (Valles Marineris), em camadas emendáveis | Missões de Marte |
| 6 | Corredor da nave emendável | Nave (hoje a pintura é espelhada) |
