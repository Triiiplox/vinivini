# STEP 24 — Animação e "juice" de nível comercial

## Objetivo
Fazer cada toque parecer mágico. É o que separa um app educativo de um jogo.

## Tarefas
1. Animação de personagem: antecipação, exagero, assentamento e olhar seguindo o dedo/objeto. Idle com
   3 variações aleatórias. Andar com poeira, pulo com estica-e-achata, comemoração com 3 variações.
2. Reações do mundo:
   - planetas reagem ao toque;
   - plantas balançam quando o Vini passa;
   - NPCs olham para ele;
   - o Cosmo reage a acerto e erro com animações distintas.
3. Microinterações por objeto interativo:
   - idle sutil;
   - destaque ao tocar;
   - "pega" com levantar e sombra;
   - soltar com quique;
   - encaixe com partícula, som e vibração.
4. Transições com intenção: a nave decola ao ir para o mapa e a porta abre ao entrar na sala.
5. Orçamento de movimento: modo "reduzir efeitos" desliga tremor e flash.

## Critérios de aceite
- Resposta visual a qualquer toque em < 100 ms (medir com log de timestamp).
- Vídeo de 60 s por jogo em `docs/videos/` (captura do Xvfb ou do aparelho).
- Checklist de microinterações por jogo 100% marcado.

## Prompt pronto
> Execute o STEP 24. Implemente as animações e microinterações, meça a latência de resposta ao toque e grave
> os vídeos de evidência.
