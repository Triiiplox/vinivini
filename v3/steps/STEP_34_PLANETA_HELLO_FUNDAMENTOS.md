# STEP 34 — Planeta Hello (inglês): fundamentos, conteúdo e motor

## Objetivo
Montar a base de um curso de inglês robusto para quem **não lê**: currículo, áudio nativo, figuras,
repetição espaçada e trilha. Leitura obrigatória: `v3/ingles/REFERENCIAS_INGLES.md` e `CURRICULO_INGLES.md`.

## Tarefas
1. Conteúdo:
   - converter `v3/ingles/banco_ingles_seed.json` em `game/content/english/units.json`;
   - completar as unidades 21–30 (canção original + história);
   - validar no `ContentValidator`: cada unidade com ≥ 8 palavras com figura, ≥ 3 frases-chave,
     ≥ 3 comandos de corpo, 1 canção, 1 história e 2 jogos;
   - revisar inglês natural (uso real, sem tradução literal).
2. Voz em inglês:
   - estender `tools/gen_voice.py` com `Lines.en("…")` e vozes Kokoro en-US;
   - Hoppy: voz infantil/aguda, ex. `af_heart` com leve pitch; narradora inglesa só para canções;
   - gerar palavra (normal + lenta), 2 frases de contexto por palavra, frases-chave, comandos e canções
     faladas no ritmo;
   - canções cantadas: melodia FluidSynth + voz falada no ritmo, ou gravação humana (decisão do Andro);
   - escuta humana de 100% das palavras (planilha do STEP 31).
3. Figuras: uma por palavra no estilo da bíblia de arte (STEP 22/23). Verbos com animação de 1–2 s.
4. Motor de repetição espaçada `EnglishSRS`:
   - caixas nova → 1 → 2 → 4 → 7 → 14 → 30 dias;
   - "conhecida" = acerto de primeira em 3 dias diferentes;
   - persistido no save, com testes unitários de relógio simulado.
5. Trilha:
   - tela de mapa com 3 galáxias × 10 planetas × 5 paradas (150 lições);
   - desbloqueio em ordem; revisões aparecem como "cometas" na trilha;
   - planta da constância na nave (cresce, nunca morre).
6. Personagem Hoppy:
   - rig com idle, falar, comemorar e "não entendi" (inclina a cabeça);
   - só fala inglês;
   - o Cosmo dá apoio em português que vai sumindo, com a regra do REFERENCIAS.

## Critérios de aceite
- Validador verde para as 30 unidades.
- 0 falas em inglês sem áudio.
- Testes do SRS: subir, cair, "conhecida", revisões vencidas.
- Trilha navegável com Autoplay.

## Prompt pronto
> Execute o STEP 34. Leia `v3/ingles/`, transforme o banco em conteúdo validado, complete as unidades 21–30,
> gere as vozes en-US, implemente o motor de repetição espaçada, o Hoppy e a trilha das 150 lições.
