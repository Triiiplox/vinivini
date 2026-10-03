#!/usr/bin/env bash
# Gera os APKs assinados (export sem Gradle) e verifica assinatura/manifest/permissões.
# Saída: build/ViniComandante.apk (universal: arm64 + armv7) e build/ViniComandante-v<ver>-arm64.apk
# (menor, para enviar por chat). Cópia versionada do universal em dist/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/game"
VERSION="$(grep -E '^version/name=' export_presets.cfg | head -1 | cut -d'"' -f2)"
mkdir -p "$ROOT/build" "$ROOT/dist"
godot --headless --path . --import >/dev/null 2>&1

export_apk() {
	godot --headless --path . --export-release "Android" "$1" 2>&1 | grep -E "ERROR|Signed|DONE\] export" || true
	[ -f "$1" ] || { echo "APK não gerado: $1"; exit 1; }
	apksigner verify "$1" 2>/dev/null && echo "assinatura: OK ($(basename "$1"))"
	aapt dump badging "$1" | grep -E "^package|sdkVersion|native-code"
	# Única permissão aceita: VIBRATE (vibração leve de feedback; desligável na área dos pais).
	local perms
	perms="$(aapt dump permissions "$1" | grep uses-permission | grep -v -c "android.permission.VIBRATE" || true)"
	[ "$perms" -eq 0 ] || { echo "ERRO: permissão inesperada"; aapt dump permissions "$1"; exit 1; }
	echo "tamanho: $(du -h "$1" | cut -f1)"
}

export_apk "$ROOT/build/ViniComandante.apk"
cp export_presets.cfg /tmp/export_presets.bak
trap 'cp /tmp/export_presets.bak "$ROOT/game/export_presets.cfg"' EXIT
sed -i '0,/architectures\/armeabi-v7a=true/s//architectures\/armeabi-v7a=false/' export_presets.cfg
export_apk "$ROOT/build/ViniComandante-v${VERSION}-arm64.apk"
cp /tmp/export_presets.bak export_presets.cfg
rm -f "$ROOT"/dist/ViniComandante-v*.apk "$ROOT"/dist/ViniComandante-v*.apk.sha256
cp "$ROOT/build/ViniComandante.apk" "$ROOT/dist/ViniComandante-v${VERSION}.apk"
(cd "$ROOT/dist" && sha256sum "ViniComandante-v${VERSION}.apk" | tee "ViniComandante-v${VERSION}.apk.sha256")
(cd "$ROOT/build" && sha256sum "ViniComandante-v${VERSION}-arm64.apk")
