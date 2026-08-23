package com.antigravity.flow_notes_reminders

import android.app.*
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Foreground service that blocks a user-selected set of apps during a focus
 * session. While active it polls the foreground app via UsageStatsManager and,
 * whenever the user opens one of the blocked packages, shows a full-screen,
 * touch-blocking overlay until they return to the launcher/another allowed app.
 */
class FocusLockService : Service() {

    private lateinit var windowManager: WindowManager
    private var overlayView: LinearLayout? = null
    private val running = AtomicBoolean(false)
    private val handler = Handler(Looper.getMainLooper())
    private var endTimeMillis = 0L
    private var blockedPackages: Set<String> = emptySet()
    private var shownForPackage: String? = null

    companion object {
        const val CHANNEL_ID = "focus_lock"
        const val EXTRA_DURATION_MINUTES = "extra_duration_minutes"
        const val EXTRA_BLOCKED_PACKAGES = "extra_blocked_packages"
        private const val NOTIFICATION_ID = 4201
        private const val POLL_INTERVAL_MS = 800L
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val minutes = intent?.getIntExtra(EXTRA_DURATION_MINUTES, 25) ?: 25
        blockedPackages =
            intent?.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)?.toSet() ?: emptySet()
        if (minutes <= 0 || blockedPackages.isEmpty()) {
            stopSelf()
            return START_NOT_STICKY
        }
        endTimeMillis = System.currentTimeMillis() + minutes * 60_000L

        startForeground(NOTIFICATION_ID, buildNotification(minutes, blockedPackages.size))
        running.set(true)
        startPolling()
        return START_STICKY
    }

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!running.get()) return

            if (System.currentTimeMillis() >= endTimeMillis) {
                stopSelf()
                return
            }

            val foreground = currentForegroundPackage()
            val shouldBlock = foreground != null && blockedPackages.contains(foreground)

            if (shouldBlock && shownForPackage != foreground) {
                shownForPackage = foreground
                showOverlay()
            } else if (!shouldBlock && shownForPackage != null) {
                shownForPackage = null
                hideOverlay()
            }

            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    private fun startPolling() {
        handler.removeCallbacks(pollRunnable)
        handler.post(pollRunnable)
    }

    /** Best-effort detection of the foreground package via usage stats. */
    private fun currentForegroundPackage(): String? {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
            val begin = end - 1000 * 60 * 60 * 12
            val stats: List<UsageStats> = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, begin, end,
            )
            var latest: UsageStats? = null
            for (s in stats) {
                if (latest == null || s.lastTimeUsed > latest.lastTimeUsed) {
                    latest = s
                }
            }
            latest?.packageName
        } catch (_: Exception) {
            null
        }
    }

    private fun showOverlay() {
        if (overlayView != null) return
        if (!canDrawOverlays()) return

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        )
        params.gravity = Gravity.CENTER

        val view = LinearLayout(this).apply {
            gravity = android.view.Gravity.CENTER
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xEE12161A.toInt())
        }

        val title = TextView(this).apply {
            text = "Focus Mode Active"
            setTextColor(0xFFFFFFFF.toInt())
            textSize = 24f
        }
        val subtitle = TextView(this).apply {
            text = "This app is blocked until focus ends"
            setTextColor(0xFF94A3B8.toInt())
            textSize = 14f
            setPadding(0, 12, 0, 0)
        }
        view.addView(title)
        view.addView(subtitle)

        try {
            windowManager.addView(view, params)
            overlayView = view
        } catch (_: Exception) {
            overlayView = null
        }
    }

    private fun hideOverlay() {
        overlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (_: Exception) {
            }
        }
        overlayView = null
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            android.provider.Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    override fun onDestroy() {
        running.set(false)
        handler.removeCallbacks(pollRunnable)
        hideOverlay()
        super.onDestroy()
    }

    private fun buildNotification(minutes: Int, blockedCount: Int): Notification {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Focus Lock",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Blocks selected apps during focus mode"
        }
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(channel)

        val endIntent = PendingIntent.getService(
            this,
            0,
            Intent(this, FocusLockService::class.java),
            PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Focus Mode")
            .setContentText("$blockedCount apps blocked for $minutes minutes")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_lock_lock,
                    "End focus now",
                    endIntent,
                ).build(),
            )
            .build()
    }
}