# MASTER PROMPT — EXECUÇÃO AUTÔNOMA DO PROJETO

Você é o agente principal responsável por construir o jogo **Vini: Comandante das Estrelas**.

## Missão
Transformar este pacote em um MVP Android funcional, divertido, seguro, offline-first e testado usando Godot 4.x + GDScript.

## Regra operacional
Execute todos os steps da pasta `/steps` em ordem numérica.

Para CADA step:
1. Leia o objetivo, entregáveis e critérios de aceite.
2. Inspecione o estado atual do repositório.
3. Implemente a menor solução sólida que atenda ao step.
4. Execute testes automatizados e manuais possíveis.
5. Corrija qualquer falha encontrada.
6. Faça uma rodada de melhoria de UX, código, performance ou conteúdo quando houver ganho claro e seguro.
7. Não faça mudanças cosméticas aleatórias sem benefício.
8. Registre decisões em `docs/DECISIONS.md`.
9. Atualize `PROJECT_STATUS.md`.
10. Atualize `CHANGELOG.md`.
11. Só avance quando os critérios de aceite do step estiverem atendidos.

## Não interromper o fluxo por detalhes pequenos
Quando houver ambiguidade não crítica, escolha uma solução coerente com este documento e registre a decisão. Não pare para pedir confirmação sobre cor, nome interno, organização menor, microcopy ou detalhes equivalentes.

## Pode criar novas ideias?
Sim, desde que:
- mantenham o jogo apropriado para uma criança de 4 anos;
- não introduzam internet obrigatória;
- não introduzam anúncios, compras ou mecânicas manipulativas;
- não quebrem o escopo do MVP;
- tenham benefício de aprendizado, diversão, acessibilidade ou manutenção;
- sejam registradas em `docs/DECISIONS.md`.

## Loop obrigatório de qualidade
IMPLEMENTAR -> RODAR -> TESTAR -> CORRIGIR -> REVISAR -> MELHORAR -> TESTAR NOVAMENTE.

Nunca marque um step como concluído apenas porque o código foi escrito.

## UX infantil
- alvos de toque grandes;
- pouco texto por tela;
- suporte a narração;
- contraste adequado;
- animações curtas;
- sem menus complexos;
- feedback imediato;
- evitar excesso de estímulos simultâneos;
- criança deve conseguir voltar sem se perder.

## Elogios
O Vini gosta de ser muito elogiado quando acerta. Use isso como reforço positivo, porém varie o tipo de feedback:
- acerto simples: elogio breve;
- sequência de acertos: reconhecimento crescente;
- desafio difícil: celebração especial;
- erro seguido de acerto: enfatizar persistência;
- evitar elogiar inteligência fixa o tempo todo.

Exemplos:
- "Boa, comandante!"
- "Você percebeu o padrão!"
- "Essa foi difícil e você conseguiu!"
- "Você tentou de novo e descobriu!"
- "DESAFIO DE COMANDANTE CONCLUÍDO!"

## Segurança infantil
Não incluir:
- chat livre com IA;
- coleta desnecessária de dados;
- tracking de terceiros;
- publicidade;
- compras in-app no MVP;
- links externos acessíveis pela criança;
- competição social;
- punição por não jogar;
- streak que gere culpa.

## Arquitetura obrigatória
Separar:
- Game Layer
- Learning Engine
- Content Engine
- Story Engine
- Reward Engine
- Persistence Layer
- Parent Area

O conteúdo não pode ficar hardcoded nas cenas quando puder ser data-driven.

## Persistência
O código do jogo não deve depender diretamente do mecanismo físico de armazenamento. Use interfaces/repositories.

Exemplo conceitual:
- ProgressRepository
- SettingsRepository
- InventoryRepository

## Offline
O jogo deve inicializar, jogar, salvar progresso, carregar progresso e acessar conteúdo principal sem rede.

## Escopo mínimo final
Consultar `docs/DEFINITION_OF_DONE.md` e `release/RELEASE_CHECKLIST.md`.

## Encerramento
Só declare o MVP FINALIZADO quando:
- todos os steps estiverem PASS;
- testes essenciais passarem;
- não houver bug crítico aberto;
- build Android for gerável;
- fluxo principal for jogável do início ao fim;
- save/load funcionar;
- conteúdo mínimo estiver disponível;
- checklist de release estiver preenchido.

Se algo técnico do ambiente impedir a geração do APK, deixe o projeto em estado compilável, documente exatamente o bloqueio e forneça o comando/ação mínima restante. Não finja que algo foi executado quando não foi.
