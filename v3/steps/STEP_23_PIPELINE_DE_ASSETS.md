# STEP 23 — Pipeline de assets (concept → camadas → atlas → Godot)

## Objetivo
Produzir a arte final de todo o fluxo da criança com consistência. Nada de JPEG inteiro como cenário.

## Tarefas
1. Pipeline documentado e automatizado (`tools/assets/`):
   - convenção de nomes e pastas;
   - masters 2×/4×;
   - export WebP/PNG com alfa, SVG para ícones;
   - atlas por grupo (vini_body, vini_clothes, astro, luna, apolo, <planeta>_environment, ui_icons);
   - script de validação: tamanho, alfa, nome, presença no atlas, nada de PNG solto não usado.
2. Prompts de geração versionados em `art_src/prompts/` (para reproduzir), sempre referenciando o character
   sheet e as pranchas, nunca "gere o Vini pulando" solto.
3. Cenários de todos os planetas desmontados em camadas:
   - sky, far, mid, gameplay, foreground;
   - props e props animados.
4. Substituir **toda** a arte gerada por código da v2 (SvgArt/art2.json) por assets do pipeline. Teste que
   falha se uma tela da criança ainda usar o gerador antigo.

## Critérios de aceite
- 0 placeholder (varredura).
- Prancha de screenshots 16:9 de todas as telas em `docs/screenshots/v3/`.
- Comparação com as pranchas aprovada pelo Andro.
- APK arm64 medido e justificado (meta ≤ 80 MB).

## Prompt pronto
> Execute o STEP 23: monte o pipeline de assets com masters, camadas, atlas e validação, gere/limpe/exporte
> toda a arte seguindo a Art Bible e troque a arte v2 em todas as telas da criança.
