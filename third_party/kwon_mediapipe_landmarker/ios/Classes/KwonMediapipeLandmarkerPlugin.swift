import Flutter
import UIKit
import Accelerate
import CoreGraphics

public class KwonMediapipeLandmarkerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // Error codes (matching Dart LandmarkerError enum)
    private static let ERROR_NOT_INITIALIZED = "NOT_INITIALIZED"
    private static let ERROR_MODEL_LOAD_FAILED = "MODEL_LOAD_FAILED"
    private static let ERROR_INVALID_IMAGE = "INVALID_IMAGE"
    private static let ERROR_DETECTION_FAILED = "DETECTION_FAILED"
    private static let ERROR_INITIALIZATION_FAILED = "INITIALIZATION_FAILED"
    private static let ERROR_DISPOSE_FAILED = "DISPOSE_FAILED"
    private static let ERROR_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"

    private var eventSink: FlutterEventSink?

    private var faceLandmarkerHelper: FaceLandmarkerHelper?
    private var poseLandmarkerHelper: PoseLandmarkerHelper?

    private var isInitialized = false
    private var faceEnabled = false
    private var poseEnabled = false

    // 성능 측정용
    private var frameCount = 0
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.kwon.mediapipe_landmarker",
            binaryMessenger: registrar.messenger()
        )
        
        let eventChannel = FlutterEventChannel(
            name: "com.kwon.mediapipe_landmarker/stream",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = KwonMediapipeLandmarkerPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "detect":
            handleDetect(call, result: result)
        case "startStream":
            result(nil)
        case "stopStream":
            result(nil)
        case "dispose":
            handleDispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: Self.ERROR_INVALID_ARGUMENTS, message: "Invalid arguments", details: nil))
            return
        }
        
        do {
            faceEnabled = args["enableFace"] as? Bool ?? true
            poseEnabled = args["enablePose"] as? Bool ?? false
            
            // Face Landmarker 초기화
            if faceEnabled {
                let numFaces = args["faceNumFaces"] as? Int ?? 1
                let minDetectionConfidence = args["faceMinDetectionConfidence"] as? Double ?? 0.5
                let minTrackingConfidence = args["faceMinTrackingConfidence"] as? Double ?? 0.5
                let outputBlendshapes = args["faceOutputBlendshapes"] as? Bool ?? true
                let outputTransformationMatrix = args["faceOutputTransformationMatrix"] as? Bool ?? false
                
                faceLandmarkerHelper = try FaceLandmarkerHelper(
                    numFaces: numFaces,
                    minDetectionConfidence: Float(minDetectionConfidence),
                    minTrackingConfidence: Float(minTrackingConfidence),
                    outputBlendshapes: outputBlendshapes,
                    outputTransformationMatrix: outputTransformationMatrix
                )
            }
            
            // Pose Landmarker 초기화
            if poseEnabled {
                let numPoses = args["poseNumPoses"] as? Int ?? 1
                let minDetectionConfidence = args["poseMinDetectionConfidence"] as? Double ?? 0.5
                let minTrackingConfidence = args["poseMinTrackingConfidence"] as? Double ?? 0.5
                
                poseLandmarkerHelper = try PoseLandmarkerHelper(
                    numPoses: numPoses,
                    minDetectionConfidence: Float(minDetectionConfidence),
                    minTrackingConfidence: Float(minTrackingConfidence)
                )
            }
            
            isInitialized = true
            result(nil)
        } catch {
            result(FlutterError(code: Self.ERROR_INITIALIZATION_FAILED, message: error.localizedDescription, details: String(describing: error)))
        }
    }
    
    private func handleDetect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: Self.ERROR_NOT_INITIALIZED, message: "Landmarker is not initialized. Call initialize() first.", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: Self.ERROR_INVALID_ARGUMENTS, message: "Invalid arguments", details: nil))
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var image: UIImage?
        
        // 1. 이미지 바이트에서 UIImage 생성 (JPEG, PNG 등)
        if let imageBytes = args["imageBytes"] as? FlutterStandardTypedData {
            image = UIImage(data: imageBytes.data)
        }
        // 2. 카메라 YUV planes에서 UIImage 생성
        else if let planesData = args["planes"] as? [FlutterStandardTypedData] {
            let width = args["imageWidth"] as? Int ?? 0
            let height = args["imageHeight"] as? Int ?? 0
            let rotation = args["imageRotation"] as? Int ?? 0
            let bytesPerRow = args["bytesPerRow"] as? [Int]
            
            image = convertNV12ToUIImageFast(
                planes: planesData,
                width: width,
                height: height,
                rotation: rotation,
                bytesPerRow: bytesPerRow
            )
        }
        
        let conversionTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        guard let inputImage = image else {
            result(FlutterError(code: Self.ERROR_INVALID_IMAGE, message: "Could not decode image. Check image format and data.", details: nil))
            return
        }
        
        let detectStart = CFAbsoluteTimeGetCurrent()
        let timestampMs = Int64(Date().timeIntervalSince1970 * 1000)
        var response: [String: Any?] = [
            "timestampMs": timestampMs
        ]
        
        // Face 분석
        if faceEnabled, let faceHelper = faceLandmarkerHelper {
            if let faceResult = faceHelper.detect(image: inputImage) {
                response["face"] = faceResult
            }
        }
        
        // Pose 분석
        if poseEnabled, let poseHelper = poseLandmarkerHelper {
            if let poseResult = poseHelper.detect(image: inputImage) {
                response["pose"] = poseResult
            }
        }
        
        let detectTime = (CFAbsoluteTimeGetCurrent() - detectStart) * 1000
        
        // 성능 로그 (30프레임마다)
        frameCount += 1
        if frameCount % 30 == 0 {
            print("[MediaPipe] Performance: conversion=\(String(format: "%.1f", conversionTime))ms, detection=\(String(format: "%.1f", detectTime))ms, total=\(String(format: "%.1f", conversionTime + detectTime))ms")
        }
        
        result(response)
    }
    
    /// 최적화된 NV12 → UIImage 변환 (vImage 하드웨어 가속)
    private func convertNV12ToUIImageFast(
        planes: [FlutterStandardTypedData],
        width: Int,
        height: Int,
        rotation: Int,
        bytesPerRow: [Int]?
    ) -> UIImage? {
        guard planes.count >= 2, width > 0, height > 0 else {
            return nil
        }
        
        let yData = planes[0].data
        let uvData = planes[1].data
        
        let yBytesPerRow = bytesPerRow?[0] ?? width
        let uvBytesPerRow = bytesPerRow?[1] ?? width
        
        // vImage 버퍼 설정
        var yBuffer = vImage_Buffer()
        var uvBuffer = vImage_Buffer()
        var destBuffer = vImage_Buffer()
        
        // Y 평면 버퍼
        yData.withUnsafeBytes { yPtr in
            yBuffer = vImage_Buffer(
                data: UnsafeMutableRawPointer(mutating: yPtr.baseAddress!),
                height: vImagePixelCount(height),
                width: vImagePixelCount(width),
                rowBytes: yBytesPerRow
            )
        }
        
        // UV 평면 버퍼
        uvData.withUnsafeBytes { uvPtr in
            uvBuffer = vImage_Buffer(
                data: UnsafeMutableRawPointer(mutating: uvPtr.baseAddress!),
                height: vImagePixelCount(height / 2),
                width: vImagePixelCount(width / 2),
                rowBytes: uvBytesPerRow
            )
        }
        
        // 출력 ARGB 버퍼 할당
        let destRowBytes = width * 4
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: height * destRowBytes)
        defer { destData.deallocate() }
        
        destBuffer = vImage_Buffer(
            data: destData,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: destRowBytes
        )
        
        // NV12 → ARGB 변환 (vImage 사용 불가 시 최적화된 수동 변환)
        convertNV12ToARGBManualOptimized(
            yData: yData,
            uvData: uvData,
            destData: destData,
            width: width,
            height: height,
            yBytesPerRow: yBytesPerRow,
            uvBytesPerRow: uvBytesPerRow
        )
        
        // CGImage 생성
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: destData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: destRowBytes,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        guard let cgImage = context.makeImage() else {
            return nil
        }
        
        var uiImage = UIImage(cgImage: cgImage)
        
        // 회전 적용
        if rotation != 0 {
            uiImage = rotateImageFast(uiImage, degrees: rotation) ?? uiImage
        }
        
        return uiImage
    }
    
    /// 최적화된 수동 NV12 → ARGB 변환 (SIMD 스타일 최적화)
    private func convertNV12ToARGBManualOptimized(
        yData: Data,
        uvData: Data,
        destData: UnsafeMutablePointer<UInt8>,
        width: Int,
        height: Int,
        yBytesPerRow: Int,
        uvBytesPerRow: Int
    ) {
        yData.withUnsafeBytes { yPtr in
            uvData.withUnsafeBytes { uvPtr in
                let yBase = yPtr.bindMemory(to: UInt8.self).baseAddress!
                let uvBase = uvPtr.bindMemory(to: UInt8.self).baseAddress!
                
                // 병렬 처리를 위한 DispatchQueue 사용
                DispatchQueue.concurrentPerform(iterations: height) { j in
                    let yRowStart = j * yBytesPerRow
                    let uvRowStart = (j / 2) * uvBytesPerRow
                    let destRowStart = j * width * 4
                    
                    for i in 0..<width {
                        let yIndex = yRowStart + i
                        let uvIndex = uvRowStart + (i / 2) * 2
                        
                        let y = Int(yBase[yIndex])
                        let u = Int(uvBase[uvIndex]) - 128
                        let v = Int(uvBase[uvIndex + 1]) - 128
                        
                        // YUV to RGB (정수 연산으로 최적화)
                        // R = Y + 1.402 * V ≈ Y + (359 * V) >> 8
                        // G = Y - 0.344 * U - 0.714 * V ≈ Y - (88 * U + 183 * V) >> 8
                        // B = Y + 1.772 * U ≈ Y + (454 * U) >> 8
                        var r = y + ((359 * v) >> 8)
                        var g = y - ((88 * u + 183 * v) >> 8)
                        var b = y + ((454 * u) >> 8)
                        
                        // Clamp
                        r = max(0, min(255, r))
                        g = max(0, min(255, g))
                        b = max(0, min(255, b))
                        
                        let destIndex = destRowStart + i * 4
                        destData[destIndex] = UInt8(r)
                        destData[destIndex + 1] = UInt8(g)
                        destData[destIndex + 2] = UInt8(b)
                        destData[destIndex + 3] = 255
                    }
                }
            }
        }
    }
    
    /// 최적화된 이미지 회전
    private func rotateImageFast(_ image: UIImage, degrees: Int) -> UIImage? {
        guard degrees != 0 else { return image }
        
        guard let cgImage = image.cgImage else { return nil }
        
        let radians = CGFloat(degrees) * .pi / 180
        
        var newSize: CGSize
        if degrees == 90 || degrees == 270 || degrees == -90 || degrees == -270 {
            newSize = CGSize(width: image.size.height, height: image.size.width)
        } else {
            newSize = image.size
        }
        
        // Core Graphics로 직접 회전 (더 빠름)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: Int(newSize.width),
            height: Int(newSize.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(newSize.width) * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        context.draw(cgImage, in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))
        
        guard let rotatedCGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: rotatedCGImage)
    }
    
    private func handleDispose(result: @escaping FlutterResult) {
        faceLandmarkerHelper?.close()
        poseLandmarkerHelper?.close()
        faceLandmarkerHelper = nil
        poseLandmarkerHelper = nil
        isInitialized = false
        faceEnabled = false
        poseEnabled = false
        result(nil)
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
