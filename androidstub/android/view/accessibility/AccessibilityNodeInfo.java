package android.view.accessibility;
public class AccessibilityNodeInfo {
    public static final int ACTION_CLICK = 1;
    public CharSequence contentDescription;
    public boolean performAction(int action) { return true; }
    public int getChildCount() { return 0; }
    public AccessibilityNodeInfo getChild(int i) { return null; }
}
