package com.example.manualentryticket

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.util.Base64
import android.util.Log
import androidx.annotation.WorkerThread
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "PlateOCR"
        private const val CHANNEL = "com.yourapp/plate_detection"

        private const val PLATE_CROP_WIDTH = 94
        private const val PLATE_CROP_HEIGHT = 24

        // Plate-detector model, bundled in android/app/src/main/assets/
        private const val MODEL_PATH = "best_float16.tflite"
    }

    private var detector: Detector? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initDetector()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "detectAndCropPlate" -> {

                        val base64Image = call.argument<String>("base64Image")

                        if (base64Image.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "base64Image is required", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Default).launch {
                            handleDetectAndCrop(base64Image, result)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // -----------------------------
    // INIT DETECTOR (ONCE ONLY)
    // -----------------------------
    private fun initDetector() {
        CoroutineScope(Dispatchers.Default).launch {
            try {
                detector = Detector(
                    baseContext,
                    MODEL_PATH
                ) { msg ->
                    Log.d(TAG, "Detector: $msg")
                }

                Log.d(TAG, "Detector initialized successfully")

            } catch (e: Exception) {
                Log.e(TAG, "Detector init failed", e)
            }
        }
    }

    // -----------------------------
    // MAIN PIPELINE
    // -----------------------------
    @WorkerThread
    private suspend fun handleDetectAndCrop(
        base64Image: String,
        result: MethodChannel.Result
    ) {
        try {

            // 1. Decode Base64 → Bitmap
            val originalBitmap = decodeBase64ToBitmap(base64Image)
                ?: return sendError(result, "DECODE_FAILED", "Invalid image data")

            // 2. Run YOLO detection
            val detectorLocal = detector
                ?: return sendError(result, "DETECTOR_NOT_READY", "Model not initialized")

            val boxes = detectorLocal.detect(originalBitmap)
            val diag = detectorLocal.lastDetectionInfo

            if (boxes.isNullOrEmpty()) {
                originalBitmap.recycle()
                withContext(Dispatchers.Main) {
                    result.success(mapOf("plate" to null, "diag" to diag))
                }
                return
            }

            // 3. Pick best box
            val best = boxes.maxByOrNull { it.cnf }!!

            val roi = Rect(
                (best.x1 * originalBitmap.width).toInt().coerceAtLeast(0),
                (best.y1 * originalBitmap.height).toInt().coerceAtLeast(0),
                (best.x2 * originalBitmap.width).toInt().coerceAtMost(originalBitmap.width),
                (best.y2 * originalBitmap.height).toInt().coerceAtMost(originalBitmap.height)
            )

            val cropped = cropAndResize(originalBitmap, roi)

            originalBitmap.recycle()

            if (cropped == null) {
                return sendError(result, "CROP_FAILED", "Invalid ROI")
            }

            // 4. Encode → Base64
            val croppedBase64 = bitmapToBase64(cropped)

            cropped.recycle()

            Log.d(TAG, "Crop success: ${croppedBase64.length} chars")

            // 5. Return to Flutter
            withContext(Dispatchers.Main) {
                result.success(mapOf("plate" to croppedBase64, "diag" to diag))
            }

        } catch (e: Exception) {
            Log.e(TAG, "detectAndCropPlate failed", e)
            sendError(result, "UNEXPECTED_ERROR", e.message ?: "unknown")
        }
    }

    // -----------------------------
    // IMAGE HELPERS
    // -----------------------------
    private fun decodeBase64ToBitmap(base64: String): Bitmap? {
        return try {
            val bytes = Base64.decode(base64, Base64.DEFAULT)
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        } catch (e: Exception) {
            null
        }
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }

    private fun cropAndResize(bitmap: Bitmap, rect: Rect): Bitmap? {
        if (rect.width() <= 0 || rect.height() <= 0) return null

        val cropped = Bitmap.createBitmap(
            bitmap,
            rect.left,
            rect.top,
            rect.width(),
            rect.height()
        )

        val resized = Bitmap.createScaledBitmap(
            cropped,
            PLATE_CROP_WIDTH,
            PLATE_CROP_HEIGHT,
            true
        )

        if (resized != cropped) cropped.recycle()

        return resized
    }

    // -----------------------------
    // ERROR HANDLER
    // -----------------------------
    private suspend fun sendError(
        result: MethodChannel.Result,
        code: String,
        message: String
    ) {
        withContext(Dispatchers.Main) {
            result.error(code, message, null)
        }
    }
}