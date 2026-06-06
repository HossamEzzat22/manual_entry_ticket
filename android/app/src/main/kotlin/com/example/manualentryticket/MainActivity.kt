package com.example.manualentryticket

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Rect
import android.media.ExifInterface
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
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "PlateOCR"
        private const val CHANNEL = "com.yourapp/plate_detection"

//        private const val PLATE_CROP_WIDTH = 200
//        private const val PLATE_CROP_HEIGHT = 50
        private const val PLATE_TARGET_HEIGHT = 50


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

            // 1. Decode Base64 → Bitmap (and apply EXIF orientation — BitmapFactory
            //    ignores it, which would feed the model a sideways image).
            val decoded = decodeBase64ToBitmap(base64Image)
                ?: return sendError(result, "DECODE_FAILED", "Invalid image data")
            val originalBitmap = decoded.bitmap
            val exifOrientation = decoded.exifOrientation

            // 2. Run YOLO detection
            val detectorLocal = detector
                ?: return sendError(result, "DETECTOR_NOT_READY", "Model not initialized")

            val boxes = detectorLocal.detect(originalBitmap)
            val diag = "exif=$exifOrientation " + detectorLocal.lastDetectionInfo

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
    private data class DecodedImage(val bitmap: Bitmap, val exifOrientation: Int)

    private fun decodeBase64ToBitmap(base64: String): DecodedImage? {
        return try {
            val bytes = Base64.decode(base64, Base64.DEFAULT)
            val raw = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null

            // BitmapFactory does NOT apply EXIF rotation, so read it from the
            // same bytes and rotate the bitmap upright before detection.
            val orientation = try {
                ExifInterface(ByteArrayInputStream(bytes))
                    .getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            } catch (e: Exception) {
                ExifInterface.ORIENTATION_NORMAL
            }

            DecodedImage(applyExifOrientation(raw, orientation), orientation)
        } catch (e: Exception) {
            null
        }
    }

    private fun applyExifOrientation(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { matrix.postRotate(90f); matrix.postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_TRANSVERSE -> { matrix.postRotate(270f); matrix.postScale(-1f, 1f) }
            else -> return bitmap // ORIENTATION_NORMAL / UNDEFINED → nothing to do
        }
        val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        if (rotated != bitmap) bitmap.recycle()
        return rotated
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }

    // AFTER
    private fun cropAndResize(bitmap: Bitmap, rect: Rect): Bitmap? {
        if (rect.width() <= 0 || rect.height() <= 0) return null

        val cropped = Bitmap.createBitmap(
            bitmap,
            rect.left,
            rect.top,
            rect.width(),
            rect.height()
        )

        // Calculate width that preserves the original plate aspect ratio
        // at the fixed target height — so a wide plate stays wide and a
        // narrow plate stays narrow.
        val aspectRatio = cropped.width.toFloat() / cropped.height.toFloat()
        val targetWidth = (PLATE_TARGET_HEIGHT * aspectRatio).toInt().coerceAtLeast(1)

        Log.d(TAG, "Plate crop: original=${cropped.width}x${cropped.height}, " +
                "aspectRatio=${"%.2f".format(aspectRatio)}, " +
                "resized=${targetWidth}x$PLATE_TARGET_HEIGHT")

        val resized = Bitmap.createScaledBitmap(
            cropped,
            targetWidth,
            PLATE_TARGET_HEIGHT,
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