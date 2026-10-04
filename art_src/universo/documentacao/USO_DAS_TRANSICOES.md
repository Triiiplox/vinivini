# Transições

Cada diretório contém uma sequência de 12 PNGs transparentes, numerados de `frame_00` a `frame_11`, e os SVGs de origem.

| Efeito | Movimento |
| --- | --- |
| dissolver | A camada azul-marinho aumenta a opacidade. |
| deslizar | Uma cortina azul, com borda ciano, cobre a tela da esquerda para a direita. |
| portas | Duas metades fecham em direção ao centro. |
| circulo | Um círculo central cresce até cobrir a tela. |
| estrela | Uma estrela cresce a partir do centro. |
| faixas | Oito faixas alternadas avançam pelas laterais. |

Use a mesma posição, escala e âncora para todos os quadros. O primeiro tem alpha zero; o último é completamente opaco em toda a imagem. Não troque a cena enquanto houver área transparente na sobreposição.

Fechamento: 00 → 11. Pausa coberta: aproximadamente 100 ms. Abertura: 11 → 00. Velocidade de referência: 24 quadros por segundo. A mesma sequência serve para entrada e saída, sem manter dois conjuntos de PNGs.

Para economizar memória, carregue apenas a transição selecionada e libere os quadros quando ela não for mais necessária. Não é preciso carregar todas as transições junto com todas as artes do catálogo.

Os efeitos da folha 3D `15_efeitos_recompensa_4x2.png` são ilustrações estáticas com fundo cinza, separadas destas sequências de transição prontas com transparência.
