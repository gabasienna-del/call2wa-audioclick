package de.robv.android.xposed;
public final class XposedHelpers {
  public static Class<?> findClass(String name, ClassLoader loader){ return Object.class; }
  public static void findAndHookMethod(Class<?> cls, String name, Object... args){}
}
