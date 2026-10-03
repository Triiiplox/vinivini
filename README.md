# Vini: Comandante das Estrelas

Jogo educativo infantil **offline**, tema espacial, para o Vini (4 anos): leitura, matemática, lógica,
histórias, emoções/respeito e astronomia. Sem anúncios, sem compras, sem internet, sem coleta de dados.

## Instalar no Android (o que importa)
1. Copie **`dist/ViniComandante-v2.0.0.apk`** (universal) para o celular/tablet (Android 7+).
   Em celulares de 64 bits também serve o `ViniComandante-v2.0.0-arm64.apk` (menor).
2. Abra o arquivo e permita "instalar de fontes desconhecidas" quando o Android pedir.
3. A voz já vem dentro do jogo (não precisa configurar nada, funciona em modo avião).
4. Área dos pais: na nave, **segure o cadeado (canto superior esquerdo) por 2 segundos**.

Atualizações futuras devem ser assinadas com `game/android/vini-sideload.keystore` para instalar por cima
**sem perder o progresso** (ver docs/DECISIONS.md ADR-014).

## O que tem no jogo (v2)
- Feito para quem **ainda não lê**: tudo é dito pela narradora/Cosmo; tocar no alto-falante repete;
  uma mão animada mostra o que fazer se a criança fica parada.
- **Nave explorável**: o Vini anda pela nave e entra nas salas (quarto/guarda-roupa, oficina, cozinha,
  laboratório de criaturas, monstro das sílabas, robôs, observatório, ateliê, troféus, cabine).
- **Mapa da galáxia** com 4 campanhas e 12 missões (Preparando a Nave, Missão Lua, Planeta Vermelho,
  Gigantes do Espaço). Coroa dourada em missão concluída = Desafio de Comandante.
- Jogos: exploração, pilotagem com portais, chefão (nuvem rabugenta), construção de foguete/jipe/reator,
  Restaurante de Marte, Monstro das Sílabas, montar palavra, robô programável, planetas cantores,
  trilha de luzes, histórias com escolhas, planetário, criador de criaturas, desenho livre.
- Dificuldade se ajusta sozinha por habilidade. Sem punição por errar.
- Painel dos pais: tempo, habilidades, histórico, **desafio da família** (chega como presente na nave), ajustes.

Screenshots: `docs/screenshots/v2/`. Status real do checklist: `docs/CHECKLIST_STATUS.md`.

## Para desenvolvedores
```bash
tools/setup_env.sh      # Godot 4.5.1 + templates + apksigner (Ubuntu)
tools/run_checks.sh     # lint + 69 testes + smoke v1 + smoke v2 (robô joga as 12 missões, acertando e errando)
tools/build_apk.sh      # gera e verifica os APKs (universal em dist/, arm64 em build/)
KOKORO_DIR=... python3 tools/gen_voice.py   # regenera a voz (só falas novas)
python3 tools/gen_music.py                  # regenera música/SFX/ambiência
tools/screenshots.sh    # renderiza todas as telas (Xvfb)
```
Abrir `game/` no editor Godot 4.5. Conteúdo em `game/content/*.json` (fonte: `tools/gen_content.py`).

Documentos: `PROJECT_STATUS.md`, `CHANGELOG.md`, `docs/QA_REPORT.md`, `docs/DECISIONS.md`,
`docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`, `docs/MVP_SCOPE.md`. Pacote original de especificação:
`MASTER_PROMPT.md`, `steps/`, `qa/`, `release/`, `examples/`.
