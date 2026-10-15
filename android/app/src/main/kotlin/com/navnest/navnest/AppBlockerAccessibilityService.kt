package com.navnest.navnest

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "NavNestBlockerService"
        const val PREFS_NAME = "navnest_blocker_prefs"
        const val KEY_IS_BLOCKING_ENABLED = "is_blocking_enabled"
        const val KEY_IS_SESSION_ACTIVE = "is_session_active"
        const val KEY_IS_SESSION_PAUSED = "is_session_paused"
        const val KEY_BLOCKED_PACKAGES = "blocked_packages"
        const val KEY_STRICT_MODE = "strict_mode"

        const val ACTION_APP_BLOCKED = "com.navnest.navnest.ACTION_APP_BLOCKED"
        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"
        const val EXTRA_BLOCKED_TIMESTAMP = "blocked_timestamp"

        @Volatile
        var isServiceConnected: Boolean = false
            private set

        @Volatile
        var isBlockingEnabled: Boolean = true

        @Volatile
        var isSessionActive: Boolean = false

        @Volatile
        var isSessionPaused: Boolean = false

        @Volatile
        var strictMode: Boolean = true

        @Volatile
        var blockedPackages: Set<String> = emptySet()

        private var lastBlockedPackage: String? = null
        private var lastBlockedTime: Long = 0L

        fun updateState(
            context: Context,
            blockingEnabled: Boolean,
            sessionActive: Boolean,
            sessionPaused: Boolean,
            strict: Boolean,
            packages: Set<String>
        ) {
            isBlockingEnabled = blockingEnabled
            isSessionActive = sessionActive
            isSessionPaused = sessionPaused
            strictMode = strict
            blockedPackages = packages

            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean(KEY_IS_BLOCKING_ENABLED, blockingEnabled)
                .putBoolean(KEY_IS_SESSION_ACTIVE, sessionActive)
                .putBoolean(KEY_IS_SESSION_PAUSED, sessionPaused)
                .putBoolean(KEY_STRICT_MODE, strict)
                .putStringSet(KEY_BLOCKED_PACKAGES, packages)
                .apply()
        }

        fun loadState(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            isBlockingEnabled = prefs.getBoolean(KEY_IS_BLOCKING_ENABLED, true)
            isSessionActive = prefs.getBoolean(KEY_IS_SESSION_ACTIVE, false)
            isSessionPaused = prefs.getBoolean(KEY_IS_SESSION_PAUSED, false)
            strictMode = prefs.getBoolean(KEY_STRICT_MODE, true)
            blockedPackages = prefs.getStringSet(KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceConnected = true
        loadState(applicationContext)
        Log.i(TAG, "NavNest AppBlockerAccessibilityService connected and state loaded.")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val targetPackage = event.packageName?.toString() ?: return
        val myPackage = applicationContext.packageName

        // CRITICAL LOOP GUARD: Never block NavNest itself or core system packages
        if (targetPackage == myPackage ||
            targetPackage == "com.android.systemui" ||
            targetPackage == "com.android.settings" ||
            targetPackage == "android" ||
            targetPackage.contains("launcher", ignoreCase = true) ||
            targetPackage.contains("inputmethod", ignoreCase = true)
        ) {
            return
        }

        // Reload state from SharedPreferences if blockedPackages is empty in memory
        // (this happens after process recreation — @Volatile fields reset to defaults)
        if (blockedPackages.isEmpty()) {
            loadState(applicationContext)
        }

        // Only enforce when blocking is enabled AND an eligible focus session is active and unpaused
        if (!isBlockingEnabled || !isSessionActive || isSessionPaused) {
            return
        }

        // Check against user-selected restricted packages
        if (!blockedPackages.contains(targetPackage)) {
            return
        }

        // Debounce repeated window state changes within 1500ms for the same package
        val now = System.currentTimeMillis()
        if (targetPackage == lastBlockedPackage && (now - lastBlockedTime) < 1500L) {
            return
        }
        lastBlockedPackage = targetPackage
        lastBlockedTime = now

        Log.w(TAG, "Restricted app foreground transition detected: $targetPackage. Applying distraction shield.")

        // Step 1: Minimize the restricted app by returning to Home screen
        try {
            performGlobalAction(GLOBAL_ACTION_HOME)
        } catch (e: Exception) {
            Log.e(TAG, "Error performing global home action: ${e.message}")
        }

        // Step 2: Bring NavNest to the foreground with the intervention payload
        try {
            val intent = Intent(applicationContext, MainActivity::class.java).apply {
                action = ACTION_APP_BLOCKED
                putExtra(EXTRA_BLOCKED_PACKAGE, targetPackage)
                putExtra(EXTRA_BLOCKED_TIMESTAMP, now)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error launching NavNest intervention activity: ${e.message}")
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "NavNest AppBlockerAccessibilityService interrupted.")
    }

    override fun onDestroy() {
        isServiceConnected = false
        super.onDestroy()
        Log.i(TAG, "NavNest AppBlockerAccessibilityService destroyed.")
    }
}
