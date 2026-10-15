package com.navnest.navnest

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.text.TextUtils
import java.io.File
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.navnest.navnest/focus_timer"
    private val BLOCKER_CHANNEL = "com.navnest.navnest/app_blocker"
    private val INSTALLER_CHANNEL = "com.navnest.navnest/apk_installer"

    private var blockerMethodChannel: MethodChannel? = null
    private var pendingBlockedPackage: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Focus Timer Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getElapsedRealtime" -> {
                    result.success(SystemClock.elapsedRealtime())
                }

                "getBootTimeInfo" -> {
                    val elapsed = SystemClock.elapsedRealtime()
                    val bootTimeEpoch = System.currentTimeMillis() - elapsed
                    result.success(
                        mapOf(
                            "elapsedRealtime" to elapsed,
                            "bootTimeEpochMs" to bootTimeEpoch,
                            "currentTimeMillis" to System.currentTimeMillis()
                        )
                    )
                }

                "startForegroundService" -> {
                    val title = call.argument<String>("title") ?: "NavNest Focus Session"
                    val content = call.argument<String>("content") ?: "Deep work in progress"
                    val deadlineMs = call.argument<Number>("deadlineMs")?.toLong() ?: 0L
                    val isCountdown = call.argument<Boolean>("isCountdown") ?: true
                    val isPaused = call.argument<Boolean>("isPaused") ?: false

                    val serviceIntent = Intent(this, FocusForegroundService::class.java).apply {
                        action = FocusForegroundService.ACTION_START
                        putExtra(FocusForegroundService.EXTRA_TITLE, title)
                        putExtra(FocusForegroundService.EXTRA_CONTENT, content)
                        putExtra(FocusForegroundService.EXTRA_DEADLINE_MS, deadlineMs)
                        putExtra(FocusForegroundService.EXTRA_IS_COUNTDOWN, isCountdown)
                        putExtra(FocusForegroundService.EXTRA_IS_PAUSED, isPaused)
                    }

                    try {
                        ContextCompat.startForegroundService(this, serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_FAILED", e.localizedMessage, null)
                    }
                }

                "updateNotification" -> {
                    val title = call.argument<String>("title")
                    val content = call.argument<String>("content")
                    val deadlineMs = call.argument<Number>("deadlineMs")?.toLong()
                    val isCountdown = call.argument<Boolean>("isCountdown")
                    val isPaused = call.argument<Boolean>("isPaused")

                    val serviceIntent = Intent(this, FocusForegroundService::class.java).apply {
                        action = FocusForegroundService.ACTION_UPDATE
                        title?.let { putExtra(FocusForegroundService.EXTRA_TITLE, it) }
                        content?.let { putExtra(FocusForegroundService.EXTRA_CONTENT, it) }
                        deadlineMs?.let { putExtra(FocusForegroundService.EXTRA_DEADLINE_MS, it) }
                        isCountdown?.let { putExtra(FocusForegroundService.EXTRA_IS_COUNTDOWN, it) }
                        isPaused?.let { putExtra(FocusForegroundService.EXTRA_IS_PAUSED, it) }
                    }

                    try {
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UPDATE_FAILED", e.localizedMessage, null)
                    }
                }

                "stopForegroundService" -> {
                    val serviceIntent = Intent(this, FocusForegroundService::class.java).apply {
                        action = FocusForegroundService.ACTION_STOP
                    }
                    try {
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_FAILED", e.localizedMessage, null)
                    }
                }

                "isIgnoringBatteryOptimizations" -> {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && powerManager != null) {
                        powerManager.isIgnoringBatteryOptimizations(packageName)
                    } else {
                        true
                    }
                    result.success(isIgnoring)
                }

                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            startActivity(fallbackIntent)
                            result.success(false)
                        }
                    } else {
                        result.success(true)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // App Blocker Channel
        val blockerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLOCKER_CHANNEL)
        blockerMethodChannel = blockerChannel
        blockerChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled(this))
                }

                "isAccessibilityServiceConnected" -> {
                    result.success(AppBlockerAccessibilityService.isServiceConnected)
                }

                "openAccessibilitySettings" -> {
                    try {
                        // On Android 13+ (API 33+), try to deep-link directly to NavNest's service settings
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            try {
                                val deepLinkIntent = Intent("android.settings.ACCESSIBILITY_DETAILS_SETTINGS").apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(deepLinkIntent)
                                result.success(true)
                            } catch (e: Exception) {
                                // Fall back to general accessibility settings on any failure
                                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(intent)
                                result.success(true)
                            }
                        } else {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("OPEN_SETTINGS_FAILED", e.localizedMessage, null)
                    }
                }

                "getInstalledLauncherApps" -> {
                    try {
                        val packageManager = packageManager
                        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        // On Android 11+ (API 30+) we need MATCH_ALL or GET_META_DATA to see all apps
                        val queryFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            android.content.pm.PackageManager.GET_META_DATA
                        } else {
                            0
                        }
                        @Suppress("DEPRECATION")
                        val resolveInfos = packageManager.queryIntentActivities(mainIntent, queryFlags)
                        val appList = mutableListOf<Map<String, Any>>()
                        val myPackage = packageName

                        for (info in resolveInfos) {
                            val pkg = info.activityInfo.packageName
                            if (pkg == myPackage) continue
                            val label = info.loadLabel(packageManager).toString()
                            val isSystem = (info.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                            appList.add(
                                mapOf(
                                    "packageName" to pkg,
                                    "appName" to label,
                                    "isSystemApp" to isSystem
                                )
                            )
                        }
                        appList.sortBy { (it["appName"] as String).lowercase() }
                        result.success(appList)
                    } catch (e: Exception) {
                        result.error("QUERY_APPS_FAILED", e.localizedMessage, null)
                    }
                }

                "updateBlockerConfig" -> {
                    try {
                        val isBlockingEnabled = call.argument<Boolean>("isBlockingEnabled") ?: true
                        val isSessionActive = call.argument<Boolean>("isSessionActive") ?: false
                        val isSessionPaused = call.argument<Boolean>("isSessionPaused") ?: false
                        val strictMode = call.argument<Boolean>("strictMode") ?: true
                        val packagesList = call.argument<List<String>>("blockedPackages") ?: emptyList()

                        AppBlockerAccessibilityService.updateState(
                            context = this,
                            blockingEnabled = isBlockingEnabled,
                            sessionActive = isSessionActive,
                            sessionPaused = isSessionPaused,
                            strict = strictMode,
                            packages = packagesList.toSet()
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UPDATE_CONFIG_FAILED", e.localizedMessage, null)
                    }
                }

                "getPendingBlockedIntervention" -> {
                    val pkg = pendingBlockedPackage
                    pendingBlockedPackage = null
                    result.success(pkg)
                }

                else -> result.notImplemented()
            }
        }

        // APK Installer Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALLER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    val canInstall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(canInstall)
                }

                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_PERMISSION_FAILED", e.localizedMessage, null)
                        }
                    } else {
                        result.success(true)
                    }
                }

                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "APK file path cannot be null or empty", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "APK file does not exist at $filePath", null)
                            return@setMethodCallHandler
                        }
                        val apkUri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )
                        val installIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(apkUri, "application/vnd.android.package-archive")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                        }
                        startActivity(installIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.localizedMessage, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // Check if activity was launched with an intervention action
        handleBlockedAppIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleBlockedAppIntent(intent)
    }

    private fun handleBlockedAppIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == AppBlockerAccessibilityService.ACTION_APP_BLOCKED) {
            val blockedPackage = intent.getStringExtra(AppBlockerAccessibilityService.EXTRA_BLOCKED_PACKAGE) ?: return
            val timestamp = intent.getLongExtra(AppBlockerAccessibilityService.EXTRA_BLOCKED_TIMESTAMP, System.currentTimeMillis())

            if (blockerMethodChannel != null) {
                blockerMethodChannel?.invokeMethod(
                    "onAppBlocked",
                    mapOf("packageName" to blockedPackage, "timestamp" to timestamp)
                )
            } else {
                pendingBlockedPackage = blockedPackage
            }
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val expectedService1 = "${context.packageName}/${AppBlockerAccessibilityService::class.java.canonicalName}"
        val expectedService2 = "${context.packageName}/.AppBlockerAccessibilityService"

        val enabledServicesSetting = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)

        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(expectedService1, ignoreCase = true) ||
                componentName.equals(expectedService2, ignoreCase = true)
            ) {
                return true
            }
        }
        return false
    }
}
