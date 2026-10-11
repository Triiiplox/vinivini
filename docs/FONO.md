# Módulo FALAR (treino de fala em casa)

Complemento do trabalho da fonoaudióloga. **Não avalia nem diagnostica**: o adulto confirma cada fala e o app só
organiza o treino. Os sons ligados e a ordem são escolhidos pelos pais **no aparelho** (área dos pais → aba Fala).
Este repositório é público: nenhum relatório, dado de saúde ou identificação da criança entra aqui.

## Estrutura

| Peça | Arquivo |
|---|---|
| Conteúdo (6 sons, 7 níveis, regras, 21 exercícios) | `game/content/fono/fono.json` |
| Dados, escolhas dos pais e progresso | `game/src/fono/fono_data.gd` |
| Microfone (gravar na memória, ouvir de volta, medidor de chiado) | `game/src/fono/fono_mic.gd` |
| Espelho ao vivo (câmera frontal, nada é salvo) | `game/src/fono/fono_mirror.gd` |
| Rosto que mostra a posição da boca | `game/src/fono/fono_face.gd` |
| Telas: início, sessão, academia da boca | `game/src/fono/fono_*_screen.gd` |
| Parte da área dos pais | `game/src/fono/fono_parent_panel.gd` |
| Testes | `game/tests/integration/test_fono.gd` |

Sons: CH /ʃ/, J /ʒ/, S /s/, R fraco /ɾ/, TI-DI /tʃ dʒ/, N-D /n d/. Cada um tem 20 palavras com o som no início,
20 com o som no meio, 10 frases e uma história.

## Níveis (por som)

0. **Escutar.** Chuva de palavras (bombardeio auditivo: 15 palavras com figura, só ouvir) mais o Ouvido de detetive.
1. **Som sozinho.**
2. **Sílabas.**
3. **Palavras (início).**
4. **Palavras (meio).**
5. **Frases.**
6. **História.**

Passa de nível com **8 de 10** falas confirmadas pelo adulto. No máximo 2 tentativas por item, **sem cronômetro**
e com elogio sempre.

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
  mostra a criança, a narradora conta no ritmo, e o número de repetições é escolhido pelos pais (5 a 30). A
  evidência desses exercícios para a *fala* é fraca; eles entram porque são prescrição da fono (tônus e
  selamento), não como treino de fala.

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
- Câmera frontal no celular (Godot 4.5 tem CameraServer no Android).
- Volume do microfone em ambiente com barulho.
