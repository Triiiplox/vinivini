#!/usr/bin/env bash
# Confere um APK antes da entrega: assinatura (v2/v3, exigidas no Android moderno), versão, alvo/mínimo de SDK,
# permissões, bibliotecas nativas alinhadas em 16 KB (aparelhos com Android 15+ usam páginas de 16 KB; .so em 4 KB
# não abre neles) e o que é particular (rostos dos convidados, música da família).
# Uso: tools/check_apk.sh <apk> [publico|completo]
set -euo pipefail
apk="$1"
kind="${2:-publico}"
bt=/opt/android-sdk/build-tools/35.0.0
fail=0
say() { printf '%-28s %s\n' "$1" "$2"; }

sig=$("$bt/apksigner" verify -v "$apk" 2>/dev/null | grep -E "v2 scheme|v3 scheme" | grep -c "true" || true)
say "assinatura v2+v3" "$([ "$sig" = 2 ] && echo ok || { fail=1; echo FALHOU; })"
say "versão" "$(aapt dump badging "$apk" | grep -oE "versionCode='[0-9]+' versionName='[^']+'")"
say "sdk" "$(aapt dump badging "$apk" | grep -oE "^(sdkVersion|targetSdkVersion):'[0-9]+'" | tr '\n' ' ')"
perms=$(aapt dump permissions "$apk" | grep -oE "name='[^']+'" | tr '\n' ' ')
say "permissões" "$perms"
[ "$perms" = "name='android.permission.VIBRATE' " ] || fail=1

tmp=$(mktemp -d)
unzip -q -o "$apk" 'lib/*' -d "$tmp"
bad=0
while read -r so; do
  if readelf -lW "$so" | awk '/LOAD/{print $NF}' | grep -qv '0x4000\|0x10000'; then bad=1; echo "  4 KB: $so"; fi
done < <(find "$tmp/lib" -name '*.so')
rm -rf "$tmp"
say "nativas em 16 KB" "$([ $bad = 0 ] && echo ok || { fail=1; echo FALHOU; })"

kids=0
for k in manuzita enzo aylinha; do
  for f in head ship; do
    h=$(printf "res://assets/characters/kids/%s/%s.png" "$k" "$f" | md5sum | cut -c1-32)
    kids=$((kids + $(unzip -l "$apk" | grep -c "$h" || true)))
  done
done
h=$(printf "res://assets/private/poder.ogg" | md5sum | cut -c1-32)
song=$(unzip -l "$apk" | grep -c "$h" || true)
say "fotos convidados" "$kids (rosto + nave)"
say "música particular" "$song"
if [ "$kind" = publico ] && [ $((kids + song)) -gt 0 ]; then fail=1; echo "PRIVADO NO APK PÚBLICO"; fi
if [ "$kind" = completo ] && { [ "$kids" != 6 ] || [ "$song" != 1 ]; }; then fail=1; echo "COMPLETO SEM O PARTICULAR"; fi
[ $fail = 0 ] && echo "APK OK ($kind)" || { echo "APK COM PROBLEMA"; exit 1; }
