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
step "smoke (pacote exportado)"; mkdir -p ../build/linux
godot --headless --path . --export-pack "Linux" ../build/linux/vini.pck >"$LOG/pack.txt" 2>&1 || fail=1
(cd /tmp && godot --headless --main-pack "$OLDPWD/../build/linux/vini.pck" -- --smoke) >"$LOG/smoke_pck.txt" 2>&1 || fail=1
grep -E "SMOKE|FALHOU" "$LOG/smoke_pck.txt"; bad "$LOG/smoke_pck.txt"
echo "logs em $LOG"
[ $fail -eq 0 ] && echo "TUDO OK" || { echo "FALHOU"; exit 1; }
