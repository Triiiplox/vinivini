# Direção de arte OBRIGATÓRIA — Design System do Vini

As 4 pranchas em `referencias/` são a **direção de arte e o mínimo visual aceitável**:
- design system de telas;
- sistema de ícones;
- marca, personagens e paleta;
- componentes de UI.

**Não são screenshots a reproduzir.** Elas viram tokens, componentes, camadas, sprites, rigs, animações,
shaders e partículas reais no Godot.

> **Regra de FAIL:** se a implementação parecer mais pobre, plana, estática ou genérica do que as pranchas,
> o step é **FAIL** e volta para uma nova rodada de polimento antes de prosseguir.
>
> **Regra de movimento:** nenhuma tela é considerada pronta por screenshot. É obrigatório gravar e revisar
> a sequência **entrada → idle → interação → feedback → sucesso → erro → saída**.
>
> **Onde as pranchas não cobrem** (telas, fases, planetas, jogos novos): seguir a mesma tendência —
> mesmos tokens, mesma família de ícones, mesmo tratamento de luz, glow, profundidade e motion.
> Nada de cada tela inventar seu estilo.

Tokens: `DESIGN_TOKENS.json`. Conflitos das pranchas com as regras do produto: `CONFLITOS_E_ADAPTACOES.md`.

## 1. Orientação e layout
- **Landscape 16:9** (1280×720 lógico, `canvas_items` + `expand`). As pranchas são retrato: recompor, nunca
  esticar.
- 3 layouts-base de jogo:
  - **Mundo**: cena cheia com HUD mínimo nos cantos;
  - **Painel**: cena viva ao fundo + painel holográfico central;
  - **Escolha**: 2–4 cartões grandes de figura.
- Grid de 8 px, margem segura de 40 px e alvo de toque mínimo de **96 px** (criança de 4 anos; a prancha diz
  44 px para adulto).

## 2. Pipelines oficiais
**Gráfico (geral)**

1. CONCEPT (geração de imagem, a partir das pranchas)
2. APROVAÇÃO DE DIREÇÃO DE ARTE (Andro)
3. QUEBRA EM ASSETS
4. LIMPEZA / REDESENHO
5. CAMADAS
6. RIG (Godot Skeleton2D — ver `RIG_GODOT.md`)
7. ANIMAÇÃO
8. EXPORT (atlas + PNG/WebP/SVG)
9. GODOT
10. SHADERS / PARTÍCULAS / LUZES
11. PASSE DE PERFORMANCE
12. JOGO

**Cenários**

1. Concept completo
2. Separar em camadas: sky → far → mid → gameplay → foreground
3. Props
4. Props animados
5. Partículas
6. Luz
7. Shaders

**UI**

1. Design system
2. Tokens
3. Componentes
4. NinePatch
5. Ícones
6. Estados
7. Animações
8. SFX
9. Haptics

**Personagem**

1. Character sheet
2. Partes
3. Rig
4. Expressões
5. Animações
6. Skins
7. Lip-sync
8. Godot

**Cada missão** = gameplay + animação + câmera + SFX + música + voz + partículas + recompensa.

## 3. UI — componentes reais, nunca imagem de tela
Proibido usar `home_screen.png` como tela. Biblioteca:

```
ui/
  buttons/{primary,secondary,icon}/
  panels/  cards/  badges/  bars/  tabs/  icons/  dialogs/  rewards/
```

- **Botões**:
  - estados normal, pressed, focused, disabled, success, warning e rare;
  - `NinePatchRect`/`StyleBoxTexture` (9-slice), nunca uma imagem por tamanho;
  - camadas: base + gradiente + borda com glow + highlight especular + ícone + texto + partícula opcional;
  - toque: 1,00 → 0,94 → 1,03 → 1,00 em 180–250 ms, com som curto, haptic pequeno e glow reagindo.
- **Painel**: abre em 250 ms (alpha, escala 0,92 → 1, y +20 → 0) e fecha em 150 ms (escala → 0,96, alpha → 0).
- **Ícones**: SVG como master, uma só família: o estilo 3D brilhante da prancha 02. Pastas: navigation,
  missions, rewards, reading, math, astronomy, food, emotions, construction, parents, settings.
  Proibido misturar flat, emoji, Material Icons ou ícone 3D de outra família.
- **Variações de container** (prancha 02): preenchido, contorno, circular e hexagonal.
- **Texto na UI da criança**: ver conflitos. O botão JOGAR existe como componente com ícone ▶ e voz; o texto
  é opcional/decorativo.

## 4. Personagens
- Elenco das pranchas (marca):
  - **Vini** (comandante);
  - **Astro** (robô companheiro, substitui o Cosmo);
  - **Luna** (dragoa cósmica);
  - **Apolo** (cão espacial, um corgi).
- Elenco próprio que segue a mesma tendência: Hoppy (inglês), Eco (fala), NPCs e chefões.
- **Primeiro o character reference sheet** de cada personagem (frente, 3/4, perfil, costas, expressões,
  proporções, paleta). Só depois partes e animação. Nunca gerar poses isoladas: viram personagens diferentes.
- **Partes do Vini**: HEAD, HAIR_BACK, HAIR_FRONT, EYES, EYEBROWS, MOUTH, TORSO, ARM_L, ARM_R, HAND_L, HAND_R,
  LEG_L, LEG_R, BOOT_L, BOOT_R, BACKPACK, HELMET, ACCESSORY. Skins trocam roupa, capacete, cabelo, mochila e
  acessório (criador de personagem).
- **Biblioteca de animações**: o sistema nasce preparado para todas; o MVP prioriza as marcadas com *.
  - Básicas: idle_01*, idle_02, idle_curious, walk*, run*, jump*, land*, climb, push, pull, carry.
  - Emoções: happy*, super_happy, curious, surprised*, sad*, frustrated, thinking*, proud, scared, excited, laugh.
  - Jogo: pickup*, use_terminal, build*, repair, cook*, scan, point*, read, write, pilot*, celebrate*,
    celebrate_epic.
  - Social: wave*, hug, high_five, talk*, listen, give_item.
- **Rosto separado**:
  - olhos: open, blink, half, happy, sad, surprised;
  - sobrancelhas: normal, curious, angry, sad, surprised;
  - boca: neutral, smile, big_smile, O, sad, talk_A, talk_E, talk_O, MBP, REST.
- **Lip-sync simplificado** (A, E, O, M/B/P, REST) por markers JSON por fala, gerados no build a partir dos
  fonemas do texto + envelope de amplitude do áudio. O personagem que fala move a boca, pisca e reage com a
  sobrancelha.
- **Rig (decisão oficial)**: 100% Godot 4 — Skeleton2D + Bone2D + Polygon2D com pesos + AnimationPlayer/AnimationTree,
  IK nativo e movimento secundário (Jiggle ou mola procedural). Sem Spine; custo de software R$ 0. Detalhes:
  `RIG_GODOT.md`. Não reduzir a qualidade por causa disso.

## 5. Cenários (nunca uma imagem única)
- Toda imagem gerada por IA é **desmontada** em camadas com transparência. Exemplo para Marte: sky, mountains_far,
  mountains_near, ground, rocks_01/02, crystals, building_01/02, fog.
- Parallax de referência:

| Camada | Fator |
|---|---|
| Nebulosa | 0,05 |
| Estrelas | 0,10 |
| Planeta | 0,15 |
| Montanhas | 0,35 |
| Construções | 0,60 |
| Personagem | 1,00 |
| Primeiro plano | 1,20 |

- **Mundo vivo**: pedra brilha quando o Vini passa, cristal pulsa, NPC olha, Astro acompanha com os olhos, porta
  acende a luz, máquina responde.
- **Loops de ambiente**: star_twinkle, cloud_move, plant_sway, hologram_flicker, light_blink, robot_idle,
  planet_rotate, crystal_pulse, water_move, flag_wave.

## 6. Efeitos
- **Partículas** (GPUParticles2D, com CPUParticles2D no nível LOW): stars, dust, sparks, rocket_smoke,
  rocket_fire, crystal_glow, portal, confetti, magic_dust, snow, rain, leaves, energy, asteroid_dust.
- **Shaders reutilizáveis**: hologram, glow, portal, energy, shield, star_twinkle, water, nebula, crystal,
  outline, dissolve.
  - Holograma = scanlines + distorção + flicker + transparência + glow ciano. Usado quando o Astro aparece
    como transmissão.
- **Glow**: 60–70% pré-renderizado no asset e 30–40% em tempo real. Nada de blur/bloom em tudo o tempo todo.
- **Níveis de qualidade** LOW/MEDIUM/HIGH escolhidos automaticamente pelo FPS medido.

## 7. Câmera, cinemáticas e transições
- **Câmera**: follow suave, look-ahead, zoom contextual, shake leve, pan cinematográfico, foco e slow zoom.
  Câmera fixa só em telas de painel.
- **Cinemáticas curtas em tempo real** (3–6 s), nunca vídeo. Exemplos:
  - chegada a Saturno: nave entra → planeta aparece → câmera abre → música sobe → Luna olha;
  - chefão: o som para, zoom, pan até o chefão, o Astro diz "Ahhh… Vini?".
- **Transição entre planetas**: o planeta cresce, a câmera vai até ele, a nave aparece, os motores ligam,
  vem o warp (estrelas viram riscos) com WHOOSH, depois a atmosfera do planeta, o pouso e o Vini sai. Isso
  mascara o carregamento.
- **Loading é experiência**: a nave viaja e o Astro conta uma curiosidade com voz ("Um dia em Marte dura quase
  o mesmo que um dia na Terra!").
- **Recompensa proporcional**: fácil ⭐, médio ⭐⭐, difícil ⭐⭐⭐ + partículas, comandante/chefão = cinemática +
  música + animação + item raro.

## 8. Produção e performance
- Masters em 2× ou 4× do uso (personagem 2048–4096 px). Export otimizado em atlas por grupo:
  vini_body, vini_clothes, astro, mars_environment, ui_icons…
- As pranchas têm 1055×1491 px: servem de referência, **não** de fonte de recorte. Todo asset é regenerado ou
  redesenhado em alta resolução.
- **Renderer**: avaliar **Mobile** (Vulkan) com fallback automático para Compatibility (Godot ≥ 4.4,
  `rendering/rendering_device/fallback_to_opengl3`). Medir os dois no aparelho do Vini antes de decidir.
  Hoje o projeto está em Compatibility.
- **Gates no aparelho real**:
  - 60 FPS como objetivo e 30 FPS como mínimo em hardware fraco;
  - quadro-alvo de 16,6 ms, sem engasgo perceptível no jogo normal;
  - medir RAM, carga, GPU, partículas, draw calls e tamanho das texturas.

## 9. Vídeos que o Andro pode gerar (oferecido por ele)
Uso: **referência de movimento** para animar o rig (timing, arcos, exagero). Não entram como vídeo no jogo.
Pedidos detalhados em `PEDIDO_DE_VIDEOS.md`. O agente pede quando chegar no STEP 24.
