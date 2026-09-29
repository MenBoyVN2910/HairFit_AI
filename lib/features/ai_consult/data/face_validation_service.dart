import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../core/constants/business_constants.dart';

/// Kết quả xác thực khuôn mặt từ ML Kit
class FaceValidationResult {
  final bool isValid;
  final Face? face;
  final String? errorMessage;
  final String? errorHint;
  final double? eulerX;
  final double? eulerY;
  final double? boundingBoxWidth;
  final int faceCount;

  const FaceValidationResult._({
    required this.isValid,
    this.face,
    this.errorMessage,
    this.errorHint,
    this.eulerX,
    this.eulerY,
    this.boundingBoxWidth,
    this.faceCount = 0,
  });

  factory FaceValidationResult.valid({
    required Face face,
    int faceCount = 1,
  }) {
    return FaceValidationResult._(
      isValid: true,
      face: face,
      eulerX: face.headEulerAngleX,
      eulerY: face.headEulerAngleY,
      boundingBoxWidth: face.boundingBox.width,
      faceCount: faceCount,
    );
  }

  factory FaceValidationResult.invalid({
    required String error,
    required String hint,
    double? eulerX,
    double? eulerY,
    double? boundingBoxWidth,
    int faceCount = 0,
  }) {
    return FaceValidationResult._(
      isValid: false,
      errorMessage: error,
      errorHint: hint,
      eulerX: eulerX,
      eulerY: eulerY,
      boundingBoxWidth: boundingBoxWidth,
      faceCount: faceCount,
    );
  }
}

/// Dịch vụ kiểm tra và xác thực khuôn mặt on-device bằng Google ML Kit
class FaceValidationService {
  final FaceDetector _faceDetector;

  FaceValidationService({FaceDetector? customDetector})
      : _faceDetector = customDetector ??
            FaceDetector(
              options: FaceDetectorOptions(
                enableLandmarks: true,
                enableContours: true,
                enableClassification: true,
                performanceMode: FaceDetectorMode.accurate,
                minFaceSize: 0.15,
              ),
            );

  /// Kiểm tra ảnh khuôn mặt theo các tiêu chí:
  /// 1. Có khuôn mặt nào không (faces.isNotEmpty)
  /// 2. Chọn khuôn mặt to nhất nếu trong khung hình có nhiều người
  /// 3. Góc quay ngang Euler Y không vượt quá 20 độ (nhìn thẳng)
  /// 4. Góc quay dọc Euler X không vượt quá 15 độ (đầu không ngửa/cúi)
  /// 5. Kích thước khuôn mặt đủ lớn (chiều rộng bounding box >= 100px)
  Future<FaceValidationResult> validateFace(InputImage image) async {
    try {
      final faces = await _faceDetector.processImage(image);

      // Trường hợp 1: Không tìm thấy khuôn mặt nào
      if (faces.isEmpty) {
        return FaceValidationResult.invalid(
          error: 'Không phát hiện khuôn mặt trong ảnh',
          hint: 'Vui lòng căn chỉnh sao cho khuôn mặt nằm trọn trong khung hình',
          faceCount: 0,
        );
      }

      // Trường hợp 2: Lấy khuôn mặt lớn nhất (nổi bật nhất)
      final primaryFace = faces.reduce((a, b) =>
          a.boundingBox.width * a.boundingBox.height >
                  b.boundingBox.width * b.boundingBox.height
              ? a
              : b);

      final eulerY = primaryFace.headEulerAngleY ?? 0.0;
      final eulerX = primaryFace.headEulerAngleX ?? 0.0;
      final boxWidth = primaryFace.boundingBox.width;

      // Trường hợp 3: Quay đầu sang trái/phải quá nhiều
      if (eulerY.abs() > BusinessConstants.maxHeadEulerAngleY) {
        return FaceValidationResult.invalid(
          error: 'Vui lòng nhìn thẳng vào camera',
          hint: 'Gương mặt hiện đang bị nghiêng sang một bên (${eulerY.toStringAsFixed(1)}°)',
          eulerX: eulerX,
          eulerY: eulerY,
          boundingBoxWidth: boxWidth,
          faceCount: faces.length,
        );
      }

      // Trường hợp 4: Ngửa cổ hoặc cúi đầu quá nhiều
      if (eulerX.abs() > BusinessConstants.maxHeadEulerAngleX) {
        return FaceValidationResult.invalid(
          error: 'Vui lòng giữ đầu thẳng đứng',
          hint: 'Không ngửa đầu lên trên hoặc cúi đầu xuống dưới (${eulerX.toStringAsFixed(1)}°)',
          eulerX: eulerX,
          eulerY: eulerY,
          boundingBoxWidth: boxWidth,
          faceCount: faces.length,
        );
      }

      // Trường hợp 5: Khuôn mặt quá nhỏ (ở quá xa camera)
      if (boxWidth < BusinessConstants.minFaceBoundingBoxWidth) {
        return FaceValidationResult.invalid(
          error: 'Đưa camera lại gần khuôn mặt hơn',
          hint: 'Khuôn mặt cần chiếm ít nhất 25% diện tích khung hình',
          eulerX: eulerX,
          eulerY: eulerY,
          boundingBoxWidth: boxWidth,
          faceCount: faces.length,
        );
      }

      // Đạt chuẩn
      return FaceValidationResult.valid(
        face: primaryFace,
        faceCount: faces.length,
      );
    } catch (e) {
      debugPrint('Lỗi khi xử lý ML Kit Face Detection: $e');
      return FaceValidationResult.invalid(
        error: 'Lỗi trong quá trình quét khuôn mặt',
        hint: e.toString(),
      );
    }
  }

  /// Giải phóng bộ nhớ của ML Kit khi không sử dụng
  Future<void> dispose() async {
    try {
      await _faceDetector.close();
    } catch (_) {}
  }
}
