package com.kwon.mediapipe_landmarker

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

/**
 * Pose Landmarker Helper
 * MediaPipe Pose Landmarker 래퍼 클래스
 * 
 * 33개 신체 랜드마크 감지:
 * - 얼굴 (0-10): nose, eyes, ears, mouth
 * - 상체 (11-22): shoulders, elbows, wrists, fingers
 * - 하체 (23-32): hips, knees, ankles, heels, feet
 */
class PoseLandmarkerHelper(
    private val context: Context,
    private val numPoses: Int = 1,
    private val minDetectionConfidence: Float = 0.5f,
    private val minTrackingConfidence: Float = 0.5f,
    private val minPosePresenceConfidence: Float = 0.5f,
    private val runningMode: RunningMode = RunningMode.VIDEO,
    private val useGpu: Boolean = false
) {
    companion object {
        private const val TAG = "PoseLandmarkerHelper"
        private const val MODEL_NAME = "models/pose_landmarker_lite.task"
        // 모델 옵션: pose_landmarker_lite.task, pose_landmarker_full.task, pose_landmarker_heavy.task
    }

    private var poseLandmarker: PoseLandmarker? = null

    init {
        setupPoseLandmarker()
    }

    private fun setupPoseLandmarker() {
        try {
            val baseOptionsBuilder = BaseOptions.builder()
                .setModelAssetPath(MODEL_NAME)

            // GPU 사용 여부 (주의: 일부 기기에서 불안정)
            if (useGpu) {
                baseOptionsBuilder.setDelegate(Delegate.GPU)
            } else {
                baseOptionsBuilder.setDelegate(Delegate.CPU)
            }

            val baseOptions = baseOptionsBuilder.build()

            val optionsBuilder = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setNumPoses(numPoses)
                .setMinPoseDetectionConfidence(minDetectionConfidence)
                .setMinTrackingConfidence(minTrackingConfidence)
                .setMinPosePresenceConfidence(minPosePresenceConfidence)
                .setRunningMode(runningMode)
                .setOutputSegmentationMasks(false)  // 세그멘테이션 마스크 불필요

            val options = optionsBuilder.build()
            poseLandmarker = PoseLandmarker.createFromOptions(context, options)
            
            Log.d(TAG, "PoseLandmarker initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize PoseLandmarker", e)
            throw e
        }
    }

    /**
     * Bitmap에서 포즈 감지 (VIDEO 모드)
     * @return Map 형태의 결과 (Flutter로 전달용)
     */
    fun detect(bitmap: Bitmap, timestampMs: Long): Map<String, Any?>? {
        val landmarker = poseLandmarker ?: return null

        return try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            
            val result: PoseLandmarkerResult = when (runningMode) {
                RunningMode.VIDEO -> landmarker.detectForVideo(mpImage, timestampMs)
                RunningMode.IMAGE -> landmarker.detect(mpImage)
                else -> return null
            }

            convertResultToMap(result)
        } catch (e: Exception) {
            Log.e(TAG, "Detection failed", e)
            null
        }
    }

    /**
     * PoseLandmarkerResult를 Flutter 전달용 Map으로 변환
     */
    private fun convertResultToMap(result: PoseLandmarkerResult): Map<String, Any?>? {
        if (result.landmarks().isEmpty()) {
            return null
        }

        // 첫 번째 포즈만 사용 (numPoses=1인 경우)
        val landmarks = result.landmarks()[0]
        val worldLandmarks = if (result.worldLandmarks().isNotEmpty()) {
            result.worldLandmarks()[0]
        } else null

        Log.d(TAG, "Pose detected! landmarks=${landmarks.size}")

        // Normalized landmarks (0.0~1.0)
        val landmarksList = landmarks.mapIndexed { index, landmark ->
            hashMapOf(
                "index" to index,
                "x" to landmark.x(),
                "y" to landmark.y(),
                "z" to landmark.z(),
                "visibility" to (landmark.visibility().orElse(0f)),
                "presence" to (landmark.presence().orElse(0f))
            )
        }

        // World landmarks (미터 단위)
        val worldLandmarksList = worldLandmarks?.mapIndexed { index, landmark ->
            hashMapOf(
                "index" to index,
                "x" to landmark.x(),
                "y" to landmark.y(),
                "z" to landmark.z(),
                "visibility" to (landmark.visibility().orElse(0f)),
                "presence" to (landmark.presence().orElse(0f))
            )
        }

        return hashMapOf(
            "landmarks" to landmarksList,
            "worldLandmarks" to worldLandmarksList
        )
    }

    /**
     * 리소스 해제
     */
    fun close() {
        try {
            poseLandmarker?.close()
            poseLandmarker = null
            Log.d(TAG, "PoseLandmarker closed")
        } catch (e: Exception) {
            Log.e(TAG, "Error closing PoseLandmarker", e)
        }
    }
}
