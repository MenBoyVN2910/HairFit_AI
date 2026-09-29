/// Hằng số nghiệp vụ toàn hệ thống HairFit AI
class BusinessConstants {
  BusinessConstants._();

  /// Độ dài chuẩn của một khung giờ (slot): 30 phút
  static const int slotMinutes = 30;

  /// Thời gian tối thiểu khách phải đặt trước giờ hẹn: 30 phút
  static const int leadTimeMinutes = 30;

  /// Giới hạn thời gian tối đa được đặt trước: 30 ngày
  static const int maxBookingDaysAhead = 30;

  /// Số lượng lịch hẹn active (pending + confirmed) tối đa của 1 khách hàng: 2 lịch
  static const int maxActiveBookingsPerCustomer = 2;

  /// Múi giờ chuẩn của nghiệp vụ Việt Nam
  static const String timezone = 'Asia/Ho_Chi_Minh';

  /// Danh sách các thời lượng dịch vụ hợp lệ (bội số của 30 phút)
  static const List<int> validDurationMinutes = [30, 60, 90, 120, 150, 180];

  /// Góc quay khuôn mặt tối đa cho phép của ML Kit Face Detection
  static const double maxHeadEulerAngleY = 20.0; // Quay trái/phải tối đa 20 độ
  static const double maxHeadEulerAngleX = 15.0; // Ngửa/cúi đầu tối đa 15 độ

  /// Chiều rộng tối thiểu của bounding box khuôn mặt (px)
  static const double minFaceBoundingBoxWidth = 100.0;

  /// Tối đa số gợi ý kiểu tóc trả về từ AI Recommendation Engine
  static const int maxHairstyleSuggestions = 3;

  /// Toạ độ mặc định trung tâm TP. Đà Nẵng (dành cho fallback bản đồ khi từ chối GPS)
  static const double defaultLatitude = 16.0544;
  static const double defaultLongitude = 108.2022;
  static const String defaultCityName = 'Đà Nẵng';
}
