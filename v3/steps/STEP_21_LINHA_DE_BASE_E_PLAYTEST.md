# STEP 21 — Linha de base: playtest com o Vini + medição honesta

## Objetivo
Medir onde a v2 está de verdade antes de mexer em qualquer coisa. Sem isso, "10/10" é opinião.

## Entradas (pedir ao Andro)
Modelo do aparelho; 3 sessões de 15 min do Vini jogando (gravação de tela opcional); anotações.

## Tarefas do agente
1. Criar `docs/PLAYTEST_PROTOCOLO.md`, uma folha de 1 página para o adulto preencher:
   - por jogo: entendeu sozinho (s/n), onde travou, quantas vezes pediu ajuda, quis repetir (s/n), sorriu/reclamou;
   - regra para o adulto: **não ajudar nos primeiros 30 s** de cada travada.
2. Telemetria local (sem rede):
   - registrar por segmento: tempo até a 1ª ação certa, toques "perdidos" (fora de qualquer alvo), dicas mostradas,
     abandonos (Home no meio), repetições voluntárias, sessões por dia;
   - tela "Diário" na área dos pais e exportação para arquivo local (JSON/CSV) via compartilhar do Android.
3. Varredura automática: teste que percorre todas as telas do fluxo da criança e falha se encontrar `Label`
   visível com texto não-alvo (exceto sílabas/numerais marcados como alvo).
4. Criar `docs/RUBRICA_PROGRESSO.md` com as notas atuais da `v3/RUBRICA_10.md` e "pendente" onde faltar evidência.
5. Depois do playtest: relatório `docs/PLAYTEST_01.md` com os 10 maiores problemas ordenados por impacto,
   cada um com evidência (minuto do vídeo ou dado da telemetria).

## Critérios de aceite
- Telemetria testada (unit) e visível na área dos pais; exportação gera arquivo válido.
- Teste de "texto no fluxo da criança" no `run_checks.sh`.
- `PLAYTEST_01.md` com dados reais **ou** step marcado BLOQUEADO aguardando o Andro (não inventar resultados).

## Anti-padrões
Inventar resultado de playtest; enviar telemetria para fora; perguntar à criança "gostou?" e tratar como dado.

## Prompt pronto
> Execute o STEP 21 do `v3/steps`. Implemente o protocolo, a telemetria local com exportação, o teste de texto
> no fluxo da criança e a rubrica de progresso. Depois peça ao Andro as sessões de playtest e o modelo do
> aparelho. Não preencha resultados de playtest sem dados reais.
