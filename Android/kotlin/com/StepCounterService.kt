// android/app/src/main/kotlin/com/example/formdakal/StepCounterService.kt
package com.example.formdakal

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat

class StepCounterService : Service() {
    
    companion object {
        private const val CHANNEL_ID = "formdakal_step_counter"
        private const val NOTIFICATION_ID = 1001
        private const val PREFS_NAME = "step_counter_prefs"
        private const val KEY_DAILY_STEPS = "daily_steps"
        private const val KEY_TOTAL_STEPS = "total_steps"
        private const val KEY_INITIAL_COUNT = "initial_count"
        private const val KEY_LAST_DATE = "last_date"
    }
    
    private var sensorManager: SensorManager? = null
    private var stepCounterSensor: Sensor? = null
    private var stepDetectorSensor: Sensor? = null
    
    private var dailySteps = 0L
    private var totalSteps = 0L
    private var initialStepCount = 0L
    private var isServiceRunning = false
    
    // Step Counter Listener
    private val stepCounterListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
                val currentTotal = event.values[0].toLong()
                
                // İlk başlatma
                if (initialStepCount == 0L) {
                    initialStepCount = currentTotal
                    saveToPreferences()
                }
                
                // Telefon yeniden başladıysa (step count düştü)
                if (currentTotal < initialStepCount) {
                    initialStepCount = 0L
                }
                
                // Günlük adımları hesapla
                val newDailySteps = currentTotal - initialStepCount
                
                if (newDailySteps != dailySteps) {
                    dailySteps = newDailySteps
                    totalSteps = currentTotal
                    
                    // Verileri kaydet
                    saveToPreferences()
                    
                    // Notification'ı güncelle
                    updateNotification()
                }
            }
        }