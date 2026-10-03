# STEP 34 — Gates finais e release

## Objetivo
Só chamar de 10/10 o que a rubrica prova.

## Tarefas
1. Atualizar `docs/RUBRICA_PROGRESSO.md` com evidência por área (link para arquivo, vídeo, log).
2. Rodar e anexar:
   - `tools/run_checks.sh` (TUDO OK);
   - smoke v2 acertando e errando com **todas** as missões;
   - varredura de texto no fluxo da criança;
   - varredura de placeholder;
   - 0 falas sem áudio;
   - `aapt dump permissions` com só VIBRATE e RECORD_AUDIO.
3. Playtest final com o Vini (protocolo do STEP 21) em 3 dias + diário de 7 dias do Fun Gate.
4. Revisão cética escrita (`docs/REVISAO_FINAL.md`): o que um pai exigente, um game designer de app infantil
   e uma fonoaudióloga criticariam hoje, e o que foi feito ou não para cada ponto.
5. Build e versão: versionCode++, os dois APKs (universal e arm64), SHA-256, CHANGELOG, PROJECT_STATUS,
   `CHECKLIST_STATUS` atualizado.

## Critério de release 10/10
Todas as áreas ★ com 10 e evidência; demais áreas ≥ 9 com evidência.
Se não bater: lançar como **v3.x "beta da família"** com as notas reais. Nunca arredondar para cima.

## Prompt pronto
> Execute o STEP 34. Monte a rubrica com evidências, rode todos os gates, escreva a revisão cética e gere a
> release. Se algum gate ★ falhar, não declare 10/10 — liste o que falta e quem precisa agir.
