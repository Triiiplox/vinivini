# STEP 24 — Personagens: rig, expressões, lip-sync e biblioteca de animações

## Tarefas
1. Rig conforme a decisão do STEP 22: Spine (GDExtension) **ou** Skeleton2D/Bone2D + AnimationPlayer.
   - Partes do Vini e skins do criador de personagem, como em `DIRECAO_DE_ARTE.md` §4.
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
> Execute o STEP 24: rig, skins, rosto separado, lip-sync por markers e as animações do MVP. Peça os vídeos de
> referência ao Andro antes de animar.
