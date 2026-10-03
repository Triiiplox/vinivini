# STEP 31 — Voz 2.0: escuta humana e opção de voz real

## Objetivo
A v2 tem 529 falas neurais que **ninguém ouviu de ponta a ponta**. No Planeta Eco a voz é modelo de
pronúncia; uma palavra mal pronunciada ensina errado.

## Tarefas
1. Ferramenta de escuta (debug, atrás do PIN): toca cada fala em sequência; o adulto marca ok/ajustar
   com um toque; gera `docs/ESCUTA_VOZ.csv`.
2. Correções por fala marcada:
   - reescrever a frase (grafia fonética, vírgulas para respiração);
   - trocar a voz ou a velocidade;
   - gravar humana.
   `gen_voice.py` aceita `overrides.json` (fala → arquivo gravado).
3. **Opção de voz humana**: modo "Grave a voz da família" na área dos pais:
   - o adulto grava as falas mais frequentes, guiado pelo texto;
   - as gravações viram arquivos locais que substituem as neurais.
   Ideal para o Planeta Eco: o modelo de pronúncia é a voz do pai/mãe.
4. Mixagem medida no aparelho: voz sempre ≥ 9 dB acima da música durante a fala (ducking ajustável).
5. Nome falado configurável: hoje é sempre "Víni". Gravar o nome na voz do adulto e usar no lugar.

## Critérios de aceite
- `ESCUTA_VOZ.csv` com 100% das falas ouvidas e 0 "ajustar" pendente nas falas do fluxo principal e do
  Planeta Eco.
- Teste: fala com override usa o arquivo gravado.

## Prompt pronto
> Execute o STEP 31: ferramenta de escuta, overrides de voz, gravação de voz da família e ajuste de mixagem.
> Peça ao Andro a sessão de escuta (uns 30–40 min).
