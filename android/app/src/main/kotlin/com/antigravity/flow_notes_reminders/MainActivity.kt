package com.antigravity.flow_notes_reminders

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.antigravity.flow_notes_reminders/focus_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val minutes = call.argument<Int>("minutes") ?: 25
                        val packages =
                            call.argument<List<String>>("packages") ?: emptyList()
                        startFocusLock(minutes, packages)
                        result.success(true)
                    }
                    "stop" -> {
                        stopFocusLock()
                        result.success(true)
                    }
                    "canDrawOverlay" -> {
                        result.success(canDrawOverlay())
                    }
                    "openOverlaySettings" -> {
                        openOverlaySettings()
                        result.success(true)
                    }
                    "canAccessUsageStats" -> {
                        result.success(canAccessUsageStats())
                    }
                    "openUsageStatsSettings" -> {
                        openUsageStatsSettings()
                        result.success(true)
                    }
                    "listInstalledApps" -> {
                        result.success(listInstalledApps())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startFocusLock(minutes: Int, packages: List<String>) {
        val intent = Intent(this, FocusLockService::class.java)
            .putExtra(FocusLockService.EXTRA_DURATION_MINUTES, minutes)
            .putStringArrayListExtra(
                FocusLockService.EXTRA_BLOCKED_PACKAGES,
                ArrayList(packages),
            )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopFocusLock() {
        stopService(Intent(this, FocusLockService::class.java))
    }

    private fun canDrawOverlay(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            Settings.canDrawOverlays(this)
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName"),
            )
            startActivity(intent)
        }
    }

    private fun canAccessUsageStats(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP ||
            hasUsageStatsPermission()
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(android.app.AppOpsManager::class.java)
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName,
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageStatsSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        try {
            startActivity(intent)
        } catch (_: Exception) {
            // Fallback: open app details
            val fallback = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            )
            startActivity(fallback)
        }
    }

    private fun listInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolveInfos = pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)

        val result = mutableListOf<Map<String, String>>()
        val seen = mutableSetOf<String>()
        for (info in resolveInfos) {
            val pkg = info.activityInfo.packageName
            if (pkg == packageName) continue
            if (!seen.add(pkg)) continue
            val label = try {
                pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
            } catch (_: Exception) {
                pkg
            }
            result.add(mapOf("package" to pkg, "label" to label))
        }
        return result.sortedBy { it["label"] }
    }
}