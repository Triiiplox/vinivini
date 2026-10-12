#!/usr/bin/env bash
# Checagens completas: lint, testes (unit+integração), smoke end-to-end e smoke no pacote exportado.
# Falha se qualquer etapa falhar ou se aparecer SCRIPT ERROR / Parse Error.
set -uo pipefail
cd "$(dirname "$0")/../game"
LOG="$(mktemp -d)"
fail=0
step() { echo "== $1"; }
bad() { grep -E "SCRIPT ERROR|Parse Error" "$1" && fail=1 || true; }

step "import"; godot --headless --path . --import >"$LOG/import.txt" 2>&1
step "lint"; gdlint src tests || fail=1
step "testes"; godot --headless --path . res://tests/test_runner.tscn >"$LOG/tests.txt" 2>&1 || fail=1
grep -E "FAIL|RESULTADO|^\s+- " "$LOG/tests.txt"; bad "$LOG/tests.txt"
step "smoke (projeto)"; godot --headless --path . -- --smoke >"$LOG/smoke.txt" 2>&1 || fail=1
grep -E "SMOKE|FALHOU" "$LOG/smoke.txt"; bad "$LOG/smoke.txt"
step "smoke v2 (12 missões jogadas pelo robô)"; godot --headless --path . -- --smoke2 >"$LOG/smoke2.txt" 2>&1 || fail=1
grep -E "SMOKE2|FALHOU|sem voz|níveis" "$LOG/smoke2.txt"; bad "$LOG/smoke2.txt"
step "smoke v2 com erros de propósito"; godot --headless --path . -- --smoke2 --mistakes >"$LOG/smoke2m.txt" 2>&1 || fail=1
grep -E "SMOKE2|FALHOU" "$LOG/smoke2m.txt"; bad "$LOG/smoke2m.txt"
step "toques reais em tela larga de celular (xvfb, 2340x1080)"
xvfb-run -a -s "-screen 0 2340x1080x24" godot --path . --rendering-driver opengl3 --resolution 2340x1080 -- --touchcheck="$LOG/touch" >"$LOG/touch.txt" 2>&1 || fail=1
grep -E "TOUCH" "$LOG/touch.txt" || { echo "TOUCH sem resultado"; fail=1; }; bad "$LOG/touch.txt"
step "lições mão na massa com toques reais (traçar, contar, juntar, tirar, montar palavra)"
xvfb-run -a -s "-screen 0 2340x1080x24" godot --path . --rendering-driver opengl3 --resolution 2340x1080 -- --lessoncheck="$LOG/lessons" >"$LOG/lessons.txt" 2>&1 || fail=1
grep -E "LESSON" "$LOG/lessons.txt" || { echo "LESSON sem resultado"; fail=1; }; bad "$LOG/lessons.txt"
step "versão de TV: só controle de PS5 (setas, analógico, botões, OPTIONS segurado) em 1920x1080"
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 -- --tv --padcheck="$LOG/pad" >"$LOG/pad.txt" 2>&1 || fail=1
grep -E "^PAD" "$LOG/pad.txt" || { echo "PAD sem resultado"; fail=1; }; bad "$LOG/pad.txt"
step "botões cortando o outro: todas as telas em celular largo (2340x1080), 1280x720 e TV (1920x1080)"
overlap() {  # $1 = resolução, $2 = nome, $3 = argumento extra (--tv)
	xvfb-run -a -s "-screen 0 $1x24" godot --path . --rendering-driver opengl3 --resolution "$1" -- $3 \
		--overlapcheck="$LOG/overlap_$2" >"$LOG/overlap_$2.txt" 2>&1 || fail=1
	grep -E "^OVERLAP (PASS|FAIL)|ERRO" "$LOG/overlap_$2.txt" || { echo "OVERLAP $2 sem resultado"; fail=1; }
	bad "$LOG/overlap_$2.txt"
}
overlap 2340x1080 celular ""; overlap 1280x720 1280 ""; overlap 1920x1080 tv --tv
step "smoke (pacote exportado)"; mkdir -p ../build/linux
godot --headless --path . --export-pack "Linux" ../build/linux/vini.pck >"$LOG/pack.txt" 2>&1 || fail=1
(cd /tmp && godot --headless --main-pack "$OLDPWD/../build/linux/vini.pck" -- --smoke) >"$LOG/smoke_pck.txt" 2>&1 || fail=1
grep -E "SMOKE|FALHOU" "$LOG/smoke_pck.txt"; bad "$LOG/smoke_pck.txt"
(cd /tmp && godot --headless --main-pack "$OLDPWD/../build/linux/vini.pck" -- --smoke2) >"$LOG/smoke2_pck.txt" 2>&1 || fail=1
grep -E "SMOKE2|FALHOU|sem voz" "$LOG/smoke2_pck.txt"; bad "$LOG/smoke2_pck.txt"
echo "logs em $LOG"
[ $fail -eq 0 ] && echo "TUDO OK" || { echo "FALHOU"; exit 1; }
