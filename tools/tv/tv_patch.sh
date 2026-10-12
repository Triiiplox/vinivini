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
# Vídeo (crash na TCL 50P735 / Realtek RT2851, Android 9; logcat 12/10: "createContext failed" no GLThread): o
# Godot 4.5 usa a PRIMEIRA configuração EGL com as cores certas e depois pede um contexto OpenGL ES 3.0, que o driver
# da TV recusou (também com o filtro ES 3). Agora o RegularConfigChooser chama org.vini.ViniEgl.pick (tools/tv/egl,
# dex pronto em ViniEgl.dex): TESTA cada configuração criando um contexto ES 3.0 e usa a primeira que funciona;
# cada tentativa vai para o logcat com a etiqueta ViniEGL.
python3 - "$work/d" <<'PY'
import glob, re, sys
f = glob.glob(sys.argv[1] + "/smali*/org/godotengine/godot/xr/regular/RegularConfigChooser.smali")
assert len(f) == 1, "RegularConfigChooser.smali não encontrado"
s = open(f[0]).read()
cls = "Lorg/godotengine/godot/xr/regular/RegularConfigChooser;"
sig = ("chooseConfig(Ljavax/microedition/khronos/egl/EGL10;Ljavax/microedition/khronos/egl/EGLDisplay;"
       "[Ljavax/microedition/khronos/egl/EGLConfig;)Ljavax/microedition/khronos/egl/EGLConfig;")
m = re.search(r"\.method public " + re.escape(sig) + r".*?\.end method", s, re.S)
assert m, "chooseConfig(egl, display, configs) mudou no Godot: revisar o patch"
body = "\n".join([
    ".method public " + sig,
    "    .locals 9",
    "    move-object v0, p1",
    "    move-object v1, p2",
    "    move-object v2, p3",
    "    iget v3, p0, " + cls + "->mRedSize:I",
    "    iget v4, p0, " + cls + "->mGreenSize:I",
    "    iget v5, p0, " + cls + "->mBlueSize:I",
    "    iget v6, p0, " + cls + "->mAlphaSize:I",
    "    iget v7, p0, " + cls + "->mDepthSize:I",
    "    iget v8, p0, " + cls + "->mStencilSize:I",
    "    invoke-static/range {v0 .. v8}, Lorg/vini/ViniEgl;->pick(Ljavax/microedition/khronos/egl/EGL10;"
    "Ljavax/microedition/khronos/egl/EGLDisplay;[Ljavax/microedition/khronos/egl/EGLConfig;IIIIII)"
    "Ljavax/microedition/khronos/egl/EGLConfig;",
    "    move-result-object v0",
    "    return-object v0",
    ".end method"])
open(f[0], "w").write(s[:m.start()] + body + s[m.end():])
PY
# Tela de abertura do Android: fundo azul-escuro do jogo (o modelo do Godot deixa branco) com a nave no centro.
st="$work/d/res/values/styles.xml"
sed -i 's#<item name="windowSplashScreenAnimatedIcon">@mipmap/icon_foreground</item>#&<item name="windowSplashScreenBackground">\#ff0b1340</item>#' "$st"
grep -q windowSplashScreenBackground "$st" || { echo "splash não ajustado"; exit 1; }
mkdir -p "$work/d/res/drawable-xhdpi"
cp "$here/tv_banner.png" "$work/d/res/drawable-xhdpi/tv_banner.png"
java -jar "$APKTOOL" b "$work/d" -o "$work/u.apk" >/dev/null
# o escolhedor de vídeo entra como mais um dex (Android 5+ carrega classes2.dex, classes3.dex... sozinho)
n=$(unzip -l "$work/u.apk" | grep -cE ' classes[0-9]*\.dex$')
cp "$here/egl/ViniEgl.dex" "$work/classes$((n + 1)).dex"
(cd "$work" && zip -q -0 u.apk "classes$((n + 1)).dex")
"$bt/zipalign" -f -p 4 "$work/u.apk" "$work/a.apk"
"$bt/apksigner" sign --ks "$ks" --ks-key-alias vini --ks-pass pass:vinisideload --key-pass pass:vinisideload \
  --out "$out" "$work/a.apk" 2>/dev/null
rm -rf "$work" "$out.idsig"
echo "TV OK: $out"
