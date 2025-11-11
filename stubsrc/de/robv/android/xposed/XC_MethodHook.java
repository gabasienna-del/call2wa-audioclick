package de.robv.android.xposed;
public class XC_MethodHook {
  public static class MethodHookParam { public Object thisObject; }
  public void afterHookedMethod(MethodHookParam param) throws Throwable {}
}
