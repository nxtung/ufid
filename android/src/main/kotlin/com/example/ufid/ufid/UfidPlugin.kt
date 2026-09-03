package com.example.ufid.ufid

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * UfidPlugin
 *
 * Implements persistent device identification and reinstall detection on Android.
 * Retrieves ANDROID_ID using deep android.provider.Settings APIs (IPC Call & Cursor Query)
 * WITHOUT using PackageManager to avoid Package Visibility limitations and sensitive permissions.
 */
class UfidPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ufid")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val appContext = context
        if (appContext == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "getUFID" -> {
                val ufid = getDeepAndroidId(appContext)
                result.success(ufid)
            }
            "isReinstalled" -> {
                val (_, isReinstalled) = getInstallInfo(appContext)
                result.success(isReinstalled)
            }
            "getInfo" -> {
                val (ufid, isReinstalled) = getInstallInfo(appContext)
                val map = mapOf(
                    "ufid" to ufid,
                    "isReinstalled" to isReinstalled
                )
                result.success(map)
            }
            "reset" -> {
                val success = reset(appContext)
                result.success(success)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Retrieves Android ID using deep APIs in android.provider.Settings.
     * 1. Direct ContentResolver IPC Call ("GET_secure") to SettingsProvider.
     * 2. Direct ContentResolver Cursor Query on Settings.Secure.CONTENT_URI.
     * 3. Settings.Secure.getString fallback.
     */
    private fun getDeepAndroidId(ctx: Context): String {
        // Level 1: Deep IPC call to SettingsProvider via ContentResolver.call
        try {
            val uri = Settings.Secure.CONTENT_URI
            val bundle: Bundle? = ctx.contentResolver.call(
                uri,
                "GET_secure",
                Settings.Secure.ANDROID_ID,
                null
            )
            val value = bundle?.getString("value")
            if (!value.isNullOrBlank()) {
                return value
            }
        } catch (_: Throwable) {
            // Proceed to level 2
        }

        // Level 2: Direct Cursor Query on Settings.Secure.CONTENT_URI
        try {
            val cursor = ctx.contentResolver.query(
                Settings.Secure.CONTENT_URI,
                arrayOf("value"),
                "name=?",
                arrayOf(Settings.Secure.ANDROID_ID),
                null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val colIndex = it.getColumnIndex("value")
                    if (colIndex != -1) {
                        val value = it.getString(colIndex)
                        if (!value.isNullOrBlank()) {
                            return value
                        }
                    }
                }
            }
        } catch (_: Throwable) {
            // Proceed to level 3
        }

        // Level 3: Settings.Secure.getString API
        try {
            val value = Settings.Secure.getString(
                ctx.contentResolver,
                Settings.Secure.ANDROID_ID
            )
            if (!value.isNullOrBlank()) {
                return value
            }
        } catch (_: Throwable) {
            // Ignored
        }

        return ""
    }

    /**
     * Identifies whether the current launch is a re-installation or fresh install.
     */
    private fun getInstallInfo(ctx: Context): Pair<String, Boolean> {
        val ufid = getDeepAndroidId(ctx)

        val localPrefs: SharedPreferences = ctx.getSharedPreferences("ufid_local_state", Context.MODE_PRIVATE)
        val backupPrefs: SharedPreferences = ctx.getSharedPreferences("ufid_persistent_backup", Context.MODE_PRIVATE)

        val hasLaunchedInThisInstall = localPrefs.getBoolean("has_launched_in_install", false)
        val hasPreviousBackupState = backupPrefs.getBoolean("has_ever_installed", false)

        val isReinstalled: Boolean

        if (!hasLaunchedInThisInstall) {
            // First time launching in this installation
            isReinstalled = hasPreviousBackupState

            localPrefs.edit()
                .putBoolean("has_launched_in_install", true)
                .putBoolean("was_reinstalled", isReinstalled)
                .apply()

            backupPrefs.edit()
                .putBoolean("has_ever_installed", true)
                .putString("last_ufid", ufid)
                .putLong("first_recorded_time", System.currentTimeMillis())
                .apply()
        } else {
            // Subsequent launch in this installation
            isReinstalled = localPrefs.getBoolean("was_reinstalled", false)
        }

        return Pair(ufid, isReinstalled)
    }

    /**
     * Resets local flags (for testing purposes).
     */
    private fun reset(ctx: Context): Boolean {
        val localPrefs: SharedPreferences = ctx.getSharedPreferences("ufid_local_state", Context.MODE_PRIVATE)
        val backupPrefs: SharedPreferences = ctx.getSharedPreferences("ufid_persistent_backup", Context.MODE_PRIVATE)

        localPrefs.edit().clear().apply()
        backupPrefs.edit().clear().apply()
        return true
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }
}
