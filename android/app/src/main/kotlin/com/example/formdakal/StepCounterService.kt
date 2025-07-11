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
import java.text.SimpleDateFormat
import java.util.*

class StepCounterService : Service() {
    
    companion object {
        private const val CHANNEL_ID = "formdakal_step_counter_foreground"
        private const val NOTIFICATION_ID = 1001
        // private const val PREFS_NAME = "step_counter_prefs" // KALDIRILDI
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
        
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
            // Sensor accuracy değişikliklerini handle et
        }
    }
    
    // Step Detector Listener (opsiyonel - her adım için tetiklenir)
    private val stepDetectorListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            if (event?.sensor?.type == Sensor.TYPE_STEP_DETECTOR) {
                // Her adım için tetiklenir - real-time feedback için kullanılabilir
                android.util.Log.d("StepCounterService", "Step detected!")
            }
        }
        
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    override fun onCreate() {
        super.onCreate()
        
        // Sensor Manager'ı başlat
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        
        // Step Counter ve Step Detector sensörlerini al
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            stepCounterSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            stepDetectorSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
        }
        
        // Notification channel oluştur
        createNotificationChannel()
        
        // Kaydedilmiş verileri yükle
        loadFromPreferences()
        
        android.util.Log.d("StepCounterService", "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        android.util.Log.d("StepCounterService", "Service started")
        
        // Eğer zaten çalışıyorsa, restart
        if (isServiceRunning) {
            stopStepCounting()
        }
        
        // Step counting başlat
        startStepCounting()
        
        // Foreground service olarak başlat
        startForeground(NOTIFICATION_ID, createNotification())
        
        // START_STICKY: Service kapandığında otomatik restart
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        // Bu service bind edilebilir değil
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        android.util.Log.d("StepCounterService", "Service destroyed")
        stopStepCounting()
    }
    
    private fun startStepCounting() {
        if (stepCounterSensor == null) {
            android.util.Log.e("StepCounterService", "Step Counter sensor not available!")
            return
        }
        
        try {
            // Step Counter sensörünü kaydet
            val stepCounterRegistered = sensorManager?.registerListener(
                stepCounterListener,
                stepCounterSensor,
                SensorManager.SENSOR_DELAY_UI
            ) ?: false
            
            // Step Detector sensörünü kaydet (varsa)
            var stepDetectorRegistered = true
            if (stepDetectorSensor != null) {
                stepDetectorRegistered = sensorManager?.registerListener(
                    stepDetectorListener,
                    stepDetectorSensor,
                    SensorManager.SENSOR_DELAY_UI
                ) ?: false
            }
            
            isServiceRunning = stepCounterRegistered
            
            android.util.Log.d("StepCounterService", 
                "Step counting started - Counter: $stepCounterRegistered, Detector: $stepDetectorRegistered")
                
        } catch (e: Exception) {
            android.util.Log.e("StepCounterService", "Failed to start step counting: ${e.message}")
        }
    }
    
    private fun stopStepCounting() {
        if (!isServiceRunning) return
        
        sensorManager?.unregisterListener(stepCounterListener)
        sensorManager?.unregisterListener(stepDetectorListener)
        
        isServiceRunning = false
        
        android.util.Log.d("StepCounterService", "Step counting stopped")
    }
    
    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Adım Sayacı Arka Plan Servisi",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Arka planda adım sayma servisi bildirimi"
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        
        notificationManager.createNotificationChannel(channel)
    }
    
    private fun createNotification(): Notification {
        // Ana aktiviteye gidecek intent
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("FormdaKal Adım Sayacı")
            .setContentText("Bugün: $dailySteps adım")
            .setSmallIcon(android.R.drawable.ic_menu_directions) // Varsayılan icon
            .setContentIntent(pendingIntent)
            .setOngoing(true) // Notification sürüklenip silinemesin
            .setSilent(true) // Ses yok
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }
    
    private fun updateNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, createNotification())
    }
    
    private fun saveToPreferences() {
        try {
            // getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE) yerine varsayılanı kullan
            val prefs = getSharedPreferences(packageName + "_preferences", Context.MODE_PRIVATE) // Varsayılan SharedPreferences dosyasının adı
            val editor = prefs.edit()
            
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
            
            editor.putLong(KEY_DAILY_STEPS, dailySteps)
            editor.putLong(KEY_TOTAL_STEPS, totalSteps)
            editor.putLong(KEY_INITIAL_COUNT, initialStepCount)
            editor.putString(KEY_LAST_DATE, today)
            
            editor.apply()
            
        } catch (e: Exception) {
            android.util.Log.e("StepCounterService", "Failed to save preferences: ${e.message}")
        }
    }
    
    private fun loadFromPreferences() {
        try {
            // getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE) yerine varsayılanı kullan
            val prefs = getSharedPreferences(packageName + "_preferences", Context.MODE_PRIVATE) // Varsayılan SharedPreferences dosyasının adı
            
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
            val lastDate = prefs.getString(KEY_LAST_DATE, "")
            
            // Eğer yeni bir gün başladıysa günlük adımları sıfırla
            if (lastDate != today) {
                dailySteps = 0L
                initialStepCount = 0L
                android.util.Log.d("StepCounterService", "New day detected, resetting daily steps")
            } else {
                dailySteps = prefs.getLong(KEY_DAILY_STEPS, 0L)
                initialStepCount = prefs.getLong(KEY_INITIAL_COUNT, 0L)
            }
            
            totalSteps = prefs.getLong(KEY_TOTAL_STEPS, 0L)
            
            android.util.Log.d("StepCounterService", 
                "Loaded from preferences - Daily: $dailySteps, Total: $totalSteps, Initial: $initialStepCount")
                
        } catch (e: Exception) {
            android.util.Log.e("StepCounterService", "Failed to load preferences: ${e.message}")
        }
    }
}
