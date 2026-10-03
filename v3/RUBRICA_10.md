# Rubrica 10/10 (régua de release)

Cada área tem nota 0–10. **10 exige todos os critérios da coluna 10 com evidência.** A nota final é a
**menor** nota entre as áreas críticas (marcadas ★) — um jogo lindo que trava não é 10.
O agente mantém `docs/RUBRICA_PROGRESSO.md` com: área, nota atual, evidência, data.

| Área | v2 (hoje) | Critérios para 10 (todos) | Evidência obrigatória |
|---|---|---|---|
| ★ Autonomia sem leitura | 8 | Vini completa ≥ 80% das missões **sem adulto tocar na tela**; nenhuma instrução precisa ser repetida mais de 2× em média; 0 telas com texto necessário no fluxo da criança | Registro de playtest (STEP 21 protocolo) em 3 dias diferentes; varredura automática de Labels no fluxo da criança |
| ★ Diversão (Fun Gate) | ? | Vini pede para jogar em ≥ 4 de 7 dias sem ser lembrado; sessão espontânea média ≥ 10 min; ≥ 3 jogos que ele escolhe repetir sozinho | Diário de 7 dias (planilha simples) + contadores locais de sessão |
| ★ Estabilidade | 8 | 0 crash e 0 trava em 2 h de playtest real; smoke v2 (acertando e errando) verde; nenhum erro de log | Logs do aparelho, `run_checks.sh` TUDO OK |
| Arte | 5–6 | Implementação **igual ou acima das pranchas do design system** em 100% das telas (lado a lado, aprovado pelo Andro); cenários em 3+ camadas com parallax; personagens idênticos ao character sheet em todas as telas; 1 família de ícones; 0 placeholder; comparação cega com 3 adultos (Sago Mini/Khan Kids) sem "o amador" | Art Bible, pranchas lado a lado (pranchas × jogo), varreduras de placeholder e ícone, resultado da comparação cega |
| Animação / juice | 6 | Toque responde em < 100 ms; motion dos tokens em toda a UI; rig com rosto separado e lip-sync; biblioteca MVP de animações; câmera dinâmica; transições com warp; recompensa proporcional; 0 objeto interativo sem idle | Vídeo de cada tela na sequência entrada → idle → interação → feedback → sucesso → erro → saída |
| Jogabilidade | 6 | 3 jogos-âncora com ≥ 3 mecânicas que se combinam e curva de 10+ níveis; cada um passa no teste "Vini repete por vontade própria"; os demais sem nenhum ponto morto > 5 s | Playtest + gravações de tela |
| Conteúdo | 4–5 | ≥ 40 missões, ≥ 6 chefões diferentes (sem violência), ≥ 6 h até "terminar", variação procedural para rejogar | `content/` + contagem automática no teste |
| Pedagogia | 7 | Cada habilidade com progressão 3+ níveis validada; pré/pós simples (sondagem de 10 itens no início e após 4 semanas) mostrando avanço | Relatório de sondagem na área dos pais |
| Fala (Planeta Eco) | 0 | Seguir `fala/REFERENCIAS_FALA.md`; banco de palavras validado por fono **ou** marcado "não validado"; sessão de 5–8 min com 30–60 produções; adulto julga, nunca o ASR; registro de evolução por som | Banco revisado, vídeo de sessão, relatório por som |
| Inglês (Planeta Hello) | 0 | 30 unidades / 150 lições jogáveis sem ler; 0 vídeo passivo; repetição espaçada funcionando; após 8 semanas o Vini reconhece ≥ 80 palavras na sondagem por figura; usa ≥ 5 frases-chave espontaneamente (relato do adulto) | Sondagem inicial × 8 semanas, relatório do SRS, diário do adulto |
| Áudio / voz | 7 | Escuta completa de todas as falas por humano com 0 pronúncia estranha não corrigida; mixagem medida no aparelho (voz sempre inteligível sobre música) | Planilha de escuta (fala, ok/ajustar), gravação do aparelho |
| ★ Desempenho | ? | 60 FPS médio, nenhum quadro > 50 ms em transições, abertura < 3 s, no aparelho do Vini | Captura do monitor de desempenho no aparelho |
| Área dos pais | 7 | PIN próprio; relatório por área e por som de fala; exportar resumo para levar à fono (arquivo local); ajustes de vibração/som/tempo | Screenshots + teste |
| Segurança / privacidade | 9 | Sem rede; gravações de voz só locais, apagadas por padrão, consentimento explícito | `aapt dump permissions`, teste de apagamento |

**Regra de ouro:** se uma evidência depende do Vini ou do aparelho e ainda não existe, a área fica com
nota "pendente" — nunca com nota estimada.
