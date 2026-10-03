# STEP 32 — Desempenho no aparelho real

## Objetivo
60 FPS e zero engasgo no aparelho do Vini. Até a v2, nada foi medido em Android.

## Tarefas
1. Overlay de desempenho (atrás do PIN): FPS, tempo de quadro máximo, memória, nº de nós; log em arquivo.
2. Roteiro de medição: abertura, nave (andar até o fim), mapa, 1 missão de cada tipo, 10 transições.
3. Otimizações:
   - pré-rasterizar SVG ou usar atlas PNG (fim da rasterização em tempo de jogo);
   - preload da próxima tela;
   - limitar partículas;
   - shader de céu com qualidade baixa automática se FPS < 50 por 3 s.
4. Medir a abertura a frio.

## Critérios de aceite (no aparelho do Vini)
- FPS médio ≥ 58; nenhum quadro > 50 ms nas transições do roteiro; abertura < 3 s.
- 30 min de uso sem crescimento de memória > 10%.

## Prompt pronto
> Execute o STEP 32: overlay e log de desempenho, roteiro de medição, otimizações e relatório
> `docs/PERF_APARELHO.md`. Peça ao Andro para rodar o roteiro no aparelho e enviar o log.
