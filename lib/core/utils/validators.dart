/// Các hàm kiểm tra tính hợp lệ dữ liệu (Form Validation)
class Validators {
  Validators._();

  /// Kiểm tra trường bắt buộc
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? 'Vui lòng nhập $fieldName' 
          : 'Vui lòng không để trống';
    }
    return null;
  }

  /// Kiểm tra định dạng Email hợp lệ
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  /// Kiểm tra mật khẩu (tối thiểu 6 ký tự theo Firebase Auth)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  /// Kiểm tra mật khẩu xác nhận
  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != originalPassword) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  /// Kiểm tra số điện thoại Việt Nam hợp lệ
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ (ví dụ: 0912345678)';
    }
    return null;
  }

  /// Kiểm tra giá dịch vụ
  static String? servicePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập giá dịch vụ';
    }
    final price = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (price == null || price < 0) {
      return 'Giá dịch vụ không hợp lệ';
    }
    return null;
  }

  /// Kiểm tra thời lượng dịch vụ (phải là bội số của 30 phút)
  static String? serviceDuration(int? durationMinutes) {
    if (durationMinutes == null || durationMinutes <= 0) {
      return 'Thời lượng không hợp lệ';
    }
    if (durationMinutes % 30 != 0) {
      return 'Thời lượng phải là bội số của 30 phút (30, 60, 90...)';
    }
    return null;
  }
}
