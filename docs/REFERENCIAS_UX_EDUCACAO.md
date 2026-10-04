# Referências: UX e aprendizagem para 4 anos (pré-leitor)

Pesquisa feita em 04/10/2026. Os números vêm dos resumos das fontes. Algumas páginas originais não abriram por bloqueio de rede, então confira o PDF antes de citar algum número em documento formal.

## Regras aplicadas no jogo (e onde)

| # | Regra | Fonte | No jogo |
|---|---|---|---|
| 1 | Alvo de toque com no mínimo ~20 mm e área ativa maior que o desenho | NN/g "children UX physical development"; TIDRC (Soni et al. IDC 2019) | Botões da home com raio de 92 px; cartões da trilha com raio de 110; objetos de contar com raio de 88 (maior que o desenho). |
| 2 | Só tocar e arrastar com um dedo. Arrastar com um dedo deu 92% de sucesso contra 53,7% com vários dedos. | Vatavu et al. 2015 (IJHCS) | ADR-029: sem pinça, sem dois dedos, sem toque longo para a criança. |
| 3 | Instrução por voz mais demonstração com mãozinha. Só piscar ou brilhar não funciona. | Hiniker et al. 2015 (IDC) | Toda rodada tem voz. A mão demonstra o gesto na primeira rodada de cada tipo (ADR-030). A dica volta depois de 6 s parado. |
| 4 | Resposta a cada toque em até 0,1 s | NN/g "response times" | Som e animação imediatos em cada toque (press_feedback). |
| 5 | "Eu faço, nós fazemos, você faz", com dificuldade crescente | Rosenshine 2012; Callaghan & Reich 2021 | Explicação, depois demonstração, depois prática. Trilha linear. Nível adaptativo. |
| 6 | Erro em 3 níveis, mostrando o porquê | Van der Kleij 2015 (feedback elaborado com efeito ~0,49, contra ~0,05 de só certo/errado); Sesame Workshop 2012 | 1º erro: repete a pergunta ou dá a explicação (`why`). 2º erro: a mão mostra a resposta. Na cesta e na contagem, a contagem guiada mostra o resultado. |
| 7 | Vogais primeiro, em caixa alta. Traçar com o dedo. Sílaba antes de fonema. Nome e som juntos. | Pollo, Kessler & Treiman 2005; Patchan & Puranik 2016; Piasta & Wagner 2010; Castro & Barrera 2024 | Trilha de leitura: vogais, escrever vogais, consoantes, escrever letras, som das letras, montar palavras com sílabas. |
| 8 | Contar um a um, dizer o total (cardinalidade), comparar, compor até 5 e 10; trilha linear | IES/WWC 2013; Clements & Sarama; Gelman & Gallistel; Siegler & Ramani 2008 | Trilha de matemática: contar tocando (a voz conta e diz o total), juntar e tirar com a cesta, depois ordem e comparação. |
| 9 | Elogiar o processo, não a pessoa. Nada de prêmio prometido nem loja. | Cimpian et al. 2007; Gunderson 2013; Lepper 1973; Deci, Koestner & Ryan 1999; ECA Digital art. 20 | Elogios trocados de "Que esperto!" e "Que craque!" para frases sobre o que a criança fez. Sem loja e sem loot box. |
| 10 | Sessão curta que o próprio jogo encerra. Máximo de 1 h por dia (SBP e OMS). Sem autoplay, sem notificações, sem anúncios. | Hiniker 2016 (CHI); SBP "Menos telas, mais saúde"; OMS 2019; Lei 15.211/2025 (ECA Digital); LGPD art. 14 | Limite diário na área dos pais com tela de descanso. Tudo offline, sem anúncios e sem coleta de dados. |

## Ainda não aplicado
- **Tamanho do alvo em milímetros reais (`screen_get_dpi`):** hoje o tamanho é fixo em pixels do mundo 1280×720. No S23, um botão da home tem cerca de 15 mm, abaixo dos 20 mm recomendados.
- **Nada interativo perto da borda de baixo:** algumas peças de missão (a bandeja da oficina e as cores do criador de planeta) ainda ficam perto dela.
- **Subitização antes de contar:** ainda não há rodada de "quantos você vê, sem contar?".
- **Letras do nome da criança cedo na trilha:** o V, de Vini, ainda não entra antes.

## Fontes principais
- NN/g, crianças e UX: https://www.nngroup.com/articles/children-ux-physical-development/
- NN/g, tempos de resposta: https://www.nngroup.com/articles/response-times-3-important-limits/
- TIDRC (Soni et al., IDC 2019): https://init.cise.ufl.edu/wp-content/uploads/sites/378/2019/04/TIDRC-Framework-soni-et-al-IDC19-final.pdf
- Vatavu et al. 2015: https://www.sciencedirect.com/science/article/abs/pii/S1071581914001426
- Sesame Workshop 2012: https://joanganzcooneycenter.org/wp-content/uploads/2020/02/SesameWorkshop-2012.pdf
- Hiniker et al. 2015: http://faculty.washington.edu/alexisr/TouchscreenPrompts.pdf
- Hiniker et al. CHI 2016: http://faculty.washington.edu/jkientz/papers/Hiniker-Tantrums-CHI2016.pdf
- BNCC, Educação Infantil: https://basenacionalcomum.mec.gov.br/images/BNCC_EI_EF_110518_versaofinal_site.pdf
- Pollo, Kessler & Treiman 2005: https://www.sciencedirect.com/science/article/abs/pii/S0022096505000275
- Patchan & Puranik 2016: https://www.sciencedirect.com/science/article/abs/pii/S0360131516301439
- Castro & Barrera 2024: http://www.scielo.org.co/pdf/apl/v42n3/2145-4515-apl-42-03-e4238.pdf
- IES/WWC, matemática inicial: https://ies.ed.gov/ncee/wwc/Docs/PracticeGuide/early_math_pg_111313.pdf
- Siegler & Ramani 2008: https://siegler.tc.columbia.edu/wp-content/uploads/2019/02/sieg-ram08.pdf
- Van der Kleij 2015: https://research.utwente.nl/en/publications/effects-of-feedback-in-a-computer-based-learning-environment-on-s/
- Callaghan & Reich 2021: https://bera-journals.onlinelibrary.wiley.com/doi/10.1111/bjet.13055
- Rosenshine 2012: https://www.aft.org/sites/default/files/Rosenshine.pdf
- Cimpian et al. 2007: https://markmanlab.stanford.edu/publications/Cimpian-Arce-Markman-Dweck-2007.pdf
- Radesky 2022 (padrões manipulativos em apps de pré-escola): https://jamanetwork.com/journals/jamanetworkopen/fullarticle/2793493
- ECA Digital (Lei 15.211/2025): https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2025/lei/l15211.htm
- SBP, Menos telas mais saúde: https://www.sbp.com.br/fileadmin/user_upload/_22246c-ManOrient_-__MenosTelas__MaisSaude.pdf
