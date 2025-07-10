// android/app/src/main/kotlin/com/example/formdakal/MainActivity.kt
package com.example.formdakal

import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.formdakal/native_step_counter"
        private const val EVENT_CHANNEL = "com.formdakal/native_step_stream"
    }
    
    private var sensorManager: SensorManager? = null
    private var stepCounterSensor: Sensor? = null
    private var stepDetectorSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null
    
    private var isListening = false
    private var initialStepCount = 0L
    private var currentTotalSteps = 0L
    private var dailySteps = 0L
    
    // Sensor listeners
    private val stepCounterListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
                val totalStepsSinceBoot = event.values[0].toLong()
                
                // İlk değeri kaydet
                if (initialStepCount == 0L) {
                    initialStepCount = totalStepsSinceBoot
                }
                
                // Günlük adımları hesapla
                dailySteps = totalStepsSinceBoot - initialStepCount
                currentTotalSteps = totalStepsSinceBoot
                
                // Flutter'a veri gönder
                sendStepCounterEvent(currentTotalSteps, dailySteps)
            }
        }
        
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
            // Accuracy değişikliklerini Flutter'a bildir
            eventSink?.success(mapOf(
                "type" to "SENSOR_ACCURACY",
                "accuracy" to accuracy,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }
    
    private val stepDetectorListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            if (event?.sensor?.type == Sensor.TYPE_STEP_DETECTOR) {
                // Her adım için tetiklenir
                eventSink?.success(mapOf(
                    "type" to "STEP_DETECTOR",
                    "timestamp" to System.currentTimeMillis(),
                    "stepDetected" to true
                ))
            }
        }
        
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Sensor manager'ı başlat
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        
        // Android 4.4+ (API 19) için TYPE_STEP_COUNTER ve TYPE_STEP_DETECTOR
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            stepCounterSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            stepDetectorSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
        }
        
        // Method Channel - Flutter'dan komut almak için
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkSensorAvailability" -> {
                        val stepCounterAvailable = stepCounterSensor != null
                        val stepDetectorAvailable = stepDetectorSensor != null
                        
                        result.success(mapOf(
                            "stepCounterAvailable" to stepCounterAvailable,
                            "stepDetectorAvailable" to stepDetectorAvailable,
                            "apiLevel" to Build.VERSION.SDK_INT
                        ))
                    }
                    
                    "startStepCounter" -> {
                        if (startStepCounting()) {
                            result.success("Native step counter started successfully")
                        } else {
                            result.error("SENSOR_ERROR", "Failed to start step counter", null)
                        }
                    }
                    
                    "stopStepCounter" -> {
                        stopStepCounting()
                        result.success("Native step counter stopped")
                    }
                    
                    "getCurrentStepData" -> {
                        result.success(mapOf(
                            "dailySteps" to dailySteps.toInt(),
                            "totalSteps" to currentTotalSteps.toInt(),
                            "initialStepCount" to initialStepCount.toInt()
                        ))
                    }
                    
                    "resetDailySteps" -> {
                        resetDailySteps()
                        result.success("Daily steps reset successfully")
                    }
                    
                    "startBackgroundService" -> {
                        startStepCounterService()
                        result.success("Background service started")
                    }
                    
                    "stopBackgroundService" -> {
                        stopStepCounterService()
                        result.success("Background service stopped")
                    }
                    
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        
        // Event Channel - Flutter'a sürekli veri göndermek için
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }
    
    @RequiresApi(Build.VERSION_CODES.KITKAT)
    private fun startStepCounting(): Boolean {
        if (stepCounterSensor == null) {
            return false
        }
        
        if (isListening) {
            return true // Zaten dinliyor
        }
        
        try {
            // TYPE_STEP_COUNTER sensörünü kaydet
            val stepCounterRegistered = sensorManager?.registerListener(
                stepCounterListener,
                stepCounterSensor,
                SensorManager.SENSOR_DELAY_UI
            ) ?: false
            
            // TYPE_STEP_DETECTOR sensörünü kaydet (varsa)
            var stepDetectorRegistered = true
            if (stepDetectorSensor != null) {
                stepDetectorRegistered = sensorManager?.registerListener(
                    stepDetectorListener,
                    stepDetectorSensor,
                    SensorManager.SENSOR_DELAY_UI
                ) ?: false
            }
            
            isListening = stepCounterRegistered
            
            if (isListening) {
                // Başarılı başlatma bildirimi
                eventSink?.success(mapOf(
                    "type" to "SERVICE_STARTED",
                    "stepCounterActive" to stepCounterRegistered,
                    "stepDetectorActive" to stepDetectorRegistered,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
            
            return isListening
            
        } catch (e: Exception) {
            eventSink?.success(mapOf(
                "type" to "ERROR",
                "message" to "Sensor registration failed: ${e.message}",
                "timestamp" to System.currentTimeMillis()
            ))
            return false
        }
    }
    
    private fun stopStepCounting() {
        if (!isListening) return
        
        sensorManager?.unregisterListener(stepCounterListener)
        sensorManager?.unregisterListener(stepDetectorListener)
        
        isListening = false
        
        eventSink?.success(mapOf(
            "type" to "SERVICE_STOPPED",
            "timestamp" to System.currentTimeMillis()
        ))
    }
    
    private fun resetDailySteps() {
        initialStepCount = currentTotalSteps
        dailySteps = 0L
        
        eventSink?.success(mapOf(
            "type" to "DAILY_RESET",
            "newInitialStepCount" to initialStepCount.toInt(),
            "timestamp" to System.currentTimeMillis()
        ))
    }
    
    private fun sendStepCounterEvent(totalSteps: Long, dailySteps: Long) {
        eventSink?.success(mapOf(
            "type" to "STEP_COUNTER",
            "totalSteps" to totalSteps.toInt(),
            "dailySteps" to dailySteps.toInt(),
            "timestamp" to System.currentTimeMillis()
        ))
    }
    
    private fun startStepCounterService() {
        val serviceIntent = Intent(this, StepCounterService::class.java)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0+ için Foreground Service
            startForegroundService(serviceIntent)
        } else {
            // Eski versiyonlar için Normal Service
            startService(serviceIntent)
        }
    }
    
    private fun stopStepCounterService() {
        val serviceIntent = Intent(this, StepCounterService::class.java)
        stopService(serviceIntent)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopStepCounting()
    }
    
    override fun onPause() {
        super.onPause()
        // Uygulama arka planda iken sensörleri ÇALIŞIR DURUMDA BIRAK
        // Bu sayede arka planda adım sayma devam eder
    }
    
    override fun onResume() {
        super.onResume()
        // Uygulama öne geldiğinde sensör durumunu kontrol et
        if (!isListening && stepCounterSensor != null) {
            startStepCounting()
        }
    }
}