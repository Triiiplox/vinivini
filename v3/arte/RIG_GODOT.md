# Rig e animação de personagens — 100% Godot 4 (custo de software R$ 0)

**Decisão oficial (Andro, 2026-10-03):** sem Spine. Rig e animação só com recursos nativos e gratuitos do Godot 4.

> **Instrução ao agente:** não reduzir a qualidade visual por ausência do Spine. Recriar o pipeline de rig e
> animação usando exclusivamente recursos gratuitos do Godot 4: Skeleton2D, Bone2D, Polygon2D, AnimationPlayer
> e AnimationTree. Quando necessário, implementar movimento secundário procedural. O custo de software de
> animação deve permanecer R$ 0.

Classes confirmadas no Godot 4.5.1 do projeto: `Skeleton2D`, `Bone2D`, `PhysicalBone2D`, `Polygon2D` (com pesos
de osso), `RemoteTransform2D`, `AnimationPlayer`, `AnimationTree` (`AnimationNodeStateMachine`, `BlendSpace1D`),
`SkeletonModificationStack2D` com `Jiggle`, `TwoBoneIK`, `FABRIK`, `CCDIK`, `LookAt` e `PhysicalBones`.
⚠️ As `SkeletonModification2D*` são marcadas como **experimentais** no Godot 4. Use-as, mas tenha fallback
procedural (abaixo) e teste no aparelho.

| Parte | Ferramenta |
|---|---|
| Engine | Godot 4 |
| Rig 2D | Skeleton2D + Bone2D |
| Deformação (dobra de cotovelo, bochecha, roupa) | Polygon2D com pesos de osso (malha), equivalente gratuito das meshes do Spine Pro |
| Animação | AnimationPlayer (clipes) + AnimationTree (state machine + blend de locomoção) |
| IK | TwoBoneIK (braço/perna), LookAt (cabeça/olhos seguindo alvo) |
| Movimento secundário | Jiggle (cabelo, antena, rabo do Apolo, asas da Luna) ou mola procedural em GDScript |
| Rosto | Sprites trocáveis por slot (olhos, sobrancelhas, boca), controlados por timeline e código |
| Lip-sync | Markers JSON (A/E/O/MBP/REST) por fala → troca do sprite de boca |
| Roupas / skins | Camadas trocáveis por slot (Sprite2D/Polygon2D presos aos mesmos ossos) |
| Cinemáticas especiais (opcional) | Synfig Studio (gratuito) → sprite sheet. Só se o rig em tempo real não bastar |
| DragonBones / Spine | Não usar |

## Estrutura do Vini
```
Vini_Rig (Node2D)                      # origem = entre os pés
├── Skeleton2D
│   └── hip (Bone2D)
│       ├── torso
│       │   ├── neck
│       │   │   └── head
│       │   │       ├── hair_root → hair_mid → hair_tip   # jiggle / mola
│       │   │       └── antenna_root → antenna_tip        # (capacete com antena)
│       │   ├── backpack
│       │   ├── arm_left → forearm_left → hand_left
│       │   └── arm_right → forearm_right → hand_right
│       ├── thigh_left → leg_left → foot_left
│       └── thigh_right → leg_right → foot_right
├── Body (Polygon2D com pesos: torso, braços, pernas — dobra suave)
├── Suit (slot: polígonos/sprites do traje presos aos ossos)
├── Boots, Gloves (slots)
├── Backpack (slot)
├── Face (Node2D preso ao osso head via RemoteTransform2D)
│   ├── Eyes      (open, blink, half, happy, sad, surprised)
│   ├── Eyebrows  (normal, curious, angry, sad, surprised)
│   └── Mouth     (neutral, smile, big_smile, O, sad, A, E, MBP, REST)
├── Hair_Back, Hair_Front (slots)
├── Helmet (slot; vidro com shader de reflexo)
├── Accessories (slot)
├── ContactShadow (elipse)
├── AnimationPlayer
└── AnimationTree
```

**Ordem de desenho**: hair_back → arm/leg de trás → body/suit → backpack → arm/leg da frente → head → face →
hair_front → helmet. Use `z_index` por parte e troque a ordem em perfil.

## AnimationTree
- **State machine:** Idle ↔ Locomotion ↔ Jump(Up→Air→Land) ↔ Action ↔ Emote.
- **Locomotion:** `BlendSpace1D` walk ↔ run pela velocidade.
- **Action (one-shot):** pickup, point, build, cook, pilot, celebrate, wave…
- **Emote:** camada de rosto separada da do corpo, para ter corpo andando e rosto feliz ao mesmo tempo.
  Use `AnimationNodeBlend2`/`Add2` ou filtros por trilha.

## Movimento secundário procedural (fallback leve)
Mola amortecida por osso: o ângulo segue o ângulo do pai com atraso, `rigidez` 120–200 e `amortecimento` 10–16
(ajustar por parte). Aplicar em hair_tip, antena, mochila, rabo e orelhas. Custo desprezível e funciona mesmo se
a Jiggle experimental falhar.

## Skins (criador de personagem)
Cada slot tem variantes no atlas, por exemplo `suit_orange`, `suit_blue`, `helmet_bubble`. Trocar a skin = trocar
textura/polígono do slot. Os ossos e as animações são os mesmos para todos. Cor de pele e cabelo por
shader de recolor (máscara) em vez de 6 cópias da arte.

## Arte para rig (requisito ao gerar/redesenhar)
- Partes separadas com sobreposição nas juntas (o ombro "continua" por baixo do braço), PNG com alfa, master 2×.
- Desenho em pose neutra em T suave, frente e perfil (3/4 é a vista padrão do jogo).
- Mesma iluminação em todas as partes. O glow é pintado de forma leve e o restante vem do shader.

## Evidência exigida (STEP 24)
- Vídeo de cada animação MVP.
- Fala com lip-sync.
- Troca de skins ao vivo.
- Cabelo/antena com movimento secundário.
- FPS com 4 personagens em cena no aparelho.
