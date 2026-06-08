package com.example.logincamara

import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
                if (call.method == "isMockLocationActive") {
                    requestFreshLocation(result)
                } else {
                    result.notImplemented()
                }
            }
    }

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
                    // TRUE si la ubicación viene de un proveedor simulado
                    result.success(location.isFromMockProvider)
                }

                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(p: String?, s: Int, e: Bundle?) {}
                override fun onProviderEnabled(p: String) {}
                override fun onProviderDisabled(p: String) {}
            }

            // Pedir ubicación fresca — mínima distancia 0 para que responda inmediato
            try {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    0L, 0f, listener, Looper.getMainLooper()
                )
            } catch (e: SecurityException) { /* sin permiso GPS */ }

            try {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    0L, 0f, listener, Looper.getMainLooper()
                )
            } catch (e: SecurityException) { /* sin permiso red */ }

            // Timeout de 4 segundos — si no llega ubicación fresca, usar caché limpiada
            mainHandler.postDelayed({
                if (!responded) {
                    responded = true
                    locationManager.removeUpdates(listener)
                    // Sin respuesta = no hay mock activo en este momento
                    result.success(false)
                }
            }, 4000)

        } catch (e: Exception) {
            result.error("LOCATION_ERROR", e.message, null)
        }
    }
}