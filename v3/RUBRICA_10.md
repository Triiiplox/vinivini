# Rubrica 10/10 (régua de release)

Cada área tem nota 0–10. **10 exige todos os critérios da coluna 10 com evidência.** A nota final é a
**menor** nota entre as áreas críticas (marcadas ★) — um jogo lindo que trava não é 10.
O agente mantém `docs/RUBRICA_PROGRESSO.md` com: área, nota atual, evidência, data.

| Área | v2 (hoje) | Critérios para 10 (todos) | Evidência obrigatória |
|---|---|---|---|
| ★ Autonomia sem leitura | 8 | Vini completa ≥ 80% das missões **sem adulto tocar na tela**; nenhuma instrução precisa ser repetida mais de 2× em média; 0 telas com texto necessário no fluxo da criança | Registro de playtest (STEP 21 protocolo) em 3 dias diferentes; varredura automática de Labels no fluxo da criança |
| ★ Diversão (Fun Gate) | ? | Vini pede para jogar em ≥ 4 de 7 dias sem ser lembrado; sessão espontânea média ≥ 10 min; ≥ 3 jogos que ele escolhe repetir sozinho | Diário de 7 dias (planilha simples) + contadores locais de sessão |
| ★ Estabilidade | 8 | 0 crash e 0 trava em 2 h de playtest real; smoke v2 (acertando e errando) verde; nenhum erro de log | Logs do aparelho, `run_checks.sh` TUDO OK |
| Arte | 5–6 | Estilo único documentado (bíblia de arte); 100% das telas com arte final (cenário com 3+ camadas de profundidade, personagens com proporção consistente); comparação cega: 3 adultos colocam prints lado a lado com Sago Mini/Khan Kids e não apontam o Vini como "o amador" | Bíblia de arte, prancha de todas as telas, resultado da comparação cega |
| Animação / juice | 6 | Todo toque tem resposta < 100 ms; personagens com antecipação e assentamento; transições com intenção; 0 objeto interativo parado sem idle | Vídeo de 60 s por jogo; checklist de microinterações |
| Jogabilidade | 6 | 3 jogos-âncora com ≥ 3 mecânicas que se combinam e curva de 10+ níveis; cada um passa no teste "Vini repete por vontade própria"; os demais sem nenhum ponto morto > 5 s | Playtest + gravações de tela |
| Conteúdo | 4–5 | ≥ 40 missões, ≥ 6 chefões diferentes (sem violência), ≥ 6 h até "terminar", variação procedural para rejogar | `content/` + contagem automática no teste |
| Pedagogia | 7 | Cada habilidade com progressão 3+ níveis validada; pré/pós simples (sondagem de 10 itens no início e após 4 semanas) mostrando avanço | Relatório de sondagem na área dos pais |
| Fala (Planeta Eco) | 0 | Seguir `fala/REFERENCIAS_FALA.md`; banco de palavras validado por fono **ou** marcado "não validado"; sessão de 5–8 min com 30–60 produções; adulto julga, nunca o ASR; registro de evolução por som | Banco revisado, vídeo de sessão, relatório por som |
| Áudio / voz | 7 | Escuta completa de todas as falas por humano com 0 pronúncia estranha não corrigida; mixagem medida no aparelho (voz sempre inteligível sobre música) | Planilha de escuta (fala, ok/ajustar), gravação do aparelho |
| ★ Desempenho | ? | 60 FPS médio, nenhum quadro > 50 ms em transições, abertura < 3 s, no aparelho do Vini | Captura do monitor de desempenho no aparelho |
| Área dos pais | 7 | PIN próprio; relatório por área e por som de fala; exportar resumo para levar à fono (arquivo local); ajustes de vibração/som/tempo | Screenshots + teste |
| Segurança / privacidade | 9 | Sem rede; gravações de voz só locais, apagadas por padrão, consentimento explícito | `aapt dump permissions`, teste de apagamento |

**Regra de ouro:** se uma evidência depende do Vini ou do aparelho e ainda não existe, a área fica com
nota "pendente" — nunca com nota estimada.
