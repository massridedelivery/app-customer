package com.massdrive.customer_app

import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var proximityLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The call screen turns the screen off against the ear
        // (CallProximity in call_screen.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "massmove/call_proximity")
            .setMethodCallHandler { call, result ->
                if (call.method == "set") {
                    setProximity(call.arguments as? Boolean ?: false)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun setProximity(on: Boolean) {
        if (on) {
            if (proximityLock?.isHeld == true) return
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!power.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) return
            proximityLock = power.newWakeLock(
                PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                "massmove:call_proximity",
            ).apply {
                setReferenceCounted(false)
                acquire(60 * 60 * 1000L)
            }
        } else {
            proximityLock?.let { if (it.isHeld) it.release() }
            proximityLock = null
        }
    }

    override fun onDestroy() {
        setProximity(false)
        super.onDestroy()
    }
}
