# Checklist v4.2.0 (04/10)

Legenda: ✅ feito e validado · 🟡 parcial · ⏳ depende do Andro ou do Vini jogando.

| # | Item | Status | Evidência / o que falta |
|---|---|---|---|
| 1 | Botões e conteúdo centrados em celular largo | ✅ | 9-slice escalado (o volume encostava na borda); caixa 1280x720 centrada no HUD; capturas 2340x1080. |
| 2 | Tamanho maior (modelo do Andro) | ✅ | HUD 116 px, barra com estrela, fase atual 1,5x com ▶, cadeados dourados, Vini maior, vizinhas abrem espaço. |
| 3 | Pilotagem | ✅ | 3 faixas (0,1 s), jogo pela metade com portais, casa no voo só segurando; teste `lane_y`. ⏳ sentir no dedo do Vini. |
| 4 | Nave em corte (sem corredor) | ✅ | 9 cômodos pintados; robô abre cada um (smoke v2); teste 9 cômodos. |
| 5 | Jornada com 1 objetivo | ✅ | 3 mundos x 8 missões; briefing → voo → 2 atividades; peça por etapa no chip; 5 testes `test_journey`. ⏳ ver se prende o Vini. |
| 6 | Perfis Manuzita, Enzo, Aylinha | ✅ | Tela "Quem vai jogar?", progresso separado, rosto no traje, nome na voz (69 falas). Fotos fora do git. ⏳ ouvir a pronúncia de "Enzo" e "Aylinha". |
| 7 | Lote 3 e universo visual | ✅ | Marte, Europa, 10 ambientes por matéria, cozinha/oficina, baú que abre, mãozinha, portal, jipe sem rodas, Ana/Léo em 4 poses, cliente da cozinha, 24 objetos/coletáveis. |
| 8 | Troféus | ✅ | Tocar na patente (tela principal) abre a galeria. Diário saiu da navegação da criança. |
| 9 | Validação | ✅ | 121 testes; smoke 93/93 (projeto e pacote); robô nas missões 82/82 (projeto e pacote) e 81/81 errando; toques reais e lições mão na massa em 2340x1080. |
| 10 | APK | ✅ | v4.2.2 (code 22), arm64, 87,5 MB (< 100 MB), assinatura igual à anterior (instala por cima), só permissão VIBRATE. |
| 11 | APK público sem fotos | ✅ | `dist/` leva a versão só com o Vini (0 rostos dos convidados no pacote). A versão com os 3 rostos fica fora do repositório até ele ficar privado. |
| 12 | Repositório privado | ⏳ | Andro: deixar privado; depois disso o APK completo e os rostos sobem. |
| 13 | Lote 2 (100 palavras) | ⏳ | Arte do Andro; a leitura é a matéria mais curta sem ela. |
| 14 | Kit de interface e alfabeto do pacote | — | Não usados por decisão: botões chapados com texto pioram para quem não lê botão; o jogo já tem botões pintados com ícone. |
| 15 | Instalação no S23 | ⏳ | Sem retorno ainda. |

# Status honesto — MASTER PRODUCT CHECKLIST (v2.0.0)

Legenda: ✅ feito e testado · 🟡 parcial (o que falta está dito) · ❌ não feito · ⏳ depende de aparelho/criança real.
"Testado" = coberto por teste automatizado, smoke v2 (robô jogador nas 12 missões, também errando de propósito)
ou screenshot revisada. Nada aqui foi validado num Android físico nem com o Vini — isso é o próximo passo.

| # | Seção | Status | Evidência / o que falta |
|---|---|---|---|
| 1 | Stack e arquitetura | ✅ | Godot 4.5.1, GDScript, engines separados (Learning/Content/Story/Reward), JSON, logs locais. Feature flags: só flags de debug por linha de comando. |
| 2 | Tecnologia visual | 🟡 | Tween, GPUParticles2D, shaders (céu, planetas 3D girando, holograma, íris), Parallax2D, câmera com tremor/limites, rigs em camadas. Falta: meteoros ocasionais, PointLight2D em cena, AnimationPlayer (animação é procedural). Arte ainda é vetorial gerada por código — não é ilustração profissional. |
| 3 | UX infantil | ✅ | Fluxo da criança sem leitura obrigatória: tudo por voz, figura e toque; alvos grandes; mão-guia após 6 s parado; botão "ouvir de novo" em toda tela; formas + cores (não só cor). |
| 4 | Criador de personagem | 🟡 | Pele, cabelo, cor do cabelo, traje, capacete, acessório (desbloqueáveis). Falta: corpo, rosto, botas, luvas como peças separadas. |
| 5 | Personagem vivo | 🟡 | Idle, piscar, respirar, andar, correr, pular, comemorar, acenar, surpresa, pensar, apontar, dançar, pilotar. Falta: escalar, empurrar em cena real, reagir a NPC/objeto específico. |
| 6 | Mascotes | 🟡 | Dragãozinho que voa atrás do Vini na nave (cambalhota); robôs/alien/estrela como NPCs com emoções. Falta: habilidade por mascote, mascote ajudando em missão, desbloquear mascotes. |
| 7 | Nave-hub | ✅ | Nave explorável (5 telas de largura): quarto, oficina, cozinha, laboratório, sala do monstro, robôs, observatório, ateliê, cabine (mapa), troféus. Vini anda tocando no chão. Falta: hangar e biblioteca como salas. |
| 8 | Customização da nave | ❌ | Não feito (pintura, motor, luzes, decoração). |
| 9 | Universo e mapa | 🟡 | Mapa da galáxia com 4 campanhas (planetas em shader) e trilha; Sistema Solar navegável no planetário. Falta: luas/estações/cometas/rotas alternativas/mundos secretos. |
| 10 | Trilhas de missão | ✅ | 4 campanhas × 3 missões = 12 missões data-driven (`content/campaign/campaigns.json`), desbloqueio em cadeia. |
| 11 | Game loop | ✅ | Missão → segmentos jogáveis → baú/estrelas/itens → mapa → nave. |
| 12 | Exploração | 🟡 | Andar/correr, coletar contando, porta com cadeado de quantidade, resgate de amigo. Falta: pular plataformas, escalar, cavernas, segredos. |
| 13 | Pilotagem | 🟡 | Pilotar arrastando, desviar de asteroides (sem punição), turbo, portais (número/sílaba/forma), chefão. Falta: escudo, pouso, rotas, corrida, giroscópio. |
| 14 | Construção | 🟡 | Foguete, jipe lunar e reator com contagem de peças + teste da criação (lançar/andar/ligar). Falta: casas, bases, pontes. |
| 15 | Laboratório de invenções | 🟡 | Peças (propulsor, rodas, antena, bateria) dentro da construção. Falta: combinar componentes livremente, experimentos de causa e efeito. |
| 16 | Sandbox | 🟡 | Estações da nave = brincar sem missão: construir, cozinhar, criar criaturas, desenhar, planetário, robôs, monstro. Falta: música livre, jardinagem, pilotagem livre. |
| 17 | Interações | ✅ | Tocar, arrastar e soltar, segurar (porta dos pais), andar tocando, programar sequência. |
| 18 | Alfabetização | ✅ | Leitura pelo som: monstro das sílabas (3 níveis: famílias diferentes → mesma vogal → figura que começa com…), cartões tocáveis, portais de sílaba no chefão. |
| 19 | Escrita | 🟡 | Montar palavra no foguete (sílabas na ordem; nível 1 com letras-guia). Falta: traçado de letras. |
| 20 | Matemática | 🟡 | Contar (construção, exploração, criaturas), numeral (portais), soma (cozinha nível 2), multiplicação intuitiva (cozinha nível 3: dois pratos). Falta no v2: subtração e comparação (existem só nas telas v1). |
| 21 | Lógica | ✅ | Padrões (AB → ABC/AAB → duas lacunas), memória sequencial (planetas cantores), formas. |
| 22 | Programação visual | ✅ | Robô com setas, executar passo a passo, erro mostra onde bateu; 3 níveis (reta, L, pedras). |
| 23–24 | Astronomia / Observatório | ✅ | Planetário com 8 planetas + Sol orbitando, fatos narrados, missões de observação. |
| 25 | Ciência geral | ❌ | Fora dos fatos de astronomia, não feito. |
| 26–28 | Comidas / Restaurante de Marte | 🟡 | Restaurante completo (pedido por voz e figura, tigela, tirar item, sino). Falta: vida prática, nutrição. |
| 29–30 | Sentimentos / Respeito | 🟡 | Histórias com rostos de emoção e escolhas de empatia/cooperação; registro em emotion.recognition. Falta: atividade dedicada de emoções no v2. |
| 31 | Histórias interativas | ✅ | 2 histórias ramificadas, animadas, escolhas por figura (toque = ouvir, toque de novo = escolher). |
| 32–34 | Imaginação / Criaturas / Bestiário | ✅🟡 | Criador de criaturas (cor, forma, olhos/pernas/antenas contando) salvo; criaturas passeiam no laboratório e aparecem nos troféus. Falta: nomear criatura, ficha de bestiário. |
| 35 | Jardim espacial | ❌ | Não feito. |
| 36 | Arte | 🟡 | Desenho livre com cores, pincel e carimbos, salvo na galeria. Falta: colorir desenhos prontos, traçado guiado. |
| 37 | Música e ritmo | 🟡 | Planetas cantores (sequência sonora), trilha de luzes com notas. Falta: criação musical livre, ritmo de sílabas. |
| 38 | Voz e narração | ✅ | Voz neural natural pré-gerada offline (Kokoro, pt-BR): narradora, Cosmo (robótico leve) e NPCs; 529 falas; sem TTS do sistema. Limite: qualidade é a do Kokoro (boa, não de estúdio); nome dito sempre como "Víni". |
| 39 | Sistema de áudio | ✅ | Buses (música/voz/sfx/ambiente), crossfade, ducking da música durante a fala, 10 trilhas FluidSynth, 30+ SFX, 3 ambiências. |
| 40 | Microinterações | ✅ | Tudo reage: pegar levanta, encaixe quica, erro balança, partículas, câmera treme em impacto, íris nas transições. |
| 41 | Haptics | 🟡 | Vibração leve em encaixe, portal certo, estrelas; desligável. Falta: pouso/decolagem/descoberta. (APK pede só VIBRATE.) |
| 42 | Desafios | ✅ | Dificuldade adaptativa por habilidade; coroa no mapa = Desafio de Comandante (+1 nível, sem punição). |
| 43 | Elogio | ✅ | 122 variações por contexto (simples, sequência, persistência, difícil, estratégia por área). |
| 44 | Recompensas | 🟡 | Estrelas, baú, medalhas, capacetes/trajes/acessórios vestidos na hora. Falta: XP, mascotes, peças de nave. Sem lootbox/anúncio/compra. |
| 45 | Boss não violento | 🟡 | 1 chefão: nuvem rabugenta que fica feliz com luz (portais de sílaba), música própria, cena. Falta: chefes de lógica/construção/ciência, várias etapas. |
| 46–47 | Detetive / Caça ao tesouro | ❌ | Não feito. |
| 48–49 | Inventário / Coleções | 🟡 | Guarda-roupa, troféus por campanha, criaturas, desenhos. Falta: minerais, fósseis, artefatos. |
| 50 | Eventos aleatórios | 🟡 | Só o "presente" do desafio da família. Falta: cometas, chamadas de emergência, visitantes. |
| 51–54 | Engines | ✅ | Learning (domínio, sequência, tempo, apoio, revisão espaçada), Content (validação), Story, Reward — com testes. |
| 55 | Área dos pais | 🟡 | Porta por pergunta adulta (segurar cadeado 2 s + conta), tempo de jogo, evolução por área, histórico, sem comparação. Falta: PIN numérico próprio, evolução em gráfico. |
| 56 | Desafio do Papai | 🟡 | Pai escolhe quem envia, habilidade e nível; aparece como presente na nave, voz "O papai mandou um desafio especial!", resultado registrado. Falta: escolher recompensa; a mensagem digitada não é narrada (sem TTS). |
| 57 | Save | ✅ | Perfil, avatar, missões, habilidades, inventário, criaturas, desenhos, ajustes; escrita atômica, backup, versão. |
| 58 | Offline | ✅⏳ | APK sem permissão de internet; tudo embarcado. Teste em modo avião num aparelho: pendente. |
| 59 | Segurança infantil | ✅ | Sem chat, anúncio, link, compra, rastreamento ou IA aberta. |
| 60 | Acessibilidade | 🟡 | Narração de tudo, repetir, volumes, reduzir efeitos, formas além de cor. Falta: modo alto contraste dedicado. |
| 61 | Performance | ⏳ | Áudio comprimido, cache de texturas com orçamento por frame, sem vazamento no soak v1. 60 FPS em Android intermediário: não medido (sem aparelho). |
| 62 | Primeiro minuto | ✅ | Nave chega, Cosmo fala o nome do Vini, monta o astronauta tocando em cores e já liga o motor da nave (missão 1). |
| 63 | Gates | ⏳ | Visual/Interaction/Audio/Learning verificados aqui; Fun Gate e Parent Gate só com o Vini e você. |
| 64 | Regra por missão | ✅ | Cada missão: habilidade registrada, ação física, recompensa, mundo reage (porta abre, cliente come, nuvem sorri). |
| 66 | DoD do MVP | 🟡⏳ | Todos os itens de software ✅ exceto os ❌ acima; "APK instala/abre/modo avião" depende de você instalar. |
