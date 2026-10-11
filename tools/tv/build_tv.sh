#!/usr/bin/env bash
# Gera o APK da versão de TV — OUTRO app (com.vinicomandante.estrelas.tv, "Vini Comandante TV"), não substitui nem
# mistura com o do celular: os dois podem ficar instalados. Preset "Android TV" (feature "tv" liga o controle),
# armv7 + arm64 (TVs TCL costumam ter Android de 32 bits), depois tv_patch.sh (categoria de TV, banner) e check_apk.
#   completo = da família (rostos dos convidados + música): só para o Andro, nunca no repositório
#   publico  = sem fotos e sem música (a pasta vai para build/tv_stash durante o export e volta no fim)
# Uso: APKTOOL=/caminho/apktool.jar tools/tv/build_tv.sh [completo|publico]
set -euo pipefail
kind="${1:-completo}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/game"
VERSION="$(sed -n '/^\[preset.2.options\]/,/^\[/p' export_presets.cfg | grep -E '^version/name=' | cut -d'"' -f2)"
raw="$ROOT/build/ViniComandanteTV-raw.apk"
out="$ROOT/build/ViniComandanteTV-v${VERSION}-${kind}.apk"
stash="$ROOT/build/tv_stash"
mkdir -p "$ROOT/build"
restore() {
	for d in characters/kids private; do
		[ -d "$stash/$d" ] && { mkdir -p "assets/$(dirname "$d")"; mv "$stash/$d" "assets/$d"; }
	done
	rm -rf "$stash"
	godot --headless --path . --import >/dev/null 2>&1 || true
}
if [ "$kind" = publico ]; then
	[ -e "$stash" ] && { echo "build/tv_stash já existe: confira antes (pode ter fotos guardadas)"; exit 1; }
	mkdir -p "$stash/characters"
	trap restore EXIT
	[ -d assets/characters/kids ] && mv assets/characters/kids "$stash/characters/kids"
	[ -d assets/private ] && mv assets/private "$stash/private"
fi
godot --headless --path . --import >/dev/null 2>&1
rm -f "$raw"
godot --headless --path . --export-release "Android TV" "$raw" 2>&1 | grep -E "ERROR" || true
[ -f "$raw" ] || { echo "APK não gerado"; exit 1; }
"$ROOT/tools/tv/tv_patch.sh" "$raw" "$out"
rm -f "$raw" "$raw.idsig"
"$ROOT/tools/check_apk.sh" "$out" "$kind"
aapt dump badging "$out" | grep -E "^package|leanback-launchable|native-code|banner="
echo "tamanho: $(du -h "$out" | cut -f1)  sha256: $(sha256sum "$out" | cut -c1-16)…"
