# Plano de jogabilidade v5 (para aprovação)

Queixas do Andro (04/10), todas marcadas: lição parece prova, voo e minijogos rasos, falta mundo e história, controle e ritmo.

## Diagnóstico
**Fato (medido no código e no conteúdo):**
- **A lição é ouvir e responder.** São 2,2 s de fala por pergunta (mediana 2,0 s), depois tocar ou digitar. Quando ele acerta, nada muda na tela além do contador e da estrela.
- **A trilha de lições está desligada das missões.** Estudar não abre planeta, não conserta nada e não leva a lugar nenhum.
- **O voo não tem progressão própria:** sem peças para melhorar a nave e sem chefão por planeta.
- **Cozinha, oficina e exploração aparecem uma vez por missão,** sem níveis próprios.

**Inferência (preciso confirmar):** em "controle e ritmo" não sei o momento exato que irrita. A transição entre fases (~1 s) e a fala por pergunta (~2 s) já estão curtas. Suspeito das cenas de missão e da pilotagem (a nave persegue o dedo com atraso), mas não medi.

## Proposta, na ordem recomendada
### 1. Cada fase vira uma missão
Resolve "parece prova" e começa a dar mundo ao jogo. As perguntas e o conteúdo continuam os mesmos; o que muda é o que acontece na tela a cada acerto. São 5 modelos, que se revezam na trilha e usam arte que já existe:

| Modelo | A cada acerto | No fim da fase |
|---|---|---|
| Ponte em Marte | entra uma tábua | o jipe atravessa |
| Foguete | encaixa uma peça | o foguete decola |
| Reator | acende uma célula | a nave liga as luzes |
| Resgate do Bip | abre um cadeado | o Bip sai pulando |
| Coleta | o jipe anda até uma amostra | as amostras vão para o laboratório |

Se ele erra, a peça balança e volta e o Astro dá a dica. O que já foi montado não se perde.

### 2. O mapa da galáxia vira a história
- **Fio da história:** a nave quebrou; para voltar para casa, é preciso consertar uma peça em cada planeta.
- **Capítulos:** cada planeta é um capítulo. O próximo abre com fases feitas nas matérias, e o treino vira combustível.
- **Chefão por planeta:** um desafio misto com conta, leitura e lógica. A fantasia fica só na apresentação; o conteúdo continua sem nada inventado.

### 3. Voo e minijogos com progressão
- **Loja de peças da nave:** escudo, ímã e turbo, compradas com estrelas.
- **Níveis 1 a 5** na cozinha (pedidos maiores, contas de quantidade) e na oficina (projetos novos).
- **Recorde por planeta.**

### 4. Ritmo e controle
- Toque na tela pula a fala.
- A nave segue o dedo sem atraso.
- Alvos de toque maiores.
- O Astro elogia 1 a cada 3 acertos, e não todos.
- **Meta:** de uma pergunta à próxima em até 3 s, medida pelo robô de teste.

## Antes de programar
- Mando 2 ou 3 telas de exemplo do item 1 para aprovação, como combinado.
- A arte nova necessária (tábuas e pilares da ponte, cadeados coloridos, peças da loja) vira o lote 4, com lista e prompts, só depois do OK.
