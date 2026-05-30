package com.kwon.mediapipe_landmarker

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.ImageFormat
import android.graphics.YuvImage
import android.graphics.Rect
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayOutputStream
import android.util.Log
import java.util.concurrent.Executors
import java.util.concurrent.CountDownLatch

/** KwonMediapipeLandmarkerPlugin */
class KwonMediapipeLandmarkerPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val TAG = "MediaPipeLandmarker"
        // 병렬 처리용 스레드 풀 (CPU 코어 수에 맞춤)
        private val executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())

        // Error codes (matching Dart LandmarkerError enum)
        private const val ERROR_NOT_INITIALIZED = "NOT_INITIALIZED"
        private const val ERROR_MODEL_LOAD_FAILED = "MODEL_LOAD_FAILED"
        private const val ERROR_INVALID_IMAGE = "INVALID_IMAGE"
        private const val ERROR_DETECTION_FAILED = "DETECTION_FAILED"
        private const val ERROR_INITIALIZATION_FAILED = "INITIALIZATION_FAILED"
        private const val ERROR_DISPOSE_FAILED = "DISPOSE_FAILED"
        private const val ERROR_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
        private const val ERROR_NO_CONTEXT = "NO_CONTEXT"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null

    private var faceLandmarkerHelper: FaceLandmarkerHelper? = null
    private var poseLandmarkerHelper: PoseLandmarkerHelper? = null

    private var isInitialized = false
    private var faceEnabled = false
    private var poseEnabled = false
    
    // 버퍼 재사용 (메모리 할당 최소화)
    private var argbBuffer: IntArray? = null
    private var lastWidth = 0
    private var lastHeight = 0

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.kwon.mediapipe_landmarker")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.kwon.mediapipe_landmarker/stream")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "detect" -> handleDetect(call, result)
            "startStream" -> handleStartStream(result)
            "stopStream" -> handleStopStream(result)
            "dispose" -> handleDispose(result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val ctx = context
        if (ctx == null) {
            result.error(ERROR_NO_CONTEXT, "Application context is not available", null)
            return
        }

        try {
            faceEnabled = call.argument<Boolean>("enableFace") ?: true
            poseEnabled = call.argument<Boolean>("enablePose") ?: false

            Log.d(TAG, "Initializing: face=$faceEnabled, pose=$poseEnabled")

            // Face Landmarker 초기화
            if (faceEnabled) {
                val numFaces = call.argument<Int>("faceNumFaces") ?: 1
                val minDetectionConfidence = call.argument<Double>("faceMinDetectionConfidence")?.toFloat() ?: 0.5f
                val minTrackingConfidence = call.argument<Double>("faceMinTrackingConfidence")?.toFloat() ?: 0.5f
                val outputBlendshapes = call.argument<Boolean>("faceOutputBlendshapes") ?: true
                val outputTransformationMatrix = call.argument<Boolean>("faceOutputTransformationMatrix") ?: false

                faceLandmarkerHelper = FaceLandmarkerHelper(
                    context = ctx,
                    numFaces = numFaces,
                    minDetectionConfidence = minDetectionConfidence,
                    minTrackingConfidence = minTrackingConfidence,
                    outputBlendshapes = outputBlendshapes,
                    outputTransformationMatrix = outputTransformationMatrix
                )
                Log.d(TAG, "FaceLandmarkerHelper created")
            }

            // Pose Landmarker 초기화
            if (poseEnabled) {
                val numPoses = call.argument<Int>("poseNumPoses") ?: 1
                val minDetectionConfidence = call.argument<Double>("poseMinDetectionConfidence")?.toFloat() ?: 0.5f
                val minTrackingConfidence = call.argument<Double>("poseMinTrackingConfidence")?.toFloat() ?: 0.5f

                poseLandmarkerHelper = PoseLandmarkerHelper(
                    context = ctx,
                    numPoses = numPoses,
                    minDetectionConfidence = minDetectionConfidence,
                    minTrackingConfidence = minTrackingConfidence
                )
                Log.d(TAG, "PoseLandmarkerHelper created")
            }

            isInitialized = true
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Initialization failed", e)
            result.error(ERROR_INITIALIZATION_FAILED, e.message, e.stackTraceToString())
        }
    }

    private fun handleDetect(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error(ERROR_NOT_INITIALIZED, "Landmarker is not initialized. Call initialize() first.", null)
            return
        }

        try {
            val startTime = System.currentTimeMillis()
            
            val bitmap: Bitmap? = when {
                // 이미지 바이트 (JPEG, PNG 등)
                call.argument<ByteArray>("imageBytes") != null -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")!!
                    BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                }
                // 카메라 YUV 프레임
                call.argument<List<ByteArray>>("planes") != null -> {
                    val planes = call.argument<List<ByteArray>>("planes")!!
                    val width = call.argument<Int>("imageWidth") ?: 0
                    val height = call.argument<Int>("imageHeight") ?: 0
                    val rotation = call.argument<Int>("imageRotation") ?: 0
                    val bytesPerRow = call.argument<List<Int>>("bytesPerRow")
                    
                    convertYuvToArgbParallel(planes, width, height, rotation, bytesPerRow)
                }
                else -> null
            }

            val conversionTime = System.currentTimeMillis() - startTime

            if (bitmap == null) {
                result.error(ERROR_INVALID_IMAGE, "Could not decode image. Check image format and data.", null)
                return
            }

            val detectStart = System.currentTimeMillis()
            val timestampMs = System.currentTimeMillis()
            val response = hashMapOf<String, Any?>(
                "timestampMs" to timestampMs
            )

            // Face 분석
            if (faceEnabled && faceLandmarkerHelper != null) {
                val faceResult = faceLandmarkerHelper!!.detect(bitmap, timestampMs)
                if (faceResult != null) {
                    response["face"] = faceResult
                }
            }

            // Pose 분석
            if (poseEnabled && poseLandmarkerHelper != null) {
                val poseResult = poseLandmarkerHelper!!.detect(bitmap, timestampMs)
                if (poseResult != null) {
                    response["pose"] = poseResult
                }
            }

            val detectTime = System.currentTimeMillis() - detectStart

            // Bitmap 메모리 해제
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }

            // 성능 로그 (30프레임마다)
            if (timestampMs % 1000 < 50) {
                Log.d(TAG, "Performance: conversion=${conversionTime}ms, detection=${detectTime}ms, total=${conversionTime + detectTime}ms")
            }

            result.success(response)
        } catch (e: Exception) {
            Log.e(TAG, "Detection failed", e)
            result.error(ERROR_DETECTION_FAILED, e.message, e.stackTraceToString())
        }
    }

    /**
     * 병렬 처리 YUV → ARGB 변환
     * 멀티코어 활용으로 2-3배 속도 향상
     */
    private fun convertYuvToArgbParallel(
        planes: List<ByteArray>,
        width: Int,
        height: Int,
        rotation: Int,
        bytesPerRowList: List<Int>?
    ): Bitmap? {
        if (planes.isEmpty() || width == 0 || height == 0) {
            return null
        }

        try {
            val yPlane = planes[0]
            val uPlane = if (planes.size > 1) planes[1] else ByteArray(0)
            val vPlane = if (planes.size > 2) planes[2] else ByteArray(0)
            
            val yStride = bytesPerRowList?.getOrNull(0) ?: width
            val uvStride = bytesPerRowList?.getOrNull(1) ?: width
            
            // 버퍼 재사용 (메모리 할당 최소화)
            val argb: IntArray
            if (lastWidth == width && lastHeight == height && argbBuffer != null) {
                argb = argbBuffer!!
            } else {
                argb = IntArray(width * height)
                argbBuffer = argb
                lastWidth = width
                lastHeight = height
            }
            
            // 병렬 처리: 행을 여러 청크로 나눔
            val numThreads = Runtime.getRuntime().availableProcessors()
            val rowsPerThread = height / numThreads
            val latch = CountDownLatch(numThreads)
            
            for (threadIdx in 0 until numThreads) {
                val startRow = threadIdx * rowsPerThread
                val endRow = if (threadIdx == numThreads - 1) height else (threadIdx + 1) * rowsPerThread
                
                executor.execute {
                    try {
                        for (j in startRow until endRow) {
                            val yRowOffset = j * yStride
                            val uvRow = j / 2
                            val argbRowOffset = j * width
                            
                            for (i in 0 until width) {
                                val yIndex = yRowOffset + i
                                val uvCol = i / 2
                                val uvIndex = uvRow * (uvStride / 2) + uvCol
                                
                                // 안전한 인덱스 접근
                                val y = if (yIndex < yPlane.size) (yPlane[yIndex].toInt() and 0xFF) else 0
                                val u = if (uvIndex < uPlane.size) (uPlane[uvIndex].toInt() and 0xFF) - 128 else 0
                                val v = if (uvIndex < vPlane.size) (vPlane[uvIndex].toInt() and 0xFF) - 128 else 0
                                
                                // YUV to RGB (정수 비트시프트 최적화)
                                // R = Y + 1.402 * V ≈ Y + (359 * V) >> 8
                                // G = Y - 0.344 * U - 0.714 * V ≈ Y - (88 * U + 183 * V) >> 8
                                // B = Y + 1.772 * U ≈ Y + (454 * U) >> 8
                                var r = y + ((359 * v) shr 8)
                                var g = y - ((88 * u + 183 * v) shr 8)
                                var b = y + ((454 * u) shr 8)
                                
                                // Clamp to 0-255
                                r = r.coerceIn(0, 255)
                                g = g.coerceIn(0, 255)
                                b = b.coerceIn(0, 255)
                                
                                argb[argbRowOffset + i] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
                            }
                        }
                    } finally {
                        latch.countDown()
                    }
                }
            }
            
            // 모든 스레드 완료 대기
            latch.await()
            
            var bitmap = Bitmap.createBitmap(argb, width, height, Bitmap.Config.ARGB_8888)
            
            // 회전 적용
            if (rotation != 0) {
                val matrix = Matrix()
                matrix.postRotate(rotation.toFloat())
                
                val rotatedBitmap = Bitmap.createBitmap(
                    bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
                )
                if (rotatedBitmap != bitmap) {
                    bitmap.recycle()
                }
                bitmap = rotatedBitmap
            }

            return bitmap
        } catch (e: Exception) {
            Log.e(TAG, "Parallel YUV conversion failed", e)
            return null
        }
    }

    private fun handleStartStream(result: Result) {
        result.success(null)
    }

    private fun handleStopStream(result: Result) {
        result.success(null)
    }

    private fun handleDispose(result: Result) {
        try {
            faceLandmarkerHelper?.close()
            poseLandmarkerHelper?.close()
            faceLandmarkerHelper = null
            poseLandmarkerHelper = null
            isInitialized = false
            faceEnabled = false
            poseEnabled = false
            argbBuffer = null
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Dispose failed", e)
            result.error(ERROR_DISPOSE_FAILED, e.message, e.stackTraceToString())
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        faceLandmarkerHelper?.close()
        poseLandmarkerHelper?.close()
        argbBuffer = null
        context = null
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
