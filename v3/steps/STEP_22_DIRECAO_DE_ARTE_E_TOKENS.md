# STEP 22 — Direção de arte congelada + tokens + character sheets

## Objetivo
Transformar as pranchas (`v3/arte/referencias/`) numa Art Bible **congelada** antes de qualquer tela.
Leitura obrigatória: `v3/arte/DIRECAO_DE_ARTE.md`, `DESIGN_TOKENS.json`, `CONFLITOS_E_ADAPTACOES.md`.

## Tarefas
1. `docs/ART_BIBLE.md` congela:
   - logo: redesenhado em vetor (SVG) a partir da prancha; nunca recortado do PNG;
   - paleta, grid, tipografia, raios, glow e sombras;
   - família de ícones;
   - estilo e proporções dos personagens;
   - tratamento de cenário e iluminação;
   - partículas;
   - motion language.
2. Tokens no código:
   - `game/src/ui/design_tokens.gd` (constantes) e um `Theme` gerado a partir dele;
   - teste que falha se aparecer cor literal fora do token nos scripts de UI.
3. Fontes OFL: Orbitron, Nunito e Andika (alfabetização), com licenças em `game/assets/fonts/LICENSES`.
4. Character reference sheets aprovados de Vini, Astro, Luna, Apolo, Hoppy e Eco:
   - frente, 3/4, perfil, costas, **e a versão em partes separadas para rig** (requisitos em `RIG_GODOT.md`);
   - 6 expressões, proporções e paleta;
   - gerados via Weave/IA **ou** enviados pelo Andro.
5. 3 telas-chave recompostas para **16:9**, em concept estático fiel às pranchas: nave/hub, mapa galáctico e
   Restaurante de Marte. Aplicam os 3 layouts-base e os conflitos (sem texto obrigatório, sem vidas, sem loja).
6. Decisões registradas em `docs/DECISIONS.md`:
   - rig 100% Godot (já decidido, `v3/arte/RIG_GODOT.md`);
   - renomear Cosmo → Astro;
   - Mobile × Compatibility (decisão provisória até o STEP 32).

## Critérios de aceite
- OK explícito do Andro na Art Bible, nos character sheets e nas 3 telas-chave.
- Tokens no código com teste.
- Sem nenhum elemento listado como conflito.

## Prompt pronto
> Execute o STEP 22. As pranchas são direção de arte obrigatória e o mínimo visual. Congele a Art Bible,
> implemente os tokens, produza os character sheets e as 3 telas-chave em 16:9 e peça aprovação ao Andro. Peça
> também a decisão do nome Astro. O rig é Godot puro (decidido).
