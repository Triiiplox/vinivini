# CHANGELOG

## v1.0.0 — 2026-10-03 — MVP
### Adicionado
- Projeto Godot 4.5.1 (GL Compatibility), Android landscape, minSdk 24, arm64 + armv7, 0 permissões.
- Arquitetura em camadas: EventBus, Router com histórico, GameLog; engines puros (Learning, Adaptive,
  Content/Validator, Story, Reward, Praise); persistência por repositories com envelope versionado,
  escrita atômica e backup; autoloads de serviço.
- Conteúdo data-driven (399 atividades em 9 habilidades × até 3 níveis; 2 histórias com 5 finais; 10 fatos;
  24 itens; elogios por contexto) gerado por `tools/gen_content.py` e validado no boot e nos testes.
- 9 minigames: Sílabas, Montar Palavra, Contar, Somar, Comparar, Padrões, Memória, Quiz do Espaço, Sentimentos.
- Telas: início, criador/oficina, intro do Cosmo, nave, mapa, planeta, atividade, resultado, biblioteca,
  história, laboratório de planetas, observatório, troféus, porta dos pais, painel dos pais.
- Adaptação: nível por habilidade sobe/desce; modo apoio com representação alternativa e dicas;
  revisão espaçada; Desafio de Comandante (+1 nível, sem punição); Cosmo sugere destino.
- Recompensas: estrelas não monetárias, itens por marco, celebração calibrada, elogios variados
  (simples, sequência, persistência, estratégia, desafio).
- Painel dos pais: resumo, habilidades observáveis, histórico, desafio da família, ajustes
  (música/efeitos/voz, nome, lembrete de pausa, apagar progresso).
- Áudio sintetizado (SFX + música em loop) e narração TTS pt-BR offline com fallback em texto.
- Arte 100% procedural; fontes Andika/Comfortaa (OFL); ícone adaptativo.
- Ferramentas: `setup_env.sh`, `run_checks.sh`, `build_apk.sh`, `screenshots.sh`, geradores.
- Testes: 62 (unit + integração), smoke end-to-end (projeto e pacote exportado), soak de 40 missões.
### Corrigido durante o QA
- Ver docs/QA_REPORT.md (2 critical, 4 high, 6 medium, 2 low).
