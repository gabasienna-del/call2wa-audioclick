package com.example.call2wa

import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityNodeInfo
import de.robv.android.xposed.IXposedHookLoadPackage
import de.robv.android.xposed.XC_MethodHook
import de.robv.android.xposed.XposedBridge
import de.robv.android.xposed.XposedHelpers
import de.robv.android.xposed.callbacks.XC_LoadPackage

class HookInit : IXposedHookLoadPackage {

    override fun handleLoadPackage(lpparam: XC_LoadPackage.LoadPackageParam) {
        if (lpparam.packageName != "com.whatsapp") return

        XposedBridge.log("Call2WA: loaded in WhatsApp")

        try {
            val activityClass = XposedHelpers.findClass(
                "android.app.Activity",
                lpparam.classLoader
            )

            XposedHelpers.findAndHookMethod(
                activityClass,
                "onResume",
                object : XC_MethodHook() {
                    override fun afterHookedMethod(param: MethodHookParam) {
                        val activity = param.thisObject as android.app.Activity
                        val rootView = activity.window?.decorView?.rootView ?: return

                        Handler(Looper.getMainLooper()).postDelayed({
                            try {
                                val root = rootView.rootView
                                val node = findAudioCallButton(root)
                                node?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                            } catch (_: Throwable) { }
                        }, 800)
                    }
                }
            )
        } catch (e: Throwable) {
            XposedBridge.log("Call2WA error: ${e.message}")
        }
    }

    private fun findAudioCallButton(root: Any?): AccessibilityNodeInfo? {
        if (root !is android.view.View) return null
        try {
            val node = root.rootView?.createAccessibilityNodeInfo()
            return findByDescription(node, "Аудиозвонок")
        } catch (_: Throwable) { }
        return null
    }

    private fun findByDescription(node: AccessibilityNodeInfo?, desc: String): AccessibilityNodeInfo? {
        if (node == null) return null
        if (node.contentDescription?.toString()?.contains(desc, true) == true) {
            return node
        }
        for (i in 0 until node.childCount) {
            val found = findByDescription(node.getChild(i), desc)
            if (found != null) return found
        }
        return null
    }
}
