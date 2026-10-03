# Architecture

## Camadas

### Game Layer
Cenas, personagens, animações, input, mapas, minigames e feedback visual.

### Learning Engine
Mantém habilidades, domínio, tentativas, dificuldade, revisão e recomendação da próxima atividade.

### Content Engine
Carrega conteúdo estruturado e valida schemas.

### Story Engine
Executa nós de narrativa, escolhas e consequências.

### Reward Engine
Conquistas, moedas não monetárias, itens cosméticos, desbloqueios e celebrações.

### Persistence Layer
Repositories desacoplados da implementação concreta.

### Parent Area
Progresso, habilidades, tempo de sessão e criação de desafios especiais.

## Eventos sugeridos
- activity_started
- answer_submitted
- answer_correct
- answer_incorrect
- challenge_completed
- skill_mastery_changed
- reward_unlocked
- story_choice_made
- session_started
- session_finished

## Autoloads sugeridos
- AppState
- EventBus
- ContentService
- LearningService
- RewardService
- SaveService
- AudioService

## Implementação (v1.0.0)
| Camada | Arquivos |
|---|---|
| Game Layer | `game/src/screens/*`, `game/src/minigames/*`, `game/src/ui/*`, `game/src/core/router.gd` |
| Learning Engine | `src/engines/learning/learning_engine.gd`, `adaptive_selector.gd`; serviço `LearningService` |
| Content Engine | `src/engines/content/content_validator.gd`, `content_repository.gd`; serviço `ContentService`; dados em `game/content/` |
| Story Engine | `src/engines/story/story_engine.gd` (validação de grafo em `ContentValidator.validate_story`) |
| Reward Engine | `src/engines/reward/reward_engine.gd`, `praise_engine.gd`; serviço `RewardService` |
| Persistence Layer | `src/persistence/*` (StorageBackend → VersionedStore → Profile/Progress/Inventory/SettingsRepository); serviço `SaveService` |
| Parent Area | `src/screens/parent_gate_screen.gd`, `parent_dashboard_screen.gd` |

Autoloads (ordem): GameLog, EventBus, SaveService, ContentService, LearningService, RewardService,
AudioService, AppState, Router. Todos os eventos sugeridos acima existem em `EventBus`
(+ `skill_level_changed`, `stars_changed`, `story_finished`, `avatar_changed`, `settings_changed`).

Fluxo de uma rodada: `ActivityRunner` → `LearningService.next_activity` (AdaptiveSelector + ContentRepository)
→ minigame emite `answered(bool)` → `LearningService.record_outcome` (LearningEngine + ProgressRepository)
→ `PraiseEngine` + `CelebrationLayer` → ao fim `RewardService.complete_mission` (estrelas, histórico, desbloqueios).
