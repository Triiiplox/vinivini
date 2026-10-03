# Planeta Eco — especificação (STEP 28)

> Para a criança é o **Planeta Eco**, onde mora o **Eco**, um alien-papagaio que repete tudo e adora sons.
> "Fonoaudiologia" nunca aparece no fluxo da criança. **Isto não é avaliação nem tratamento.**
> Base: `v3/fala/REFERENCIAS_FALA.md`. Banco: `game/content/speech/words.json`, gerado por `tools/build_speech.py`.
> O banco **ainda não foi revisado por fonoaudióloga** (`validado_por_fono = false` em tudo).

## 1. Fluxo
1. **Triagem (área dos pais, aba Fala).** Já implementada:
   - o adulto escolhe a idade e a região da família;
   - para cada uma das 30 palavras, diz a palavra (ou toca em Ouvir) e a criança repete, ou o adulto mostra o objeto;
   - o adulto marca Certo, Trocou, Não falou ou Jeito da região (este só aparece para sons com variação regional);
   - o app agrupa por som e compara com a faixa de idade típica: ok, observar, esperado para a idade ou candidato a treino;
   - o adulto liga no máximo 2 sons para treino.
2. **Planeta Eco (criança)**: só abre com pelo menos 1 som ligado. Sessão curta, de 5–8 min, com o adulto disponível.
3. **Modo fono** (opcional, atrás do PIN dos pais): a fono escolhe sons, posições, palavras e dose. O app segue.

## 2. Técnica → jogo, dose e progressão
| Técnica (evidência) | Jogo | Dose por sessão | Quem julga |
|---|---|---|---|
| Bombardeio auditivo | **Chuva de sons**: o Eco conta a mini-história do som, e cada palavra com o som acende a figura | 1 história (~15–20 palavras-alvo) | — |
| Discriminação / pares mínimos | **Qual é?**: o Eco diz "jato" ou "gato", e a criança toca a figura | 10 pares | o próprio jogo (é percepção) |
| Julgar fala certa × trocada | **O Eco falou certinho?**: o Eco diz "sapéu"; a criança toca 👍 ou 🔁 | 6 itens | o próprio jogo |
| Produção com repetições | **Fala com o Eco**: a criança fala; o Eco grava e devolve a voz dela; o adulto marca ✓ ou ↺ | 30–60 produções (meta: 50+) | **adulto** |
| Pares mínimos comunicativos | **Pede pro Eco**: a criança diz qual figura o Eco deve pegar; o adulto toca o que **ouviu** | 10 pedidos | **adulto** |
| Consciência fonológica | **Começa com chhh?** | 6 itens | o próprio jogo |

**Hierarquia de produção** (uma fase por vez, por som):
1. som isolado com metáfora ("o vento faz chhh");
2. sílaba;
3. palavra com o som no início;
4. palavra com o som no meio;
5. frase curta (frases portadoras: "Eu vejo um ___");
6. recontar a mini-história.

**Sobe de fase:** o adulto marca ≥ 80% de produções certas em 2 sessões seguidas.

**Desce de fase:** < 50% em 2 sessões seguidas, ou o adulto pede. Ninguém "perde" nada: a fase anterior volta como aquecimento.

**Feedback para a criança:** sempre positivo e específico ("Ouvi o chhh!"). O registro de certo e trocado é só do adulto e só aparece na área dos pais.

## 3. Regras fixas
- Sem ASR (reconhecimento automático de fala) julgando a criança.
- Microfone só com consentimento na área dos pais. Áudios ficam no aparelho e são apagados ao fim da sessão, a menos que o adulto salve.
- Variação regional configurada não conta como troca. Codas (r, s e l no fim de sílaba) só entram com indicação da fono.
- Exercícios de assoprar ou de língua podem existir como brincadeira, nunca anunciados como treino de fala.
- Nenhum texto diz "seu filho tem…". Vale o aviso fixo da triagem e a lista de sinais para procurar fono.
- No máximo 2 sons ativos de treino.

## 4. Implementado neste step
- `tools/build_speech.py`:
  - converte o seed em 13 famílias, 353 palavras, 45 formas trocadas e 30 itens de triagem;
  - transcrição fonológica aproximada para conferir pares mínimos: par real = difere em exatamente 1 som;
  - resultado: 75 pares válidos; rejeitados `loja/lousa` e `sal/pá`.
- `SpeechScreening` (motor puro) com testes:
  - regra de idade;
  - inconsistência ("observar");
  - variação regional;
  - máximo de 2 alvos;
  - textos sem diagnóstico.
- Aba **Fala** na área dos pais, com o áudio "Ouvir" de cada palavra.

## 5. Pendências (dependem do Andro e de arte)
- **Perguntas ao Andro:**
  1. Região e sotaque da família.
  2. Trocas que vocês ouvem, com exemplos ("sapéu", "zanela", "dato"…).
  3. Há fonoaudióloga? Ela aceita revisar o banco?
  4. Consentimento para o microfone (STEP 30).
- **Figuras:** as 353 palavras precisam de figura no estilo 3D. Sem figura, a criança não consegue jogar "Qual é?".
- **Personagem Eco:** rig com idle, falar, repetir (eco) e comemorar.
- **Revisão de ouvido:** escutar a voz neural nas palavras com som-alvo (STEP 31) e trocar ou gravar voz humana quando necessário.
