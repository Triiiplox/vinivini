# Pranchas × regras do produto — o que se adapta (decisões e pendências)

As pranchas mandam no **visual**. As regras de produto (criança de 4 anos que não lê, offline, sem punição,
sem loja) mandam no **comportamento**. Quando colidem, mantém-se o visual e adapta-se a função:

| Elemento nas pranchas | Problema | Adaptação |
|---|---|---|
| Rótulos de texto em botões, abas, cards e banners ("JOGAR", "Missões", "Mapa Galáctico", descrições) | O Vini não lê | O componente mantém o visual; a função vem de ícone + voz (tocar = ouvir). Texto vira decorativo/opcional no fluxo da criança. A área dos pais usa texto normal |
| Corações de vida no gameplay; "terminou sem perder vidas" | Errar não pune | Sem vidas. O espaço vira contador de estrelas ou energia que só sobe |
| Chip "Tempo Limitado", contagem regressiva de missão | Pressão de tempo | Eventos especiais sem prazo punitivo (aparecem e ficam) |
| Moedas/gemas como moeda, aba **Loja**, botão "+" de compra, "cristal raro" | Sem compra e sem loja | Gemas e estrelas desbloqueiam itens por progresso. Sem loja, sem "+" de comprar |
| Modal "consumirá 1 combustível" / "Pouco combustível" | Bloquear o jogo por recurso é dark pattern | Combustível só como elemento de história (abastecer na missão), nunca trava |
| Amigos/convidar/chat seguro/compartilhar/nuvem/sincronizar (ícones) | Offline, sem rede social, segurança infantil | Fora do produto. "Meus amigos" = Astro, Luna, Apolo e NPCs |
| Prancha retrato (celular em pé) | Jogo é landscape 16:9 | Recompor cada tela nos 3 layouts-base |
| Tamanho mínimo de toque 44×44 | Criança de 4 anos | Mínimo de 96 px lógicos |
| Tipografia Orbitron/Nunito para tudo | Conteúdo de alfabetização precisa de letra clara | Andika para letras e sílabas que a criança aprende |
| Tema "Planeta Terra / Cidades Sustentáveis / Reciclagem" | Novo eixo de conteúdo | **Adotar**: nova campanha "Cuidar da Terra" (reciclar, água, energia), coerente com a marca "Explorar · Aprender · Cuidar" |
| Personagens Astro (robô), Luna (dragoa), Apolo (corgi) | O jogo atual tem Cosmo e um dragão sem nome | **Adotar o elenco da marca**: Cosmo vira **Astro** (regerar falas), o dragão vira **Luna**, Apolo é novo mascote. Hoppy e Eco seguem a mesma linha visual |
| "Nível 12", XP, barra de XP | Números não são lidos | Pode ficar como visual (barra enchendo, estrela de nível). Nunca exigir leitura do número |

## Decisões que dependem do Andro
1. ~~Spine~~ **Decidido:** rig 100% Godot 4 (Skeleton2D/Bone2D/Polygon2D/AnimationTree), custo R$ 0 —
   `RIG_GODOT.md`.
2. **Renomear o Cosmo para Astro** em todo o jogo e nas vozes (recomendado, porque o design system é
   obrigatório).
3. **Geração de imagem**: ligar a Weave/Figma (pendente) ou o Andro gera e envia os concepts.
