#!/usr/bin/env bash
# Renderiza todas as telas (OpenGL via Xvfb) para revisão visual.
set -euo pipefail
OUT="${1:-$(cd "$(dirname "$0")/.." && pwd)/docs/screenshots}"
cd "$(dirname "$0")/../game"
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 -- --shots="$OUT" 2>&1 | grep -E "^shot" || true
echo "screenshots em $OUT"
