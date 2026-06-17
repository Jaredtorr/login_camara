package com.example.logincamara

import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.logincamara/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isMockLocationActive" -> requestFreshLocation(result)
                    "isAdbEnabled"          -> result.success(checkAdbEnabled())
                    else -> result.notImplemented()
                }
            }
    }

    // ── Detección de Fake GPS (práctica anterior, sin cambios) ────
    private fun requestFreshLocation(result: MethodChannel.Result) {
        try {
            val locationManager =
                getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val mainHandler = Handler(Looper.getMainLooper())
            var responded = false

            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    if (responded) return
                    responded = true
                    locationManager.removeUpdates(this)
                    result.success(location.isFromMockProvider)
                }
                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(p: String?, s: Int, e: Bundle?) {}
                override fun onProviderEnabled(p: String) {}
                override fun onProviderDisabled(p: String) {}
            }

            try {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER, 0L, 0f, listener, Looper.getMainLooper())
            } catch (e: SecurityException) {}

            try {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER, 0L, 0f, listener, Looper.getMainLooper())
            } catch (e: SecurityException) {}

            mainHandler.postDelayed({
                if (!responded) {
                    responded = true
                    locationManager.removeUpdates(listener)
                    result.success(false)
                }
            }, 4000)

        } catch (e: Exception) {
            result.error("LOCATION_ERROR", e.message, null)
        }
    }

    // ── Detección de Depuración USB (ADB) — NUEVO ──────────────────
    // Consulta directamente la configuración global del sistema:
    // Settings.Global.ADB_ENABLED -> 1 significa que la Depuración USB
    // está activada en Ajustes -> Opciones de desarrollador.
    private fun checkAdbEnabled(): Boolean {
        return try {
            Settings.Global.getInt(
                contentResolver,
                Settings.Global.ADB_ENABLED,
                0
            ) == 1
        } catch (e: Exception) {
            false
        }
    }
}