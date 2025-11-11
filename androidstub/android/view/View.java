package android.view;
import android.view.accessibility.AccessibilityNodeInfo;

public class View {
    public View getRootView() { return this; }
    public AccessibilityNodeInfo createAccessibilityNodeInfo() {
        return new AccessibilityNodeInfo();
    }
}
