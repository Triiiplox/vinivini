# Planeta Hello — base de pesquisa para inglês com criança que não lê

| Achado | Implicação no design | Fonte |
|---|---|---|
| Crianças de 0–6 anos aprendem menos com vídeo do que ao vivo ("video deficit", ~½ desvio-padrão). Quando a tela **responde à criança** (contingência), a perda praticamente some. Com 2–4 anos, um adulto junto (co-uso) também ajuda | Nada de "assistir vídeo em inglês". Tudo é interação: a criança age, o Hoppy reage na hora. Modo "jogar junto" para o adulto, opcional | Meta-análise *Child Development* (2023); "Skype Me!" (Roseberry et al.); Frontiers 2024 |
| **TPR** (Total Physical Response, Asher): ouvir um comando e fazer com o corpo melhora a retenção de vocabulário em crianças pequenas | Cada unidade tem comandos para o corpo ("Jump!", "Touch your nose!") e para o avatar, que imita | Estudos com pré-escolares e crianças em EFL (ResearchGate, ERIC) |
| Em pré-escolares, **histórias** foram o meio mais eficaz para vocabulário; história + canção também funcionou; canção sozinha foi o menos eficaz | Canções são ponte e diversão. O vocabulário principal vem de história interativa e jogo | *System* (2018), estudo com pré-escolares em EFL |
| **Prática de recuperação espaçada** (lembrar a palavra em dias diferentes) dobra a retenção após 1 semana em crianças de 4–5 anos. O número de recuperações prediz a retenção | Motor de repetição espaçada por palavra; cada lição começa revisando palavras antigas pedindo para **achar**, não só mostrando | JSLHR 2024 (Leonard et al.); PMC 2024 (fostering retention) |
| Lista oficial **Cambridge Pre A1 Starters** (~500 palavras em temas como animais, corpo, roupas, cores, família, comida, números, casa, brinquedos, transporte, tempo) | Currículo segue esses temas, em ordem de relevância para 4 anos, mais um tema "Espaço" próprio. Meta de longo prazo: cobrir a lista | Cambridge English (wordlist 2018/2025) |
| Diretrizes do CNE para educação plurilíngue (2020): escola bilíngue na educação infantil com 30–50% da carga em língua adicional | Referência de que exposição precoce é política aceita no Brasil. O app é complemento lúdico, não "escola bilíngue" | Parecer CNE/CEB 2/2020 |

## Decisões
1. **Fala primeiro, leitura nunca obrigatória.** Nenhuma palavra em inglês escrita é necessária para
   jogar. Texto em inglês aparece no máximo como legenda decorativa desligável, sem phonics nesta fase.
2. **Uma voz de referência do inglês**: vozes nativas en-US do Kokoro, em velocidade normal e lenta,
   no mesmo pipeline do `gen_voice.py`. Personagem **Hoppy** só fala inglês. O **Astro** dá o apoio em
   português e vai sumindo: traduz na 1ª exposição, depois só dá dica se a criança errar 2 vezes, e a
   partir da unidade 6 só explica a mecânica do jogo, nunca o significado.
3. **Sem culpa**: nada de "ofensiva" que se perde, vidas ou corações. A constância vira uma planta na nave
   que cresce a cada dia jogado e nunca morre.
4. **Ponte com o mundo real**: cada unidade sugere ao adulto 3 frases para usar em casa. A área dos pais
   mostra a lista e a pronúncia (botão ouvir).
5. **Licença de músicas**: só canções originais ou tradicionais em domínio público. Nada de músicas de
   canais infantis.
6. **Fala em inglês** (produção): mesmo esquema do Planeta Eco. Gravar, devolver a voz, o adulto julga se
   quiser. Sem ASR julgando a criança.

## Referências
- Screen media exposure and young children's vocabulary learning and development: a meta-analysis. *Child Development*, 2023. [Wiley](https://onlinelibrary.wiley.com/doi/10.1111/cdev.13927)
- Roseberry, Hirsh-Pasek & Golinkoff. Skype me! Socially contingent interactions help toddlers learn language. [ResearchGate](https://www.researchgate.net/publication/257646159_Skype_Me_Socially_Contingent_Interactions_Help_Toddlers_Learn_Language)
- Toddler word learning from contingent screens with and without human presence. [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S016363832100028X)
- Learning from screen media (Encyclopedia on Early Childhood Development). [link](https://www.child-encyclopedia.com/technology-early-childhood-education/according-experts/infants-toddlers-and-learning-screen-media)
- Frontiers in Developmental Psychology, 2024 (mídia e aprendizagem de linguagem). [link](https://www.frontiersin.org/journals/developmental-psychology/articles/10.3389/fdpys.2024.1439040/full)
- Impacts of Total Physical Response on young learners' vocabulary ability. [ResearchGate](https://www.researchgate.net/publication/356119690_Impacts_of_Total_Physical_Response_on_Young_Learners'_Vocabulary_Ability)
- Using TPR in early childhood foreign language teaching environments. [ResearchGate](https://www.researchgate.net/publication/273852128_Using_Total_Physical_Response_Method_in_Early_Childhood_Foreign_Language_Teaching_Environments)
- Teaching kindergarten children English vocabulary by TPR. [PDF](https://jpesm.thebrpi.org/journals/jpesm/Vol_6_No_2_December_2019/8.pdf)
- Songs, stories, and vocabulary acquisition in preschool learners of English as a foreign language. *System*. [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0346251X17302245)
- Retrieval practice and word learning by children with DLD: does expanding retrieval provide additional benefit? *JSLHR*, 2024. [ASHA](https://pubs.asha.org/doi/10.1044/2024_JSLHR-23-00528)
- Fostering retention of word learning: number of retrieval sessions relates to retention. [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC11056717/)
- The effect of retrieval practice in primary school vocabulary learning. [ResearchGate](https://www.researchgate.net/publication/259679706_The_Effect_of_Retrieval_Practice_in_Primary_School_Vocabulary_Learning)
- Cambridge Pre A1 Starters, A1 Movers e A2 Flyers wordlists (2025). [PDF](https://www.cambridgeenglish.org/Images/506166-starters-movers-flyers-word-list-2025.pdf) · Picture book: [PDF](https://www.cambridgeenglish.org/images/starters-word-list-picture-book.pdf)
- Diretrizes Curriculares Nacionais para Educação Plurilíngue (CNE 2020). [FCC](https://educa.fcc.org.br/scielo.php?script=sci_arttext&pid=S1982-03052022000400380)
