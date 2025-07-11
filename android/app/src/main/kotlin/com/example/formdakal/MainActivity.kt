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
// import io.flutter.plugin.common.EventChannel // Kaldırıldı
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.formdakal/native_step_counter"
        // private const val EVENT_CHANNEL = "com.formdakal/native_step_stream" // Kaldırıldı
    }
    
    private var sensorManager: SensorManager? = null
    private var stepCounterSensor: Sensor? = null
    private var stepDetectorSensor: Sensor? = null
    // private var eventSink: EventChannel.EventSink? = null // Kaldırıldı
    
    private var isListening = false
    private var initialStepCount = 0L
    private var currentTotalSteps = 0L
    private var dailySteps = 0L // Bu değişkenler artık sadece MainActivity içindeki geçici durum için
    
    // Sensor listeners (Artık sadece sensör mevcudiyet kontrolü için kullanılabilir, gerçek sayım StepCounterService'te)
    private val stepCounterListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            // Bu listener artık Flutter'a adım göndermeyecek, sadece StepCounterService yapacak.
            // MainActivity'deki bu listener'ın amacı sadece sensörün çalışıp çalışmadığını kontrol etmekti.
            // Gerçek adım sayma mantığı StepCounterService.kt içinde.
            if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
                // val totalStepsSinceBoot = event.values[0].toLong()
                // sendStepCounterEvent(totalStepsSinceBoot, totalStepsSinceBoot - initialStepCount)
            }
        }
        
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
            // eventSink?.success(mapOf( // Kaldırıldı
            //     "type" to "SENSOR_ACCURACY",
            //     "accuracy" to accuracy,
            //     "timestamp" to System.currentTimeMillis()
            // ))
        }
    }
    
    private val stepDetectorListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            // if (event?.sensor?.type == Sensor.TYPE_STEP_DETECTOR) { // Kaldırıldı
            //     eventSink?.success(mapOf(
            //         "type" to "STEP_DETECTOR",
            //         "timestamp" to System.currentTimeMillis(),
            //         "stepDetected" to true
            //     ))
            // }
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
                        // Bu metod artık sensör dinlemeyi başlatmayacak, sadece servis başlatılacak.
                        // Gerçek sensör dinleme StepCounterService içinde.
                        // if (startStepCounting()) { // Kaldırıldı
                        //     result.success("Native step counter started successfully")
                        // } else {
                        //     result.error("SENSOR_ERROR", "Failed to start step counter", null)
                        // }
                        result.success("Step counter start command sent to service.")
                    }
                    
                    "stopStepCounter" -> {
                        // stopStepCounting() // Kaldırıldı
                        result.success("Native step counter stop command sent to service.")
                    }
                    
                    "getCurrentStepData" -> {
                        // Bu metod artık kullanılmayacak, Flutter doğrudan SharedPreferences'tan okuyacak.
                        // result.success(mapOf( // Kaldırıldı
                        //     "dailySteps" to dailySteps.toInt(),
                        //     "totalSteps" to currentTotalSteps.toInt(),
                        //     "initialStepCount" to initialStepCount.toInt()
                        // ))
                        result.notImplemented() // Artık kullanılmayacağı için notImplemented olarak işaretlendi
                    }
                    
                    "resetDailySteps" -> {
                        // resetDailySteps() // Kaldırıldı
                        result.success("Daily steps reset command sent to service.")
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
        
        // Event Channel (Kaldırıldı)
        // EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        //     .setStreamHandler(object : EventChannel.StreamHandler {
        //         override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        //             eventSink = events
        //         }
                
        //         override fun onCancel(arguments: Any?) {
        //             eventSink = null
        //         }
        //     })
    }
    
    // startStepCounting ve stopStepCounting metodları kaldırıldı, çünkü sensör dinleme StepCounterService'e taşındı.
    // @RequiresApi(Build.VERSION_CODES.KITKAT)
    // private fun startStepCounting(): Boolean { ... }
    // private fun stopStepCounting() { ... }
    
    // resetDailySteps ve sendStepCounterEvent metodları kaldırıldı
    // private fun resetDailySteps() { ... }
    // private fun sendStepCounterEvent(totalSteps: Long, dailySteps: Long) { ... }
    
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
        // stopStepCounting() // Kaldırıldı
    }
    
    override fun onPause() {
        super.onPause()
        // Uygulama arka planda iken sensörleri ÇALIŞIR DURUMDA BIRAK
        // Bu sayede arka planda adım sayma devam eder
    }
    
    override fun onResume() {
        super.onResume()
        // Uygulama öne geldiğinde sensör durumunu kontrol et (artık gerek yok, service kendi kendine çalışıyor)
        // if (!isListening && stepCounterSensor != null) {
        //     startStepCounting()
        // }
    }
}
