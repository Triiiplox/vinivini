# Vini: Comandante das Estrelas

Jogo educativo infantil **offline**, tema espacial, para o Vini (4 anos): leitura, matemática, lógica,
histórias, emoções/respeito e astronomia. Sem anúncios, sem compras, sem internet, sem coleta de dados.

## Instalar no Android (o que importa)
1. Copie **`dist/ViniComandante-v1.0.0.apk`** para o celular/tablet (Android 7+).
2. Abra o arquivo e permita "instalar de fontes desconhecidas" quando o Android pedir.
3. Para narração em português: Configurações → Sistema → Idioma → Saída de texto em fala →
   motor do Google → instalar dados de voz **Português (Brasil)**. Sem isso, tudo aparece em texto.
4. Área dos pais: na nave, **segure o ícone de família (canto superior direito) por 2 segundos**.

Atualizações futuras devem ser assinadas com `game/android/vini-sideload.keystore` para instalar por cima
**sem perder o progresso** (ver docs/DECISIONS.md ADR-014).

## O que tem no jogo
- Criador de astronauta + Oficina (itens ganhos jogando) e Troféus.
- Nave com Mapa Estelar: **Lua** (Sílabas, Montar Palavra), **Marte** (Contar, Somar, Comparar),
  **Saturno** (Padrões, Memória), **Nebulosa da Amizade** (Sentimentos + 2 histórias ramificadas).
- Missão adaptativa (4 rodadas), Desafio de Comandante (mais difícil, sem punição), dicas após 2 erros.
- Laboratório de Planetas (criação livre), Observatório (Sistema Solar + Quiz).
- Painel dos pais: tempo, habilidades (só progresso observável), histórico, **desafio da família**, ajustes.

Screenshots: `docs/screenshots/`.

## Para desenvolvedores
```bash
tools/setup_env.sh      # Godot 4.5.1 + templates + apksigner (Ubuntu)
tools/run_checks.sh     # lint + 62 testes + smoke (projeto e pacote exportado)
tools/build_apk.sh      # gera e verifica dist/ViniComandante-v<versão>.apk
tools/screenshots.sh    # renderiza todas as telas (Xvfb)
```
Abrir `game/` no editor Godot 4.5. Conteúdo em `game/content/*.json` (fonte: `tools/gen_content.py`).

Documentos: `PROJECT_STATUS.md`, `CHANGELOG.md`, `docs/QA_REPORT.md`, `docs/DECISIONS.md`,
`docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`, `docs/MVP_SCOPE.md`. Pacote original de especificação:
`MASTER_PROMPT.md`, `steps/`, `qa/`, `release/`, `examples/`.
