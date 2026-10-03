# STEP 23 — Pipeline de arte final (fim dos placeholders)

## Objetivo
Substituir toda a arte gerada por código por arte final consistente com a bíblia.

## Decisão que depende do Andro
- **IA**: ligar a integração Weave/Figma na conta. O agente gera e refina com prompts versionados; o
  resultado é vetorizado ou exportado em PNG em várias resoluções.
- **Ilustrador**: o agente entrega a asset list e o guia de exportação; o ilustrador entrega os arquivos.
- **Híbrido**: personagens por ilustrador, cenários por IA.

## Tarefas
1. Pipeline de importação:
   - convenção de nomes;
   - atlas por tela;
   - mipmaps/compressão ETC2/ASTC;
   - 2 resoluções (1×, 2×);
   - script que valida dimensões, transparência e nomes.
2. Personagens em partes separadas (cabeça, tronco, braços, pernas, olhos, boca) para o rig continuar
   funcionando com `Skeleton2D` ou o rig procedural atual.
3. Cenários com 3+ camadas e parallax.
4. Salas da nave como interiores de verdade: porta animada, sala visível, objetos.
5. Arte que ainda falta:
   - baú abrindo (fechado/abrindo/aberto);
   - chefões;
   - figuras do banco de fala (`v3/fala/banco_fala_seed.json`);
   - ícones de jogo no mapa.
6. Teste automático que falha se algum sprite referenciado não existe ou ainda usa o gerador antigo.

## Critérios de aceite
- 0 telas com placeholder (varredura + prancha de screenshots em `docs/screenshots/v3/`).
- Comparação cega da rubrica feita com 3 adultos (registrar resultado).
- APK arm64 ≤ 60 MB: medir e justificar.

## Anti-padrões
Misturar estilos; personagem com proporção diferente entre telas; arte com texto embutido.

## Prompt pronto
> Execute o STEP 23 com a decisão de arte do Andro. Monte o pipeline, troque toda a arte do fluxo da criança,
> gere a prancha de screenshots e rode a comparação cega. Mostre antes/depois.
