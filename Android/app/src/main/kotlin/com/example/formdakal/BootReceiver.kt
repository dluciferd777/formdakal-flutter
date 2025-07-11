// android/app/src/main/kotlin/com/example/formdakal/BootReceiver.kt
package com.example.formdakal

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                
                // Step Counter Service'i başlat
                val serviceIntent = Intent(context, StepCounterService::class.java)
                
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        // Android 8.0+ için Foreground Service
                        context.startForegroundService(serviceIntent)
                    } else {
                        // Eski versiyonlar için Normal Service
                        context.startService(serviceIntent)
                    }
                    
                    android.util.Log.d("BootReceiver", "Step Counter Service started after boot")
                    
                } catch (e: Exception) {
                    android.util.Log.e("BootReceiver", "Failed to start service: ${e.message}")
                }
            }
        }
    }
}