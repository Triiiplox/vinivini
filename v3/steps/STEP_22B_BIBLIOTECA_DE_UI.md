# STEP 22B — Biblioteca de componentes de UI (real, com estados e movimento)

## Objetivo
Construir no Godot **todos** os componentes da prancha 04 como cenas reutilizáveis. Nada de imagem de tela.

## Componentes (prancha 04 + tendência)
- Botões primário/secundário/terciário/ícone/bloqueado, com estados normal, pressed, focused, disabled,
  success, warning e rare.
- Cartão de missão.
- Painel de diálogo com retrato.
- Barras de progresso e de XP.
- Popup de recompensa.
- Badges hexagonais.
- Abas.
- Toggles e sliders (área dos pais).
- Slots de inventário.
- Modal.
- Bolhas de fala.
- Chips.
- Banners/toasts.
- Nós do mapa: normal, bloqueado, concluído, evento.
- Indicadores de carregamento.
- HUD superior: avatar + nível + estrelas.
- Barra de navegação inferior, só para a área dos pais (a criança navega pela nave).

## Regras técnicas
- 9-slice (`NinePatchRect`/`StyleBoxTexture`) com texturas master em 2×. Glow majoritariamente pré-renderizado.
- Movimento padrão dos tokens: toque em 180–250 ms, painel abre em 250 ms e fecha em 150 ms.
- SFX por tipo de componente e haptic pequeno.
- Ícones SVG da família da prancha 02 em `ui/icons/<categoria>/`; um ícone fora da família reprova o step.
- Cada componente tem fala associada opcional (tocar e segurar = ouvir o que é).

## Evidência obrigatória
- Cena `UiGallery` (debug) com todos os componentes e estados.
- Vídeo da galeria cobrindo entrada → idle → interação → feedback → sucesso → erro → saída.
- Comparação lado a lado com a prancha 04; se ficar mais pobre, é FAIL.

## Prompt pronto
> Execute o STEP 22B. Construa a biblioteca de UI da prancha 04 como componentes reais com 9-slice, estados,
> motion, SFX e haptics, a galeria de debug, o vídeo e a comparação lado a lado.
