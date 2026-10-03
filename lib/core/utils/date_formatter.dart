// ============================================================================
// File: lib/core/utils/date_formatter.dart
// Mục đích: Cung cấp các hàm tiện ích (Utility/Helper) dùng chung.
// Kết cấu:
//  - Các hàm logic nhỏ, tính toán, format dữ liệu độc lập với UI.
// ============================================================================

import 'package:intl/intl.dart';

/// Tiện ích định dạng ngày giờ và tiền tệ chuẩn Việt Nam
class DateFormatter {
  DateFormatter._();

  /// Định dạng tiền tệ VNĐ (ví dụ: 70.000 đ)
  static String formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount).trim();
  }

  /// Định dạng khoảng giá: 70.000 đ - 120.000 đ
  static String formatPriceRange(int minPrice, int maxPrice) {
    if (minPrice == maxPrice) {
      return formatCurrency(minPrice);
    }
    return '${formatCurrency(minPrice)} - ${formatCurrency(maxPrice)}';
  }

  /// Định dạng ngày dạng: "Thứ 2, 10/10/2026"
  static String formatFullDate(DateTime dateTime) {
    final weekdayNames = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    final dayOfWeek = weekdayNames[dateTime.weekday];
    final formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
    return '$dayOfWeek, $formattedDate';
  }

  /// Định dạng ngày dạng chuẩn ISO: "yyyy-MM-dd"
  static String toIsoDateString(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// Parse từ chuỗi "yyyy-MM-dd" sang DateTime
  static DateTime? parseIsoDate(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Định dạng ngày hiển thị: "10/10/2026"
  static String formatShortDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// Parse ngày dạng "10/10/2026" sang DateTime
  static DateTime? parseShortDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Định dạng giờ dạng: "09:00"
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Định dạng ngày giờ đầy đủ: "09:00 - 10/10/2026"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
  }

  /// Kết hợp ngày (yyyy-MM-dd) và giờ (HH:mm) thành DateTime
  static DateTime combineDateAndTime(String dateStr, String timeStr) {
    final dateParts = dateStr.split('-');
    final timeParts = timeStr.split(':');

    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return DateTime(year, month, day, hour, minute);
  }
}
