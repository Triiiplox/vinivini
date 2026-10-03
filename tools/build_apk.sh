#!/usr/bin/env bash
# Gera o APK assinado (export sem Gradle) e verifica assinatura/manifest.
# Saída: build/ViniComandante.apk  (+ cópia versionada em dist/)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/game"
VERSION="$(grep -E '^version/name=' export_presets.cfg | head -1 | cut -d'"' -f2)"
mkdir -p "$ROOT/build" "$ROOT/dist"
godot --headless --path . --import >/dev/null 2>&1
godot --headless --path . --export-release "Android" "$ROOT/build/ViniComandante.apk" 2>&1 | grep -E "ERROR|Signed|DONE\] export" || true
APK="$ROOT/build/ViniComandante.apk"
[ -f "$APK" ] || { echo "APK não gerado"; exit 1; }
apksigner verify "$APK" 2>/dev/null && echo "assinatura: OK"
aapt dump badging "$APK" | grep -E "^package|sdkVersion|native-code"
PERMS="$(aapt dump permissions "$APK" | grep -c uses-permission || true)"
echo "permissões: $PERMS"
[ "$PERMS" -eq 0 ] || { echo "ERRO: APK não deve pedir permissões"; exit 1; }
cp "$APK" "$ROOT/dist/ViniComandante-v${VERSION}.apk"
sha256sum "$ROOT/dist/ViniComandante-v${VERSION}.apk" | tee "$ROOT/dist/ViniComandante-v${VERSION}.apk.sha256"
