# STEP 28 — Planeta Eco: fundamentos de fala (pesquisa → especificação → triagem para pais)

> Para a criança é o **Planeta Eco**: um planeta onde mora o **Eco**, um alien-papagaio que repete tudo que
> ouve e adora sons. A palavra "fonoaudiologia" não aparece no fluxo da criança. A área dos pais explica
> com clareza o que o módulo é e o que não é.

## Leitura obrigatória antes de codar
`v3/fala/REFERENCIAS_FALA.md` (idades, processos, o que tem e o que não tem evidência) e
`v3/fala/banco_fala_seed.json` (banco inicial, **não validado**).

## Entradas (pedir ao Andro)
1. Região/sotaque da família.
2. Trocas que ele ouve, com exemplos: "sapéu", "zanela", "dato"…
3. Se há fonoaudióloga e se ela aceita revisar o banco.
4. Consentimento para o microfone (só no STEP 30).

## Tarefas
1. **Especificação** `docs/PLANETA_ECO_SPEC.md`. Para cada técnica da seção 2 das referências, definir:
   - o jogo correspondente;
   - a dose (produções por sessão);
   - a progressão: som isolado → sílaba → palavra no início → palavra no meio → frase → recontar;
   - a regra para subir de fase: ≥ 80% certo, julgado pelo adulto, em 2 sessões;
   - a regra para descer de fase.
2. **Banco de fala** `game/content/speech/words.json`, partindo do seed:
   - por palavra: som-alvo, posição, figura, pares mínimos reais, formas trocadas (só para o Eco dizer),
     `validado_por_fono`, `regioes_ok`;
   - validação no `ContentValidator`: par mínimo real deve diferir em 1 som, toda palavra tem figura e áudio.
3. **Triagem para pais** (área dos pais, não é diagnóstico):
   - o adulto mostra 30 figuras (cobrindo /ʃ/ /ʒ/ /s/ /z/ /k/ /g/ /ɾ/ /ʎ/ /ɲ/ /R/, encontros com r e com l);
   - a criança nomeia; o adulto marca certo, trocado ou não falou;
   - o app mostra quais sons estão dentro do esperado para a idade e quais são candidatos a treino;
   - aviso fixo: "Isto não é avaliação. Se houver muitas trocas para a idade, converse com uma
     fonoaudióloga." + a lista de sinais da referência;
   - variação regional configurada **não** conta como troca;
   - a escolha final dos alvos é do adulto ou da fono, com no máximo 2 sons ativos por vez.
4. **Modo fono** (opcional, atrás do PIN): a fono escolhe sons, posições, palavras e dose; o app segue.
5. Vozes: gerar com `tools/gen_voice.py` cada palavra do banco, cada metáfora e cada frase do Eco.
   Conferir de ouvido as palavras com som-alvo: a voz neural pode pronunciar mal palavras isoladas, e isso
   vira modelo errado para a criança. Trocar ou gravar voz humana quando necessário (STEP 31).

## Critérios de aceite
- Especificação aprovada pelo Andro e, idealmente, comentada pela fono.
- Banco validado pelo `ContentValidator`, com todas as palavras com figura e áudio.
- Triagem implementada com testes: regra por idade, região, máximo de 2 alvos.
- Nenhum texto para pais afirma diagnóstico ("seu filho tem...").

## Anti-padrões (proibidos)
- Chamar exercício de assoprar/língua de "treino de fala".
- Julgar a criança por reconhecimento automático de fala.
- Dizer "errado" para a criança.
- Treinar codas regionais por padrão.
- Escolher alvo sem triagem ou sem a fono.

## Prompt pronto
> Execute o STEP 28. Leia `v3/fala/`. Peça ao Andro região, exemplos de trocas e se há fono. Escreva a
> especificação, monte o banco de fala validado e a triagem para pais com avisos corretos. Não implemente
> microfone neste step.
