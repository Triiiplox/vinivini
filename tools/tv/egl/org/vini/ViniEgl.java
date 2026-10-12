package org.vini;

import android.util.Log;
import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.egl.EGLDisplay;

/**
 * Escolha robusta da configuração de vídeo (EGL) para a TV TCL 50P735 (Realtek RT2851, Android 9).
 * O Godot 4.5 pega a PRIMEIRA configuração com as cores certas e depois pede um contexto OpenGL ES 3.0; na TCL
 * isso dava "createContext failed" e o app fechava. Aqui cada candidata é TESTADA (cria e destrói um contexto
 * ES 3.0) e vence a primeira que funciona — em 3 rodadas: cores e profundidade pedidas, qualquer profundidade
 * >= 16, e qualquer uma. Tudo vai para o log com a etiqueta "ViniEGL" (Bugjaeger: filtre por ViniEGL).
 */
public final class ViniEgl {
    private static final String TAG = "ViniEGL";
    private static final int RED = 0x3024, GREEN = 0x3023, BLUE = 0x3022, ALPHA = 0x3021, DEPTH = 0x3025,
        STENCIL = 0x3026, CAVEAT = 0x3027, CONFIG_ID = 0x3028, SAMPLES = 0x3031, RENDERABLE = 0x3040,
        SURFACE = 0x3033, NONE = 0x3038, CLIENT_VERSION = 0x3098, VENDOR = 0x3053, VERSION = 0x3054,
        CLIENT_APIS = 0x308D;
    private static boolean logged = false;

    private ViniEgl() {}

    public static EGLConfig pick(EGL10 egl, EGLDisplay d, EGLConfig[] cs, int r, int g, int b, int a, int depth,
            int stencil) {
        if (!logged) {
            logged = true;
            Log.i(TAG, "EGL vendor=" + egl.eglQueryString(d, VENDOR) + " version=" + egl.eglQueryString(d, VERSION)
                + " apis=" + egl.eglQueryString(d, CLIENT_APIS) + " configs=" + (cs == null ? 0 : cs.length));
        }
        if (cs == null) {
            return null;
        }
        for (int pass = 0; pass < 3; pass++) {
            for (EGLConfig c : cs) {
                if (c == null) {
                    continue;
                }
                int cr = attr(egl, d, c, RED), cg = attr(egl, d, c, GREEN), cb = attr(egl, d, c, BLUE);
                int ca = attr(egl, d, c, ALPHA), cd = attr(egl, d, c, DEPTH), cst = attr(egl, d, c, STENCIL);
                boolean ok;
                if (pass == 0) {
                    ok = cr == r && cg == g && cb == b && ca == a && cd >= depth && cst >= stencil;
                } else if (pass == 1) {
                    ok = cd >= 16 && cr >= 5;
                } else {
                    ok = true;
                }
                if (ok && works(egl, d, c, pass)) {
                    return c;
                }
            }
        }
        Log.e(TAG, "nenhuma configuracao aceitou contexto OpenGL ES 3.0 (pedido " + r + g + b + a + " d" + depth + ")");
        return null;
    }

    private static boolean works(EGL10 egl, EGLDisplay d, EGLConfig c, int pass) {
        egl.eglGetError();
        int[] list = {CLIENT_VERSION, 3, NONE};
        EGLContext ctx = egl.eglCreateContext(d, c, EGL10.EGL_NO_CONTEXT, list);
        int err = egl.eglGetError();
        boolean ok = ctx != null && ctx != EGL10.EGL_NO_CONTEXT;
        Log.i(TAG, "rodada " + pass + " config#" + attr(egl, d, c, CONFIG_ID) + " rgba=" + attr(egl, d, c, RED)
            + attr(egl, d, c, GREEN) + attr(egl, d, c, BLUE) + attr(egl, d, c, ALPHA) + " depth=" + attr(egl, d, c, DEPTH)
            + " stencil=" + attr(egl, d, c, STENCIL) + " samples=" + attr(egl, d, c, SAMPLES) + " renderable=0x"
            + Integer.toHexString(attr(egl, d, c, RENDERABLE)) + " surface=0x" + Integer.toHexString(attr(egl, d, c, SURFACE))
            + " caveat=0x" + Integer.toHexString(attr(egl, d, c, CAVEAT)) + " -> " + (ok ? "OK" : "falhou erro=0x"
            + Integer.toHexString(err)));
        if (ok) {
            egl.eglDestroyContext(d, ctx);
        }
        return ok;
    }

    private static int attr(EGL10 egl, EGLDisplay d, EGLConfig c, int key) {
        int[] v = new int[1];
        return egl.eglGetConfigAttrib(d, c, key, v) ? v[0] : -1;
    }
}
