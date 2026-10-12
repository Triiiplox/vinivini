# Módulo FALAR (treino de fala em casa)

Complemento do trabalho da fonoaudióloga. **Não avalia nem diagnostica**: o adulto confirma cada fala e o app só
organiza o treino. Os sons ligados e a ordem são escolhidos pelos pais **no aparelho** (área dos pais → aba Fala).
Este repositório é público: nenhum relatório, dado de saúde ou identificação da criança entra aqui.

## Estrutura

| Peça | Arquivo |
|---|---|
| Conteúdo (6 sons, 8 níveis, regras, atividades, 40 exercícios) | `game/content/fono/fono.json` |
| Dados, escolhas dos pais e progresso (migração v2) | `game/src/fono/fono_data.gd` |
| Plano de cada rodada (dose, ordem, sacolas, chuva, trilha, pares, microfone mudo, sessão curta) | `game/src/fono/fono_plan.gd` |
| Sondas, diário, jogos feitos, continuar de onde parou | `game/src/fono/fono_log.gd` |
| Letra-alvo em vermelho (regra por som) | `game/src/fono/fono_text.gd` |
| Peças de tela (pausa, conversa com figura, bolinhas, volume do microfone) | `game/src/fono/fono_panels.gd` |
| Microfone (gravar na memória, ouvir de volta, medidor de chiado) | `game/src/fono/fono_mic.gd` |
| Espelho ao vivo (câmera frontal, nada é salvo) | `game/src/fono/fono_mirror.gd` |
| Rosto que mostra a posição da boca | `game/src/fono/fono_face.gd` |
| Telas: início, casa do som, sessão, academia, sacolas, chuva, trilha, pares | `game/src/fono/fono_*_screen.gd` |
| Parte da área dos pais | `game/src/fono/fono_parent_panel.gd`, `fono_parent_extra.gd` |
| Testes | `game/tests/integration/test_fono.gd`, `test_fono2.gd` |

Sons: CH /ʃ/, J /ʒ/, S /s/, R fraco /ɾ/, TI-DI /tʃ dʒ/, N-D /n d/. Cada um tem 20 palavras com o som no início,
20 com o som no meio, 10 frases e uma história.

## Níveis (por som)

0. **Escutar.** Chuva de palavras (bombardeio auditivo: 15 palavras com figura, só ouvir) mais o Ouvido de detetive.
1. **Som sozinho.**
2. **Sílabas.** Na ordem do contexto facilitador: chu, chô, chi, chá, ché (ju, jô, ji, já, jé).
3. **Palavras fáceis** (v2). Vogal de bico depois do som ("chuva", "judô") ou /i/ antes ("peixe", "beijo"), que
   ajudam quem anterioriza o som (Bonini & Keske-Soares, 2018). O modelo prolonga o som do começo ("chhhuva").
   Som sem lista própria usa as palavras que casam com `facil_re` ou as mais curtas.
4. **Palavras (início).** As fáceis são sorteadas primeiro.
5. **Palavras (meio).** Idem.
6. **Frases.** No fim, o cartão "Conversa com figura".
7. **História.** Idem.

**Passar de nível:** ≥ 80% das figuras confirmadas CERTO em **2 sessões seguidas do nível, em dias diferentes**
(para não promover cedo demais). No máximo 2 tentativas por figura, **sem cronômetro**, sem placar de velocidade
e com elogio sempre.

**Migração (v2).** O progresso salvo antes do nível "Palavras fáceis" não tem `"v": 2`. Quem estava em Palavras
(índice 3) ou acima sobe um índice e continua no **mesmo conteúdo**; o histórico também. Quem estava em Sílabas ou
antes não muda e vai passar pelo nível fácil.

## Jogos

- **Ouvido de detetive.** A narradora diz a palavra certa ou com a troca típica (chave/save, sapo/θapo, cara/cala),
  gerada trocando o fonema no Piper (`fonoerr` em `tools/gen_voice.py`). A criança diz se ouviu "certo" ou
  "esquisito". É treino de percepção do próprio erro, no estilo do SAILS (Rvachew), com pares mínimos.
- **Fala comigo.**
  1. O modelo fala.
  2. A criança fala no microfone (tempo fixo, sem pressa).
  3. Ela ouve a própria voz (automonitorização).
  4. Vê o medidor de chiado.
  5. O adulto toca **CERTO** ou **QUASE**.

  Sem permissão de microfone (ou na TV), ficam só os botões do adulto.
- **Medidor de chiado.** O centroide espectral (o "centro de gravidade" das frequências do ruído) separa /ʃ/ (mais
  grave) de /s/ (mais agudo) também em crianças (Zharkova, Hardcastle & Gibbon, 2018). A fronteira começa em 6 kHz
  e se ajusta às falas que o adulto confirmou. É **pista**, não nota.
- **Academia da boca.** Os exercícios orais que a fono passa para casa. O rosto mostra o movimento, o espelho
  mostra a criança, a narradora conta no ritmo, e as repetições (10, 15 ou 20 por exercício) são escolhidas
  pelos pais. A evidência desses exercícios para a *fala* é fraca; eles entram porque são prescrição da fono
  (tônus e selamento), não como treino de fala.

## v2: dose, percepção, generalização (o que mudou e por quê)

Base: hierarquia fonética tradicional (Van Riper) com bombardeio auditivo (Hodson & Paden), que é o que costuma vir
no programa de casa, mais o que a literatura sustenta para trocas de fala na infância.

- **Fala 3 vezes (P1, dose).** Nos níveis de palavra, cada figura é falada 3× (bolinhas 1-2-3; a narradora diz "de
  novo!", "mais uma!") e o adulto julga **uma vez por figura**. Bloco de 12 figuras = 36 falas; depois uma pausa
  com estrela e um 2º bloco opcional. Os pais escolhem 6/9/12 figuras e 1/3/5 repetições. A literatura fala em
  ~50–100 produções por sessão (Williams 2012; Allen 2013; Baker & McLeod 2011). A 2ª tentativa depois de um QUASE
  é uma fala só. Sem microfone, o botão FALOU acende as bolinhas.
- **Sacolas do som (P4).** Percepção por identificação, no estilo do SAILS (Rvachew et al. 2004): a narradora diz
  a palavra certa ou com a troca (CH × S, CH × J, J × Z, J × CH, via `fonoerr`) e a criança põe a figura na sacola
  da boca que ouviu (arrastar ou tocar na sacola). 10 itens, metade trocada, retorno com a boca animada.
- **Chuva no guarda-chuva (P3).** Som prolongado: a gota anda pela linha só enquanto há chiado do lado CH/J do
  medidor (ou enquanto o adulto segura SEGURE). Sem tempo-limite. Depois a chuva cai numa vogal (u, o, i, a, e) e
  a criança diz a sílaba; o adulto confirma. 5 nuvens.
- **Letra-alvo em vermelho e Trilha de leitura (P6).** Regra por som em `fono_text.gd` (X só quando soa CH;
  G só antes de e/i; C só antes de e/i no S; R fraco só entre vogais ou depois de consoante etc.). A trilha é a
  versão sem pressão do "desafio de palavras por minuto": cada palavra lida é um passo do foguete, sem relógio.
- **Sondas (P7).** A cada 5 sessões (e uma linha de base ao chegar nas palavras), 10 palavras **nunca treinadas**,
  sem modelo, sem letra destacada e sem retorno; o adulto marca. A área dos pais mostra o gráfico "% certo nas
  palavras novas" por data, para fotografar e mostrar à fono (lógica de "provas associadas" do ABAB-Retirada).
- **Vibração J × CH (P8).** `FonoMic.voicing_cue`: chiado + energia abaixo de 500 Hz sem ser vogal = "vibrando".
  Aparece no medidor só para o J. É **pista**, não nota; precisa ser calibrada no aparelho.
- **Academia da boca (P9).** +19 exercícios (ids em `mouth_gym` do JSON). Os com `hold_s` contam "um, dois,
  três" devagar e "solta!" (contagem falada, não cronômetro; PRÓXIMO pula). Os pais montam a **lista do dia**
  como a folha da fono: cada toque num exercício passa por 10 → 15 → 20 → fora, com a data. A evidência desses
  exercícios para a fala continua fraca (Lee & Gibbon 2015; McCauley et al. 2009).
- **Conversa com figura e Diário (P10).** No fim de frases e história: várias figuras do som e a instrução de
  **reformular** (recast) sem pedir para repetir. Diário na área dos pais com toques rápidos e data (usou o som
  sozinho / notei tropeços na fala / estava cansado). Fica só no aparelho; é observação, não diagnóstico.
- **Listas (P11).** CH: + chulé, cochilo, cachimbo, cachecol (e chaveiro, chaminé); J: hoje, monja, gorjeta,
  sujeira e página saíram, entraram pijama, coruja, cereja, tigela, abajur; + jiló, jumento, jabuticaba, jogador.
  Palavras com S/Z no fim da sílaba (churrasco, xadrez, chafariz, juiz) saíram das listas de CH e J: em falares
  como o paulista esse S soa [s] e confunde o modelo. Continuam 20 de início, 20 de meio e 10 frases por som.
- **Me faz pegar! (P5).** Pares mínimos com consequência comunicativa (xis × giz, chá × já, chão × são...): a
  criança pede a figura da estrela, o adulto toca a que ouviu. **Desligado por padrão**: os pais ligam em
  "Pares mínimos (só se a fono concordar)".
- **Sessão curta (P12).** Depois de ~12 min aparece, para o adulto, o aviso de parar (sessões de 10–15 min, uma por
  dia, uns 5 dias por semana; Allen 2013). Sair no meio guarda o bloco e a próxima sessão do mesmo nível continua
  de onde parou.
- **Microfone (TV e celular).** Barrinha de volume ao vivo durante a gravação. Se 2 gravações seguidas vierem sem
  som (ou a permissão for negada), o adulto vê uma vez "O microfone não está captando — continue com os botões
  CERTO/QUASE" e a sessão segue só com os botões.

### Palavras novas sem figura

`FonoData.picture()` procura `res://assets/art/painted/fono/<slug>.png`; sem figura aparece só a palavra escrita.

- **CH (treino):** chulé, chaveiro, chaminé, cochilo, cachimbo, cachecol, queixo, faixa.
- **J (treino):** jiló, jumento, jabuticaba, jogador, pijama, coruja, cereja, tigela, abajur, beija-flor.
- **Sondas CH** (o ideal é figura, para nomear sem ler): chicote, chiqueiro, charrete, boliche, broche, ducha,
  colcha, mexilhão, tacho, rachadura.
- **Sondas J:** jangada, jardim, jornal, gigante, gengiva, garagem, vagem, canjica, pajé, gibi.
- **Pares:** xis, giz, jato (com figura óbvia). Os outros pares (chá/já, chão/são, rocha/roça...) são para ler.

## Privacidade

- **Microfone.** Só na hora. A gravação fica na memória, toca de volta e é descartada; nunca vai para arquivo
  nem para a rede (o app não tem permissão de internet).
- **Câmera.** Só o espelho na tela, nada é gravado.
- **Permissões.** `RECORD_AUDIO` e `CAMERA` estão só no APK de celular. A TV fica sem elas e cai nos botões do
  adulto e no recado "use um espelho de verdade".
- **Foto da família.** A foto do Vini de astronauta na comemoração de nível novo fica em `assets/private/`. Vai
  só no APK da família e o `tools/check_apk.sh` confere isso.

## A validar no aparelho

- Limiar do medidor com a voz real da criança.
- Pista de vibração do J (energia < 500 Hz) e o limiar de "microfone sem som" (pico < 0,02) com o microfone da TV.
- Se a voz Piper chia o S em fim de sílaba (como no carioca) nas frases.
- Câmera frontal no celular (Godot 4.5 tem CameraServer no Android).
- Volume do microfone em ambiente com barulho.
