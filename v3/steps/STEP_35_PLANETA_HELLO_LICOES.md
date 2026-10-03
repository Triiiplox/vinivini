# STEP 35 — Planeta Hello: lições interativas e jogos em modo inglês

## Objetivo
Cada lição de 5–7 min com a anatomia do `CURRICULO_INGLES.md`. Zero vídeo passivo: a criança age a cada
poucos segundos e o Hoppy reage na hora.

## Tipos de atividade (componentes reutilizáveis, configurados por JSON)
1. **Conhecer**: o objeto ganha vida, a palavra aparece em 3 frases de contexto e tocar repete.
2. **Ouvir e tocar**:
   - progressão de 2 → 3 → 4 figuras e depois cena com distratores;
   - "Touch the red ball" (2 atributos) a partir da galáxia 2.
3. **Faça você (TPR)**:
   - modo avatar: a criança arrasta o comando até o Vini e ele faz;
   - modo corpo: a criança faz e o adulto toca ✓;
   - opcional, só para jump/shake: detectar movimento pelo acelerômetro.
4. **Arrastar com instrução**: "Put the cat **under** the table", "Give the **apple** to Hoppy".
5. **Jogos da nave em modo inglês**: os 11 da tabela do currículo, com flag `language: "en"` nos segmentos
   existentes e as falas trocadas por `Lines.en`.
6. **História interativa**:
   - 6–10 cenas em inglês com escolhas por figura;
   - o Astro resume em português só na 1ª vez;
   - perguntas de compreensão por figura ("Who ate the cake?").
7. **Desafio do Hoppy** (miniboss): mistura comandos de toda a unidade + 3 revisões. Ex.: levar o Hoppy até
   o planeta seguindo instruções faladas.

## Regras
- Erro nunca é "errado": o objeto tocado diz o próprio nome e o certo pisca. Depois de 2 erros, o Astro dá a
  dica em português.
- Mão-guia após 6 s sem ação.
- Cada lição registra por palavra: acerto de primeira, tentativas e tempo, enviados ao `EnglishSRS` e ao Learning Engine (`english.<unidade>`).

## Critérios de aceite
- 7 tipos de atividade implementados e configuráveis.
- As 150 lições jogáveis pelo Autoplay (acertando e errando) no smoke.
- Previews por tipo de atividade.
- Teste de "texto no fluxo da criança" também no Planeta Hello.

## Prompt pronto
> Execute o STEP 35: componentes de atividade, modo inglês dos jogos da nave, histórias, miniboss, integração
> com o SRS, Autoplay e testes. Mostre 1 vídeo de lição completa.
