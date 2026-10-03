# STEP 27 — Escala de conteúdo

## Objetivo
Ir de 12 para **40+ missões** e **6+ chefões** sem perder qualidade.

## Tarefas
1. Novas campanhas, sugeridas:
   - Luas de Júpiter (gelo, contagem até 10, padrões);
   - Cinturão de Asteroides (detetive: pistas por figura e som);
   - Estação Espacial (consertar com o robô);
   - Planeta Jardim (plantar, regar, esperar — causa e efeito);
   - Planeta Eco (módulo de fala, STEPs 28–30);
   - Cometa da Música (ritmo e sequência).
2. Chefões não violentos (fica feliz, acorda, sai do caminho):
   - lógica: porta de padrões;
   - construção: ponte para o gigante;
   - sequência: memória musical;
   - ciência: qual planeta o monstro quer visitar;
   - pilotagem: corrida com o cometa.
3. Variação procedural controlada: cada missão sorteia números, palavras e posições dentro do nível certo,
   para rejogar sem decorar.
4. Ferramenta de autoria: validação no `ContentValidator` + teste que joga **todas** as missões com o Autoplay.
5. Voz: `tools/gen_voice.py` para todas as falas novas; 0 falas sem áudio.

## Critérios de aceite
- ≥ 40 missões e ≥ 6 chefões no JSON, todos jogados pelo smoke (acertando e errando).
- Tempo estimado até completar ≥ 6 h. Medir com o Autoplay em tempo real × fator da criança vindo do
  playtest; declarar o fator usado.

## Prompt pronto
> Execute o STEP 27. Proponha as campanhas (peça OK), implemente os jogos novos que faltarem, gere o conteúdo e
> as vozes e garanta que o smoke jogue tudo.
