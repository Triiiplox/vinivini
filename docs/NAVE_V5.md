# Fases de nave v5 — 24 fases, nave livre, mestres

Pedido do Andro em 11/10: *"jogabilidade ruim, poucas fases, gráficos do poder/suporte fracos, o mestre deveria ser algo legal, muitos bugs, a música do Blaze não tocou"*.

Escolhas dele:
- **nave livre**, seguindo o dedo;
- **24 fases**;
- **poder escolher** entre o modo fácil e o clássico;
- **eu desenho agora + prompts** para a arte pintada.

## O que o robô-criança filmou na v4 (e foi corrigido)

| Bug | Causa | Agora |
|---|---|---|
| Perdia os corações "sem encostar" | Colisão = raio do inimigo **+ 50 px** | Corpo da nave com 26 px de raio, só a cabine. Teste: tiro a 80 px não machuca |
| Fim de jogo em 17 s na fase 1 | 3 corações, colisão com folga, nave em 3 faixas | Modo fácil: escudo de 5, recarrega, e o Astro conserta a nave (a fase nunca acaba) |
| Mestre "renascia" atrás do "Fase completa!" | As ondas rodavam no mesmo quadro da vitória | Estado `won` para tudo na hora. Teste: nenhum mestre novo nasce |
| Número do portal escondido atrás do mestre | Portal em x fixo, com o mestre por cima | Portal nasce na frente do mestre. Teste confere a posição |
| Música do Blaze inaudível | Canal da música a -9 dB, abaixado para -19 dB pela fala do Astro | Canal `Power` próprio, fora do abaixamento. Os efeitos baixam 7 dB enquanto ela toca |
| Mestre era uma pedra cinza girando | — | 6 mestres desenhados, com rosto, ataques e entrada de "ALERTA!" |

## Como joga

- **Pilotar:**
  - arrasta o dedo em qualquer lugar e a nave anda junto;
  - um toque longe da nave faz ela voar até lá;
  - na TV, o analógico ou as setas.
- **A nave atira sozinha.**
- **Cápsulas:**
  - **P** sobe o canhão em 5 níveis: simples, duplo, leque, leque com mísseis que perseguem, leque largo;
  - **A** traz um ajudante: o primo voa junto atirando, até 2;
  - **S** liga o escudo de bolha, que aguenta 3 batidas;
  - **coração** devolve energia;
  - **RAIO** liga o MODO PODEROSO: 8 s invencível, tiro arco-íris e a música da família.
- **Formação vermelha:** robôs entram em V. Se a criança desliga o V vermelho inteiro, ele solta um P, como nos jogos de nave clássicos.
- **Itens com ímã:** perto da nave, o item vem sozinho.
- **Modo fácil** (padrão):
  - 5 escudinhos, que recarregam 1 a cada 9 s;
  - se acabarem, o Astro conserta e a fase segue;
  - estrelas: 3 sem conserto, 2 com um conserto, 1 com mais.
- **Modo clássico:**
  - 3 vidas × 3 escudinhos;
  - perder uma vida também baixa um nível do canhão e tira os ajudantes;
  - sem vidas, "Tente de novo".
- **Escolher o modo:** no cartão "Modo" do menu de fases.
- **Sem violência:** robô atingido "desliga" em estrelas. O mestre vencido fica feliz, vira amigo e vai embora.

## As 24 fases

São 6 planetas, e cada um tem 4 fases:

| Fase | O que tem |
|---|---|
| 1 Patrulha | Ondas de robôs e um mini-mestre (robô gigante) |
| 2 Desafio | Ondas, portal de conta no meio (o canhão sobe) e mini-mestre |
| 3 Resgate | Chuva de meteoros e 2 cápsulas A (o primo vem ajudar), mais mini-mestre |
| 4 Mestre | Ondas curtas, entrada com "ALERTA!" e o **MESTRE** do planeta. Na metade da vida dele aparece um portal de conta que dispara o **tiro especial** |

| Planeta | Inimigo novo | Mestre | Ataques (todo golpe forte avisa antes, piscando ~1 s) |
|---|---|---|---|
| Lua | Bolinha (robô redondo, voa em onda) | **Rei Cratera** | Leque de tiros, olhar-raio na altura da nave, chuva de pedras, filhotes |
| Marte | Seta (forma V) | **Robô Ferrugem** | Leque, garra na altura da nave, filhotes, espiral |
| Júpiter | Olho (mira na nave) | **Olho da Tempestade** | Espiral, raios verticais, leque |
| Saturno | Giro (para e solta 4 tiros girando) | **Senhor dos Anéis** | Anel bumerangue, parede de tiros com uma brecha, leque |
| Urano | Casco (blindado, 7 tiros) | **Rainha de Gelo** | Leque, espinhos de gelo de cima ou de baixo, espiral, filhotes |
| Netuno | Mina (solta 6 tiros quando desliga) | **Polvo Cósmico** | Bolhas em onda, tentáculo, espiral, filhotes, raios |

O mestre fica bravo na metade da vida: muda o rosto, solta fumacinha, ataca mais rápido e com mais tiros.

A dificuldade sobe devagar da fase 1 à 24 (`ShmupLevels.heat`): velocidade, cadência e vida dos inimigos.

O progresso fica em `progress["fases24"]`. A fase seguinte abre quando a anterior ganha estrela.

## Arquivos

- `src/segments/shmup_segment.gd`: jogo (controle, tiro, itens, inimigos, portal, mestre, fim).
- `src/segments/shmup_boss.gd`: os 6 mestres (desenho, rosto e ataques).
- `src/segments/shmup_sprite.gd`: inimigos, cápsulas e tiros inimigos desenhados em código.
- `src/segments/shmup_hud.gd`: escudo, vidas, canhão, barra do mestre, cartão "ALERTA!", faixas de perigo, painel final.
- `src/segments/shmup_levels.gd`: as 24 fases, as falas, o progresso e o modo.
- `src/screens/fly_menu_screen.gd`: menu com os 6 planetas, as 4 fases de cada um, o modo e o voo livre.
- Testes: `tests/integration/test_shmup.gd`.
- Robô-criança filmando: `--playfilm=dir:fase4+deus`.
- Galeria da arte: `--shmupgallery=dir`.

## Prompts para a arte pintada

A arte atual é desenhada em código: contorno escuro, cor viva, brilho. Para trocar por arte pintada no mesmo estilo das naves das crianças, gere cada imagem com as regras abaixo e me mande. Eu recorto e troco.

**Regras gerais (cole em todos os prompts):**

> Ilustração infantil estilo desenho animado 3D suave (Pixar/Nick Jr.), cores vivas, contorno limpo, iluminação de estúdio, **fundo cinza liso #808080**, objeto inteiro centralizado, sem texto, sem sombra no chão, 2048×2048, visto de lado olhando para a ESQUERDA.

**Mestres:** um por imagem. Faça 3 versões de cada (normal, bravo, feliz), no mesmo enquadramento.

1. **Rei Cratera:** uma Lua redonda cinza-lilás com crateras, coroa dourada pequena, olhos grandes e sobrancelhas marotas, 3 pedrinhas flutuando em volta. Bravo: vermelho nas bochechas, dentes cerrados, fumacinha saindo. Feliz: olhos fechados sorrindo, bochechas rosadas.
2. **Robô Ferrugem:** uma cabeça de robô quadrada laranja-ferrugem com rebites, antena com luz vermelha, dois braços com pinças grandes apontando para a esquerda, olhos redondos de tela.
3. **Olho da Tempestade:** uma bola de nuvens azul-turquesa girando, um raio amarelo saindo, rosto no centro.
4. **Senhor dos Anéis:** um planeta bege tipo Saturno com anel inclinado colorido, rosto marotinho no planeta.
5. **Rainha de Gelo:** um cristal hexagonal azul-gelo com coroa de pontas de gelo, rosto no cristal.
6. **Polvo Cósmico:** um polvo espacial roxo com pintinhas, 6 tentáculos ondulando para baixo e para a esquerda, ventosas, olhos grandes.

**Inimigos (robôs bagunceiros fofos, nada assustador):**
- bolinha verde com antena;
- seta vermelha;
- giro roxo com 4 bolinhas em volta;
- pedra-olho laranja de um olho só;
- casco azul-piscina blindado de um lado;
- mina rosa com espinhos de luz amarela.

**Cápsulas:** 4 bolhas brilhantes, com as letras P (amarela), A (azul) e S (azul-claro), e um coração (vermelho).
