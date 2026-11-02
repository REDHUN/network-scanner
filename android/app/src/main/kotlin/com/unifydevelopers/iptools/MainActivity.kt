package com.unifydevelopers.iptools

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val WIFI_SETTINGS_CHANNEL = "ip_tools/wifi_settings"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIFI_SETTINGS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "openWifiSettings") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                result.success("wifi_settings")
            } catch (_: ActivityNotFoundException) {
                result.error("SETTINGS_UNAVAILABLE", "Wi-Fi settings are unavailable", null)
            }
        }
    }
}
