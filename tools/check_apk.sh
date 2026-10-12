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
# (o fail=1 fica fora do $( ): dentro de um subshell ele não voltava, e o APK passava mesmo com FALHOU)
[ "$sig" = 2 ] && say "assinatura v2+v3" ok || { fail=1; say "assinatura v2+v3" FALHOU; }
say "versão" "$(aapt dump badging "$apk" | grep -oE "versionCode='[0-9]+' versionName='[^']+'")"
say "sdk" "$(aapt dump badging "$apk" | grep -oE "^(sdkVersion|targetSdkVersion):'[0-9]+'" | tr '\n' ' ')"
perms=$(aapt dump permissions "$apk" | grep -oE "name='[^']+'" | tr '\n' ' ')
say "permissões" "$perms"
# Só as permissões conhecidas: VIBRATE sempre; RECORD_AUDIO e CAMERA no celular (módulo FALAR: fala e espelho, só no aparelho).
for p in $perms; do
  case "$p" in "name='android.permission.VIBRATE'"|"name='android.permission.RECORD_AUDIO'"|"name='android.permission.CAMERA'") ;;
    *) fail=1; echo "PERMISSÃO INESPERADA: $p" ;; esac
done
case "$perms" in *VIBRATE*) ;; *) fail=1 ;; esac

tmp=$(mktemp -d)
unzip -q -o "$apk" 'lib/*' -d "$tmp"
bad=0
while read -r so; do
  if readelf -lW "$so" | awk '/LOAD/{print $NF}' | grep -qv '0x4000\|0x10000'; then bad=1; echo "  4 KB: $so"; fi
done < <(find "$tmp/lib/arm64-v8a" -name '*.so')  # 16 KB só existe em 64 bits; armv7 (TV TCL) usa 4 KB
rm -rf "$tmp"
[ $bad = 0 ] && say "nativas arm64 em 16 KB" ok || { fail=1; say "nativas arm64 em 16 KB" FALHOU; }

kids=0
for k in manuzita enzo aylinha; do
  for f in head ship; do
    h=$(printf "res://assets/characters/kids/%s/%s.png" "$k" "$f" | md5sum | cut -c1-32)
    kids=$((kids + $(unzip -l "$apk" | grep -c "$h" || true)))
  done
done
h=$(printf "res://assets/private/poder.ogg" | md5sum | cut -c1-32)
song=$(unzip -l "$apk" | grep -c "$h" || true)
for f in vini_joinha.png vini_head.png; do
  h=$(printf "res://assets/private/%s" "$f" | md5sum | cut -c1-32)
  song=$((song + $(unzip -l "$apk" | grep -c "$h" || true)))
done
say "fotos convidados" "$kids (rosto + nave)"
say "particular (música + 2 fotos)" "$song"
if [ "$kind" = publico ] && [ $((kids + song)) -gt 0 ]; then fail=1; echo "PRIVADO NO APK PÚBLICO"; fi
if [ "$kind" = completo ] && { [ "$kids" != 6 ] || [ "$song" != 3 ]; }; then fail=1; echo "COMPLETO SEM O PARTICULAR"; fi
[ $fail = 0 ] && echo "APK OK ($kind)" || { echo "APK COM PROBLEMA"; exit 1; }
