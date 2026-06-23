package com.kwon.mediapipe_landmarker

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult

/**
 * Face Landmarker Helper
 * MediaPipe Face Landmarker 래퍼 클래스
 *
 * 478개 얼굴 랜드마크 + 52개 블렌드쉐입 지원
 */
class FaceLandmarkerHelper(
    private val context: Context,
    private val numFaces: Int = 1,
    private val minDetectionConfidence: Float = 0.5f,
    private val minTrackingConfidence: Float = 0.5f,
    private val outputBlendshapes: Boolean = true,
    private val outputTransformationMatrix: Boolean = false
) {
    private var faceLandmarker: FaceLandmarker? = null
    private var lastTimestampMs: Long = 0

    companion object {
        private const val TAG = "FaceLandmarkerHelper"
        private const val MODEL_FACE_LANDMARKER = "models/face_landmarker.task"
    }

    init {
        setupFaceLandmarker()
    }

    private fun setupFaceLandmarker() {
        // GPU 우선 시도, 실패 시 CPU fallback
        try {
            setupWithDelegate(Delegate.GPU)
            Log.d(TAG, "FaceLandmarker initialized with GPU delegate (VIDEO mode)")
        } catch (e: Exception) {
            Log.w(TAG, "GPU delegate failed, falling back to CPU: ${e.message}")
            try {
                setupWithDelegate(Delegate.CPU)
                Log.d(TAG, "FaceLandmarker initialized with CPU delegate (VIDEO mode)")
            } catch (e2: Exception) {
                throw RuntimeException("Failed to initialize Face Landmarker: ${e2.message}", e2)
            }
        }
    }

    private fun setupWithDelegate(delegate: Delegate) {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(MODEL_FACE_LANDMARKER)
            .setDelegate(delegate)
            .build()

        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.VIDEO)  // VIDEO 모드 - tracking 활용!
            .setNumFaces(numFaces)
            .setMinFaceDetectionConfidence(minDetectionConfidence)
            .setMinTrackingConfidence(minTrackingConfidence)
            .setMinFacePresenceConfidence(minDetectionConfidence)
            .setOutputFaceBlendshapes(outputBlendshapes)
            .setOutputFacialTransformationMatrixes(outputTransformationMatrix)
            .build()

        faceLandmarker = FaceLandmarker.createFromOptions(context, options)
    }

    /**
     * 이미지에서 얼굴 감지 (VIDEO 모드)
     * @param bitmap 입력 이미지
     * @param timestampMs 타임스탬프 (밀리초) - 반드시 증가해야 함!
     * @return 감지 결과 Map (Flutter로 전송용)
     */
    fun detect(bitmap: Bitmap, timestampMs: Long): Map<String, Any>? {
        val landmarker = faceLandmarker ?: return null

        // VIDEO 모드는 timestamp가 항상 증가해야 함
        val safeTimestamp = if (timestampMs <= lastTimestampMs) {
            lastTimestampMs + 1
        } else {
            timestampMs
        }
        lastTimestampMs = safeTimestamp

        try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            // VIDEO 모드: detectForVideo 사용
            val result = landmarker.detectForVideo(mpImage, safeTimestamp)

            return convertResultToMap(result)
        } catch (e: Exception) {
            Log.e(TAG, "Detection failed", e)
            return null
        }
    }

    /**
     * FaceLandmarkerResult를 Flutter 전송용 Map으로 변환
     */
    private fun convertResultToMap(result: FaceLandmarkerResult): Map<String, Any>? {
        if (result.faceLandmarks().isEmpty()) {
            return null
        }

        // 첫 번째 얼굴만 처리 (numFaces=1 기준)
        val faceLandmarks = result.faceLandmarks()[0]

        // 랜드마크 변환 (478개)
        val landmarks = mutableListOf<Map<String, Any>>()
        faceLandmarks.forEachIndexed { index, landmark ->
            landmarks.add(
                mapOf(
                    "index" to index,
                    "x" to landmark.x(),
                    "y" to landmark.y(),
                    "z" to landmark.z()
                )
            )
        }

        // 블렌드쉐입 변환 (52개)
        val blendshapes = mutableMapOf<String, Double>()
        if (outputBlendshapes && result.faceBlendshapes().isPresent && result.faceBlendshapes().get().isNotEmpty()) {
            val faceBlendshapes = result.faceBlendshapes().get()[0]
            faceBlendshapes.forEach { category ->
                blendshapes[category.categoryName()] = category.score().toDouble()
            }
        }

        val resultMap = mutableMapOf<String, Any>(
            "landmarks" to landmarks,
            "blendshapes" to blendshapes
        )

        return resultMap
    }

    /**
     * 리소스 해제
     */
    fun close() {
        faceLandmarker?.close()
        faceLandmarker = null
    }
}
