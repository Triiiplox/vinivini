# STEP 24 — Personagens: rig, expressões, lip-sync e biblioteca de animações

## Tarefas
1. Rig **100% Godot 4** conforme `v3/arte/RIG_GODOT.md`:
   - Skeleton2D/Bone2D, Polygon2D com pesos, AnimationPlayer + AnimationTree (state machine + BlendSpace1D);
   - IK nativo, rosto em slots, skins por slot e recolor por shader;
   - movimento secundário (Jiggle ou mola procedural);
   - custo de software R$ 0, sem Spine e sem DragonBones;
   - não reduzir a qualidade por isso.
2. Animações do MVP (marcadas com * na direção de arte) para Vini, e idle/talk/react para Astro, Luna e Apolo.
   O sistema já aceita todas as da biblioteca.
3. Rosto separado (olhos, sobrancelhas, boca) com piscar aleatório e reações.
4. **Lip-sync**: `tools/gen_voice.py` gera markers por fala (A/E/O/MBP/REST) a partir dos fonemas do texto e do
   envelope de amplitude. O runtime troca a boca do personagem que fala.
5. Referência de movimento: pedir ao Andro os vídeos de `v3/arte/PEDIDO_DE_VIDEOS.md` (prioridade 1–10)
   **antes** de animar.
6. Renomear Cosmo → Astro (se aprovado): código, conteúdo e vozes (`gen_voice.py`).

## Evidência
- Vídeo de cada animação do MVP.
- Vídeo de fala com lip-sync.
- Criador de personagem trocando skins ao vivo.
- Teste de que toda fala tem markers.

## Prompt pronto
> Execute o STEP 24 usando só recursos gratuitos do Godot 4 (sem Spine): rig, skins, rosto separado, lip-sync por markers e as animações do MVP. Peça os vídeos de
> referência ao Andro antes de animar.
