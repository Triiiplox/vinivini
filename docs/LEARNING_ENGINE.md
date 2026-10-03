# Learning Engine

Cada habilidade possui domínio próprio.

Campos mínimos:
- skill_id
- level
- mastery [0..1]
- attempts
- correct
- incorrect
- streak
- average_response_time
- last_seen
- next_review

## Regras iniciais
- acerto rápido: + domínio maior
- acerto com tentativa: + domínio menor
- erro isolado: pequena redução ou estabilidade
- erros repetidos: baixar dificuldade e mudar representação
- domínio alto: introduzir nível seguinte
- revisões programadas para consolidar aprendizado

## Importante
Não rotular inteligência, capacidade ou diagnóstico. Exibir para os pais apenas progresso observável.
