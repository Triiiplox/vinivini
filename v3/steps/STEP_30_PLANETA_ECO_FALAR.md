# STEP 30 — Planeta Eco: falar com o Eco (microfone + adulto julga)

## Objetivo
Produção do som com **muitas repetições** (meta: 30–60 por sessão), autoescuta e julgamento de um adulto.

## Privacidade e permissão
- Pedir `RECORD_AUDIO` só quando o adulto liga o "Falar com o Eco" na área dos pais. Explicar em
  linguagem simples:
  - o áudio não sai do aparelho;
  - é apagado ao fim da sessão;
  - salvar é opcional, para mostrar à fono.
- `tools/build_apk.sh` passa a aceitar apenas VIBRATE + RECORD_AUDIO. Teste que confirma o apagamento.

## Jogos
1. **Eco repete**: figura aparece → voz modelo diz a palavra → a criança fala → o Eco devolve a **voz da
   criança** com efeito divertido (eco/robô) → festa. Serve para a criança se ouvir e não tem nota.
2. **Sessão com adulto** (modo principal):
   - o adulto segura o aparelho com a criança;
   - depois de cada fala, o adulto toca em um de três botões discretos no canto: ✓ saiu, ~ quase, ✗ ainda não;
   - a criança só vê reação positiva e específica ("Ouvi o chhh!");
   - em ✗, o Eco mostra a metáfora e repete o modelo, nunca diz "errado";
   - contador de produções visível para o adulto.
3. **Pares comunicativos**:
   - a criança pede ao Eco uma figura falando o nome (ex.: "jato");
   - o adulto toca na figura que **ouviu**;
   - se ouviu "gato", o Eco entrega o gato, rindo, e a criança tenta de novo;
   - é o núcleo da abordagem de pares mínimos e funciona sem ASR.
4. **Hierarquia**: som isolado (metáfora) → sílaba → palavra (início) → palavra (meio) → frase com
   figura → recontar a história do STEP 29. Sobe com ≥ 80% de ✓ em 2 sessões; desce com < 50%.

## Dados e relatório
- Por som e por nível: produções, % ✓/~/✗ por sessão, linha do tempo.
- Na área dos pais: gráfico simples e "Levar para a fono": arquivo local com resumo e, se o adulto salvou,
  as gravações. Compartilhar só por ação explícita do adulto.

## Critérios de aceite
- Fluxo completo testado: permissão, gravação, playback, apagamento, julgamento, progressão.
- Autoplay simula o adulto (✓/~/✗) e roda no smoke.
- Nenhuma tela da criança mostra nota/erro.
- Vídeo de uma sessão real de 5 min (Andro + Vini) **ou** step marcado BLOQUEADO.

## Prompt pronto
> Execute o STEP 30. Implemente a permissão de microfone com consentimento, os jogos de produção com adulto no
> circuito, progressão, relatório e exportação local. Sem reconhecimento automático julgando a criança.
