package javax.microedition.khronos.egl;
public interface EGL10 {
    EGLContext EGL_NO_CONTEXT = null;
    EGLContext eglCreateContext(EGLDisplay d, EGLConfig c, EGLContext s, int[] a);
    boolean eglDestroyContext(EGLDisplay d, EGLContext c);
    boolean eglGetConfigAttrib(EGLDisplay d, EGLConfig c, int a, int[] v);
    int eglGetError();
    String eglQueryString(EGLDisplay d, int n);
}
