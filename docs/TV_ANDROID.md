# Versão de TV — Android TV (TCL) com controle de PS5

O pedido do Andro, em 11/10: *"outra versão para jogar via controle Bluetooth na TCL Android. Não misture."*

## O que é

- É **outro app**: pacote `com.vinicomandante.estrelas.tv`, nome **Vini Comandante TV**.
  - Pode ficar instalado ao lado do app do celular.
  - Não substitui o app do celular.
  - Não compartilha o progresso com ele: o save fica em cada app.
- O mesmo código liga o modo controle só quando o APK tem a feature `tv`.
  - Isso vem do preset "Android TV".
  - No app do celular o `Pad` fica desligado.
- Roda em armv7 e arm64. Muitas TVs TCL usam Android de 32 bits, mesmo com processador de 64 bits.
- Aparece na tela inicial da TV com um banner de 640×360.
  - O export do Godot sem Gradle ignora a opção `show_in_android_tv`.
  - Por isso `tools/tv/tv_patch.sh` faz um pós-processamento: põe no manifesto a categoria `LEANBACK_LAUNCHER` e o banner.
  - Também marca toque, controle e leanback como "não obrigatórios".
  - O script remonta o APK com apktool e assina com a mesma chave.

## Como se joga (controle de PS5 / DualSense)

| Controle | Faz |
|---|---|
| Analógico esquerdo | Move a **estrela**, que faz o papel do dedo |
| Setas | A estrela pula para o botão mais perto naquela direção |
| **✕** (ou qualquer botão da frente: ○ □ △, L1, R1) | Escolher. Segurar e mover arrasta e traça letra |
| **OPTIONS** ou **CREATE** segurado (~1 s) | Volta para a tela principal. Um anel azul enche antes de voltar |
| Jogos de nave | Cima e baixo trocam de faixa; qualquer botão = turbo |
| Controle remoto da TV | Também funciona: setas, OK, e Voltar apertado 2 vezes |

**Por que "qualquer botão" escolhe:**
- Para uma criança de 4 anos, qualquer botão que ela apertar precisa responder.
- Em TV com Android 11 ou mais antigo falta o driver nativo do DualSense (`hid-playstation`, que entrou no Android 12). Nesse caso os botões podem chegar trocados ou com números fora do padrão.
- Como nenhum botão da frente tem papel especial, a troca não atrapalha.
- O botão de voltar é o OPTIONS ou o CREATE, segurados. A criança apertando tudo não sai do jogo sem querer.

Na primeira vez, a tela principal mostra a ajuda "Jogando com o controle", com voz. A ajuda fecha com qualquer botão.

## Instalar na TCL

1. **Parear o controle**
   - Na TV: Configurações → Controles remotos e acessórios → Adicionar acessório.
   - No controle de PS5: segure **PS + CREATE** (o botão pequeno à esquerda do touchpad) até a luz piscar rápido.
   - Escolha "DualSense Wireless Controller" (ou "Wireless Controller").
2. **Liberar a instalação**
   - Configurações → Sistema → Sobre → clique 7 vezes em "Build do Android TV OS" para ativar o modo desenvolvedor.
   - Depois: Configurações → Apps → Segurança → **Fontes desconhecidas**.
   - Libere o app que vai abrir o APK, por exemplo o gerenciador de arquivos ou o "Send Files to TV".
3. **Levar o APK para a TV**
   - **Pendrive**: copie o `.apk` e abra pelo gerenciador de arquivos da TV. Se a TV não tiver um, instale o "File Commander" ou o "X-plore" pela Play Store.
   - **Pela rede**: instale o "Send Files to TV" no celular e na TV, e envie o arquivo.
4. Abra o `.apk` → Instalar. O app aparece na fileira de apps da tela inicial como **Vini Comandante TV**.

**Se o Play Protect pedir:** "Instalar mesmo assim". É o mesmo aviso do app do celular, que é instalado fora da loja.

**Touchpad do DualSense:** no Android 12 ou mais novo, ele pode mover uma setinha do sistema e tocar na tela. Não quebra nada, mas a estrela é o jeito certo de jogar.

## Gerar e testar

```
APKTOOL=/caminho/apktool.jar tools/tv/build_tv.sh completo   # família: só para o Andro, nunca no repositório
APKTOOL=/caminho/apktool.jar tools/tv/build_tv.sh publico    # sem fotos dos convidados e sem a música
tools/run_checks.sh                                          # inclui o teste só com controle (abaixo)
```

O teste só com controle (`--tv --padcheck=`, em 1920×1080) usa apenas eventos de controle.

Telas e navegação:
- A ajuda abre e fecha com △.
- As setas levam ao VOAR, e ○ abre o menu.
- As setas levam à fase 1, e ✕ abre a fase.

Entrada vinda do controle e do controle remoto:
- A seta repetida como tecla pelo Android não anda duas vezes.
- O controle remoto anda.

Nave:
- Seta e analógico trocam de faixa.
- Os botões da frente não saem da fase.
- OPTIONS rápido não sai; OPTIONS segurado volta ao começo.
- Turbo com □ e com um botão de número desconhecido.

Lições:
- Arrastar com ✕ e o analógico.
- Traçar uma letra pelo analógico.

**Limite:** o teste roda sem a TV de verdade. A ordem real dos botões do DualSense na TCL específica só se confirma no aparelho. O jogo foi feito para funcionar com qualquer ordem.
