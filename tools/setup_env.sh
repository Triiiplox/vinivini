#!/usr/bin/env bash
# Prepara um Linux (Ubuntu 24.04) para testar e gerar o APK sem Android Studio.
# - Godot 4.5.1 + export templates (GitHub releases)
# - apksigner/zipalign/adb via apt (substitui o Android SDK oficial no export sem Gradle)
# - JDK 17+ (testado com 21)
set -euo pipefail
GODOT_VER="4.5.1-stable"
TPL_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VER/-/.}"
SDK="/opt/android-sdk"

if ! command -v godot >/dev/null; then
  mkdir -p /opt/godot && cd /opt/godot
  curl -sSL -o godot.zip "https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_linux.x86_64.zip"
  unzip -o -q godot.zip && rm godot.zip
  ln -sf "/opt/godot/Godot_v${GODOT_VER}_linux.x86_64" /usr/local/bin/godot
fi
if [ ! -f "$TPL_DIR/android_release.apk" ]; then
  mkdir -p "$TPL_DIR" && cd /tmp
  curl -sSL -o tpl.tpz "https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_export_templates.tpz"
  unzip -o -q tpl.tpz "templates/android_*" "templates/linux_*x86_64" "templates/version.txt" "templates/icudt_godot.dat"
  cp templates/* "$TPL_DIR/" && rm -rf templates tpl.tpz
fi
apt-get install -y -q apksigner zipalign adb xvfb >/dev/null
mkdir -p "$SDK/platform-tools" "$SDK/build-tools/35.0.0"
ln -sf /usr/bin/adb "$SDK/platform-tools/adb"
ln -sf /usr/bin/apksigner "$SDK/build-tools/35.0.0/apksigner"
ln -sf /usr/bin/zipalign "$SDK/build-tools/35.0.0/zipalign"
JAVA_HOME_DIR="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
# Configura o editor (gera o arquivo na primeira execução).
godot --headless --editor --quit --path "$(dirname "$0")/../game" >/dev/null 2>&1 || true
CFG="$HOME/.config/godot/editor_settings-4.5.tres"
python3 - "$CFG" "$SDK" "$JAVA_HOME_DIR" <<'PY'
import re, sys
f, sdk, jdk = sys.argv[1:4]
s = open(f).read()
s = re.sub(r'^export/android/(android_sdk_path|java_sdk_path) = .*\n', '', s, flags=re.M)
s = s.replace('[resource]\n', '[resource]\nexport/android/android_sdk_path = "%s"\nexport/android/java_sdk_path = "%s"\n' % (sdk, jdk), 1)
open(f, 'w').write(s)
PY
pip install -q "gdtoolkit==4.*" pillow 2>/dev/null || true
echo "ok: godot $(godot --version)"
