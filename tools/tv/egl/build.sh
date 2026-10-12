#!/usr/bin/env bash
# Recompila tools/tv/egl/ViniEgl.dex (o escolhedor de vídeo da TV). Precisa de javac e do R8/D8 do Google:
#   curl -L -o r8.jar https://dl.google.com/android/maven2/com/android/tools/r8/8.5.35/r8-8.5.35.jar
# Uso: R8=/caminho/r8.jar tools/tv/egl/build.sh   (stubs/ = só para compilar; o Android já tem as classes reais)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
w=$(mktemp -d)
javac -nowarn --release 8 -d "$w/stubs" $(find "$here/stubs" -name "*.java")
javac -nowarn --release 8 -cp "$w/stubs" -d "$w/cls" "$here/org/vini/ViniEgl.java"
(cd "$w/stubs" && jar cf ../stubs.jar .)
mkdir -p "$w/dex"
java -cp "${R8:?defina R8}" com.android.tools.r8.D8 --release --min-api 24 --classpath "$w/stubs.jar" --output "$w/dex" \
  "$w/cls/org/vini/ViniEgl.class"
cp "$w/dex/classes.dex" "$here/ViniEgl.dex"
rm -rf "$w"
echo "ok: $here/ViniEgl.dex"
