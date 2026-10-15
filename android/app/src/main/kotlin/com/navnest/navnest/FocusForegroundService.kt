package com.navnest.navnest

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

class FocusForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "navnest_focus_timer_channel"
        const val CHANNEL_NAME = "Study Focus Timer"
        const val NOTIFICATION_ID = 1092

        const val ACTION_START = "com.navnest.navnest.START_FOCUS"
        const val ACTION_UPDATE = "com.navnest.navnest.UPDATE_FOCUS"
        const val ACTION_STOP = "com.navnest.navnest.STOP_FOCUS"
        const val ACTION_PAUSE = "com.navnest.navnest.PAUSE_FOCUS"
        const val ACTION_RESUME = "com.navnest.navnest.RESUME_FOCUS"

        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_CONTENT = "extra_content"
        const val EXTRA_DEADLINE_MS = "extra_deadline_ms"
        const val EXTRA_IS_COUNTDOWN = "extra_is_countdown"
        const val EXTRA_IS_PAUSED = "extra_is_paused"

        var isServiceRunning = false
            private set
    }

    private var currentTitle = "NavNest Focus Session"
    private var currentContent = "Stay focused on your CBSE preparation."
    private var targetDeadlineMs: Long = 0
    private var isCountdown = true
    private var isPaused = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        when (intent.action) {
            ACTION_START -> {
                isServiceRunning = true
                extractExtras(intent)
                val notification = buildNotification()

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val serviceType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                    } else {
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                    }
                    ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, serviceType)
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            }

            ACTION_UPDATE -> {
                extractExtras(intent)
                val notification = buildNotification()
                val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.notify(NOTIFICATION_ID, notification)
            }

            ACTION_STOP -> {
                isServiceRunning = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }

        return START_NOT_STICKY
    }

    private fun extractExtras(intent: Intent) {
        intent.getStringExtra(EXTRA_TITLE)?.let { currentTitle = it }
        intent.getStringExtra(EXTRA_CONTENT)?.let { currentContent = it }
        if (intent.hasExtra(EXTRA_DEADLINE_MS)) {
            targetDeadlineMs = intent.getLongExtra(EXTRA_DEADLINE_MS, 0)
        }
        if (intent.hasExtra(EXTRA_IS_COUNTDOWN)) {
            isCountdown = intent.getBooleanExtra(EXTRA_IS_COUNTDOWN, true)
        }
        if (intent.hasExtra(EXTRA_IS_PAUSED)) {
            isPaused = intent.getBooleanExtra(EXTRA_IS_PAUSED, false)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(currentTitle)
            .setContentText(currentContent)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(contentPendingIntent)
            .setOngoing(!isPaused)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setPriority(NotificationCompat.PRIORITY_HIGH)

        // Native chronometer countdown on lockscreen/status bar
        if (!isPaused && targetDeadlineMs > System.currentTimeMillis()) {
            builder.setUsesChronometer(true)
            if (isCountdown) {
                builder.setChronometerCountDown(true)
            }
            builder.setWhen(targetDeadlineMs)
        } else {
            builder.setUsesChronometer(false)
        }

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows live focus timer countdown and controls on lockscreen and status bar"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        isServiceRunning = false
        super.onDestroy()
    }
}
