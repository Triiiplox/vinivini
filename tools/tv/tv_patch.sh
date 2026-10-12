#!/usr/bin/env bash
# Ajusta o APK da versão de TV (exportado pelo Godot com o preset "Android TV") para a Android TV da TCL:
# o export sem Gradle do Godot 4.5 ignora "show_in_android_tv" — sem a categoria LEANBACK_LAUNCHER o app não aparece
# na tela inicial da TV. Aqui: categoria de TV, banner 640x360, toque/faketouch não obrigatórios, controle opcional;
# depois zipalign e assinatura com a mesma chave do celular (mas é OUTRO app: com.vinicomandante.estrelas.tv).
# Uso: tools/tv/tv_patch.sh <entrada.apk> <saida.apk>   (APKTOOL=/caminho/apktool.jar)
set -euo pipefail
in="$1"; out="$2"
here="$(cd "$(dirname "$0")" && pwd)"
bt=/opt/android-sdk/build-tools/35.0.0
ks="$here/../../game/android/vini-sideload.keystore"
work=$(mktemp -d)
java -jar "${APKTOOL:?defina APKTOOL}" d -f "$in" -o "$work/d" >/dev/null
m="$work/d/AndroidManifest.xml"
python3 - "$m" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
s = re.sub(r'<uses-feature android:name="android.hardware.faketouch"[^>]*/>',
           '<uses-feature android:name="android.hardware.faketouch" android:required="false"/>', s)
# Sem microfone na TV (4.6.0 crashava ao abrir; a 4.4 sem microfone abria): nada de microfone obrigatório.
s = re.sub(r'<uses-feature android:name="android.hardware.microphone"[^>]*/>', '', s)
extra = ('<uses-feature android:name="android.hardware.touchscreen" android:required="false"/>'
         '<uses-feature android:name="android.software.leanback" android:required="false"/>'
         '<uses-feature android:name="android.hardware.gamepad" android:required="false"/>')
s = s.replace('<application ', extra + '<application android:banner="@drawable/tv_banner" ', 1)
s = s.replace('<category android:name="android.intent.category.LAUNCHER"/>',
              '<category android:name="android.intent.category.LAUNCHER"/>'
              '<category android:name="android.intent.category.LEANBACK_LAUNCHER"/>', 1)
assert "LEANBACK_LAUNCHER" in s and "tv_banner" in s, "manifesto não ajustado"
open(p, "w", encoding="utf-8").write(s)
PY
# o modelo do Godot declara o ícone "temático" como bool vazio (false) — o aapt2 do apktool recusa; vira um apelido
# válido do primeiro plano do ícone (ninguém o usa: o ícone adaptativo só tem fundo e primeiro plano).
mm="$work/d/res/values-anydpi-v26/mipmaps.xml"
[ -f "$mm" ] && sed -i 's#<item type="mipmap" name="themed_icon">false</item>#<item type="mipmap" name="themed_icon">@mipmap/icon_foreground</item>#' "$mm"
# Vídeo (crash na TCL BeyondTV2, logcat 12/10: "createContext failed" no GLThread): o Godot 4.5 escolhe a
# configuração EGL filtrando só por "suporta OpenGL ES 2" e depois pede um contexto ES 3.0 — em drivers de TV a
# configuração escolhida pode não aceitar 3.0. Aqui o filtro passa a exigir ES 3 (EGL_OPENGL_ES3_BIT_KHR = 0x40).
# Se a GPU só tiver ES 2, o erro vira "No configs match configSpec" (e aí o Godot 4 não roda nesse aparelho).
python3 - "$work/d" <<'PY'
import glob, sys
f = glob.glob(sys.argv[1] + "/smali*/org/godotengine/godot/xr/regular/RegularConfigChooser.smali")
assert len(f) == 1, "RegularConfigChooser.smali não encontrado"
s = open(f[0]).read()
old = "        0x3040\n        0x4\n"
assert s.count(old) == 1, "configSpec do EGL mudou no Godot: revisar o patch"
open(f[0], "w").write(s.replace(old, "        0x3040\n        0x40\n"))
PY
# Tela de abertura do Android: fundo azul-escuro do jogo (o modelo do Godot deixa branco) com a nave no centro.
st="$work/d/res/values/styles.xml"
sed -i 's#<item name="windowSplashScreenAnimatedIcon">@mipmap/icon_foreground</item>#&<item name="windowSplashScreenBackground">\#ff0b1340</item>#' "$st"
grep -q windowSplashScreenBackground "$st" || { echo "splash não ajustado"; exit 1; }
mkdir -p "$work/d/res/drawable-xhdpi"
cp "$here/tv_banner.png" "$work/d/res/drawable-xhdpi/tv_banner.png"
java -jar "$APKTOOL" b "$work/d" -o "$work/u.apk" >/dev/null
"$bt/zipalign" -f -p 4 "$work/u.apk" "$work/a.apk"
"$bt/apksigner" sign --ks "$ks" --ks-key-alias vini --ks-pass pass:vinisideload --key-pass pass:vinisideload \
  --out "$out" "$work/a.apk" 2>/dev/null
rm -rf "$work" "$out.idsig"
echo "TV OK: $out"
