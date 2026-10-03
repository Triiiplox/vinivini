# QA Checklist

Evidência automatizada: `tools/run_checks.sh` (smoke = `src/debug/smoke_runner.gd`). Ver docs/QA_REPORT.md.

- [x] Novo jogo — smoke ("novo jogo abre o criador")
- [x] Criar personagem — smoke + screenshot 02
- [x] Salvar personagem — smoke ("capacete salvo", "avatar persiste")
- [x] Abrir nave — smoke + screenshot 04
- [x] Abrir mapa — smoke + screenshot 05
- [x] Entrar em cada destino MVP — smoke (Lua, Marte, Saturno) + teste "toda tela abre"; Nebulosa via histórias/sentimentos
- [x] Completar leitura — smoke (missão na Lua + 2 jogos)
- [x] Completar matemática — smoke (missão em Marte + 3 jogos)
- [x] Completar lógica — smoke (missão em Saturno + 2 jogos)
- [x] Errar propositalmente — smoke e teste de integração (erros repetidos)
- [x] Recuperar após erro — dica após 2 erros, rodada concluída; teste "erro nunca resolve rodada"
- [x] Receber recompensa — smoke (itens desbloqueados por marco) + integração
- [x] Equipar item — smoke (Troféus) e Oficina
- [x] Completar história — smoke + teste exaustivo de caminhos
- [x] Reabrir jogo e validar save — smoke ("fechar e abrir") + testes de persistência
- [x] Jogar em modo avião — APK sem permissão INTERNET; nenhum código de rede (verificado). Teste físico: pendente no aparelho
- [x] Validar área dos pais — smoke (porta + todas as abas + desafio)
- [x] Validar áudio off/on — smoke (toggle música); efeitos/voz idem no painel
- [x] Validar textos e alvos de toque — revisão de 30 screenshots em 3 proporções
