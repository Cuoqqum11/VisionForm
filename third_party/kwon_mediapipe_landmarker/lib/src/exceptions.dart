/// Error codes for Landmarker operations
enum LandmarkerError {
  /// Landmarker is not initialized. Call initialize() first.
  notInitialized('NOT_INITIALIZED'),

  /// Model loading failed. Check if model files exist.
  modelLoadFailed('MODEL_LOAD_FAILED'),

  /// Invalid or unsupported image format.
  invalidImage('INVALID_IMAGE'),

  /// Detection process failed.
  detectionFailed('DETECTION_FAILED'),

  /// Camera permission was denied by user.
  cameraPermissionDenied('CAMERA_PERMISSION_DENIED'),

  /// Platform is not supported (only Android and iOS are supported).
  platformNotSupported('PLATFORM_NOT_SUPPORTED'),

  /// Initialization failed.
  initializationFailed('INITIALIZATION_FAILED'),

  /// Dispose operation failed.
  disposeFailed('DISPOSE_FAILED'),

  /// Invalid arguments provided.
  invalidArguments('INVALID_ARGUMENTS'),

  /// Context is not available (Android only).
  noContext('NO_CONTEXT'),

  /// Unknown error occurred.
  unknown('UNKNOWN');

  const LandmarkerError(this.code);

  /// Error code string
  final String code;

  /// Get LandmarkerError from error code string
  static LandmarkerError fromCode(String? code) {
    if (code == null) return LandmarkerError.unknown;

    for (final error in LandmarkerError.values) {
      if (error.code == code) {
        return error;
      }
    }
    return LandmarkerError.unknown;
  }
}

/// Exception thrown by Landmarker operations
class LandmarkerException implements Exception {
  /// Creates a LandmarkerException with the given error type, message, and optional original error.
  const LandmarkerException({
    required this.error,
    required this.message,
    this.originalError,
  });

  /// Creates a LandmarkerException from an error code string.
  factory LandmarkerException.fromCode(
    String? code,
    String message, {
    dynamic originalError,
  }) {
    return LandmarkerException(
      error: LandmarkerError.fromCode(code),
      message: message,
      originalError: originalError,
    );
  }

  /// The type of error that occurred.
  final LandmarkerError error;

  /// A human-readable description of the error.
  final String message;

  /// The original error that caused this exception, if any.
  final dynamic originalError;

  /// Error code string
  String get code => error.code;

  @override
  String toString() {
    final buffer = StringBuffer('LandmarkerException(${error.code}): $message');
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandmarkerException &&
        other.error == error &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(error, message);
}
