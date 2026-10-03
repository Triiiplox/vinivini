# Convenções do projeto (Step 00)

## Estrutura
```
game/                     projeto Godot 4.5 (abrir esta pasta no editor)
  project.godot, export_presets.cfg, gdlintrc
  content/                conteúdo data-driven (JSON) — único lugar de textos de atividades/histórias
  assets/                 fontes (OFL), áudio sintetizado, ícone
  scenes/main.tscn        única cena; telas são scripts
  src/core/               main, router, event_bus, game_log
  src/engines/            learning/, content/, story/, reward/  (lógica pura, sem nós, 100% testável)
  src/persistence/        storage backends, versionamento, repositories
  src/services/           autoloads: SaveService, ContentService, LearningService, RewardService, AudioService, AppState
  src/ui/                 design system: tema, KidButton, ícones, planeta, avatar, personagens, celebração
  src/screens/            telas (BaseScreen)
  src/minigames/          minigames (MinigameBase)
  src/debug/              smoke e screenshots (só rodam com flag de linha de comando)
  tests/unit, tests/integration
tools/                    setup do ambiente, checagens, build, geradores de conteúdo/áudio/ícone
```

## GDScript
- `gdlint src tests` deve passar (config em `game/gdlintrc`, linha máx. 140).
- Tipagem estática sempre que o tipo é conhecido; nunca `:=` com valor Variant.
- `class_name` só para tipos reutilizáveis; autoloads sem class_name.
- Lógica de regra fica em `src/engines` (RefCounted, static funcs) — telas só orquestram.
- Nada de `await` em timers dentro de telas: use `BaseScreen.after()` (tween morre com o nó).
- Para recriar filhos use `UI.clear(node)` (evita renomeação automática de nós homônimos).
- Nomes de nós sem ponto (`.`), pois o Godot os substitui.
- Logs via `GameLog` (info/warn/error); `ERROR:`/`SCRIPT ERROR` na saída = bug.

## Conteúdo
- Toda atividade passa por `ContentValidator`; conteúdo inválido é rejeitado com mensagem clara e
  aparece no painel dos pais (contador) e nos testes.
- Fonte editorial: `tools/gen_content.py` (determinístico). Pode-se editar o JSON direto também.

## Testes (rodar antes de qualquer commit)
`tools/run_checks.sh` — lint + unit + integração (inclui jogar as 399 atividades) + smoke no projeto e no pacote exportado.
