package com.example.logincamara

import android.content.Context
import android.location.LocationManager
import android.os.Bundle
import android.view.WindowManager
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        if (isFakeGpsEnabled()) {
            Toast.makeText(this, "Fake GPS detectado. La app no puede ejecutarse.", Toast.LENGTH_LONG).show()
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        if (isFakeGpsEnabled()) {
            Toast.makeText(this, "Fake GPS detectado. La app no puede ejecutarse.", Toast.LENGTH_LONG).show()
            finish()
        }
    }

    override fun onPause() {
        super.onPause()
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    private fun isFakeGpsEnabled(): Boolean {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = locationManager.allProviders
        for (provider in providers) {
            if (locationManager.isProviderEnabled(provider)) {
                val location = locationManager.getLastKnownLocation(provider)
                if (location != null && location.isFromMockProvider) {
                    return true
                }
            }
        }
        return false
    }
}