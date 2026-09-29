# HAIRFIT AI — EXECUTION PLAN FOR AI AGENTS
## Hướng Dẫn Toàn Diện Để AI Agent Triển Khai Dự Án

> **Mục đích file này:** Cung cấp đầy đủ ngữ cảnh để bất kỳ AI Agent nào đọc file này đều có thể hiểu dự án và hỗ trợ triển khai code ngay lập tức.  
> **Ngày tạo:** 2026-09-27  
> **Tham chiếu:** Đọc kèm `HairFit_AI_Specification.md` và `HairFit_AI_Timeline.md`

---

## 1. TỔNG QUAN DỰ ÁN

### 1.1 Mô Tả Ngắn

**HairFit AI** là ứng dụng Android (Flutter/Dart) với 3 tính năng cốt lõi:
1. **AI Tư Vấn Kiểu Tóc (100% On-Device)** — Chụp ảnh → ML Kit trích xuất Contours → Phân tích hình học nhân trắc on-device (< 50ms) → Khớp ma trận quy tắc chuyên gia gợi ý kiểu tóc tức thì (< 5ms)
2. **Bản Đồ Tìm Thợ** — OpenStreetMap hiển thị thợ approved gần nhất, filter theo kiểu tóc AI gợi ý
3. **Đặt Lịch Chống Trùng** — Chọn dịch vụ + slot → Firestore Transaction → Tạo appointment + bookedSlots

### 1.2 Thông Tin Dự Án

| Key | Value |
|---|---|
| **Framework** | Flutter 3.x (Dart) |
| **Platform** | Android only (minSdk API 26) |
| **Backend** | Firebase (Auth + Firestore) — KHÔNG có server riêng |
| **AI** | Google ML Kit Face Detection (on-device contours) + Geometric FaceShapeAnalyzer + Rule-based Engine (100% On-Device) |
| **Map** | flutter_map + OpenStreetMap (miễn phí, KHÔNG dùng Google Maps) |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Auth** | Firebase Auth — Email/Password (KHÔNG có Google Sign-In, KHÔNG có OTP) |
| **Team** | 1 developer |
| **Timeline** | 7 tuần |
| **Language UI** | Tiếng Việt |
| **Timezone** | Asia/Ho_Chi_Minh |

### 1.3 Phạm Vi MVP (P0 Only)

```
✅ TRONG MVP:
- Auth Email/Password + quên mật khẩu
- 3 roles: Customer, Barber, Admin
- Hồ sơ thợ (tạo/sửa, duyệt bởi Admin)
- AI tư vấn (100% On-Device ML Kit Contours + Geometric Analyzer + fallback thủ công)
- Bản đồ tìm thợ (OpenStreetMap + khoảng cách)
- Đặt lịch (Transaction chống trùng slot)
- Quản lý lịch (khách hủy, thợ confirm/reject/complete)
- Trang chủ + Profile

❌ NGOÀI MVP:
- Thanh toán, Push Notification, Portfolio, Google Sign-In
- Dark Mode, Chat media, Geo query nâng cao
- Video call, Mạng xã hội, KYC
```

---

## 2. TECH STACK & PACKAGES

### 2.1 pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Core Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0

  # AI - Face Detection (on-device)
  google_mlkit_face_detection: ^0.11.0

  # Map & Location
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
  geolocator: ^12.0.0

  # Image
  image_picker: ^1.0.0

  # State Management
  flutter_riverpod: ^2.5.0

  # Navigation
  go_router: ^14.0.0

  # Utils
  flutter_dotenv: ^5.1.0
  intl: ^0.19.0
  connectivity_plus: ^6.0.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  shared_preferences: ^2.2.0
```

### 2.2 Environment Variables (.env)

```env
# Dự án chạy 100% On-Device AI, không cần cấu hình API key bên thứ 3
```

---

## 3. KIẾN TRÚC & CẤU TRÚC THƯ MỤC

### 3.1 Architecture Pattern

```
Presentation Layer    →  Screens, Widgets (UI)
     ↕
Application Layer     →  Riverpod Providers (State Management)
     ↕
Domain Layer          →  Models, Enums, AI Analyzers
     ↕
Data Layer            →  Services, Repositories (Firebase, ML Kit)
```

### 3.2 Cấu Trúc Thư Mục (Feature-First)

```
lib/
├── main.dart                           # Entry point
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart             # Color palette
│   │   ├── app_text_styles.dart        # Typography (Be Vietnam Pro)
│   │   ├── app_dimensions.dart         # Spacing, radius tokens
│   │   └── business_constants.dart     # SLOT_MINUTES=30, LEAD_TIME=30, etc.
│   ├── theme/
│   │   └── app_theme.dart              # ThemeData
│   ├── utils/
│   │   ├── validators.dart             # Email, password, phone validation
│   │   ├── date_formatter.dart         # Format ngày/giờ tiếng Việt
│   │   └── distance_helper.dart        # Haversine formula tính khoảng cách
│   ├── services/
│   │   ├── firebase_service.dart       # Firebase.initializeApp
│   │   ├── auth_service.dart           # register, login, logout, resetPassword
│   │   ├── location_service.dart       # Xin quyền, lấy GPS
│   │   └── connectivity_service.dart   # Kiểm tra internet
│   └── widgets/
│       ├── app_button.dart             # Primary/Secondary/Outline buttons
│       ├── app_text_field.dart         # Styled text field + validation
│       ├── loading_shimmer.dart        # Skeleton loading
│       ├── empty_state.dart            # Illustration + text + CTA
│       ├── error_retry.dart            # Error message + "Thử lại" button
│       ├── status_badge.dart           # Colored badge (pending/confirmed/...)
│       └── rating_stars.dart           # Star rating display
│
├── models/
│   ├── user_model.dart                 # uid, email, displayName, role, isBlocked
│   ├── barber_profile_model.dart       # Full barber profile with services, hours
│   ├── hairstyle_model.dart            # id, name, description, faceShapes, tags
│   ├── appointment_model.dart          # Full appointment with timestamps, slotIds
│   ├── booked_slot_model.dart          # barberId, date, time, appointmentId
│   └── service_model.dart              # id, name, price, durationMinutes
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── forgot_password_screen.dart
│   │
│   ├── home/
│   │   ├── data/
│   │   │   └── home_repository.dart
│   │   └── presentation/
│   │       ├── customer_home_screen.dart
│   │       └── widgets/
│   │           ├── ai_banner.dart
│   │           ├── popular_hairstyles.dart
│   │           └── featured_barbers.dart
│   │
│   ├── ai_consult/
│   │   ├── data/
│   │   │   ├── face_validation_service.dart     # ML Kit Face Detection (Quality Gate & Contours)
│   │   │   └── hairstyle_repository.dart         # CRUD catalog từ Firestore
│   │   ├── domain/
│   │   │   ├── face_shape.dart                   # enum FaceShape
│   │   │   ├── face_shape_analyzer.dart          # Phân tích hình học nhân trắc 132 điểm Contours (On-device)
│   │   │   ├── hairstyle_recommendation_engine.dart # Ma trận quy tắc chuyên gia gợi ý kiểu tóc (On-device)
│   │   │   ├── ai_consult_result.dart            # sealed class: success/error/fallback
│   │   │   └── ai_consultant_service.dart        # Orchestrator 100% On-device (<60ms)
│   │   └── presentation/
│   │       ├── ai_consult_screen.dart            # Chụp ảnh + chọn info
│   │       ├── ai_result_screen.dart             # Hiển thị kết quả AI
│   │       ├── manual_select_screen.dart         # Fallback chọn dáng mặt thủ công
│   │       └── widgets/
│   │           ├── face_camera_overlay.dart      # Khung oval hướng dẫn
│   │           ├── hair_info_selector.dart       # Chips chọn giới tính/tóc
│   │           └── hairstyle_result_card.dart    # Card kết quả (ảnh + lý do)
│   │
│   ├── search_map/
│   │   ├── data/
│   │   │   └── barber_repository.dart            # Query approved barbers
│   │   └── presentation/
│   │       ├── search_map_screen.dart            # Bản đồ + danh sách
│   │       ├── barber_detail_screen.dart         # Chi tiết thợ
│   │       └── widgets/
│   │           ├── barber_card.dart
│   │           ├── barber_bottom_sheet.dart
│   │           └── map_marker.dart
│   │
│   ├── booking/
│   │   ├── data/
│   │   │   ├── booking_repository.dart           # Transaction đặt/hủy lịch
│   │   │   └── slot_service.dart                 # Sinh slot trống
│   │   └── presentation/
│   │       ├── booking_screen.dart               # Flow: dịch vụ → ngày → slot → xác nhận
│   │       └── widgets/
│   │           ├── service_selector.dart
│   │           ├── date_picker.dart
│   │           ├── time_slot_grid.dart
│   │           └── booking_summary.dart
│   │
│   ├── appointments/
│   │   ├── data/
│   │   │   └── appointment_repository.dart       # Query lịch
│   │   └── presentation/
│   │       ├── customer_appointments_screen.dart  # Danh sách lịch khách
│   │       ├── barber_appointments_screen.dart    # Danh sách lịch thợ
│   │       └── widgets/
│   │           └── appointment_card.dart
│   │
│   ├── barber_profile/
│   │   ├── data/
│   │   │   └── barber_profile_repository.dart
│   │   └── presentation/
│   │       ├── barber_registration_screen.dart    # Form tạo hồ sơ
│   │       ├── barber_edit_screen.dart            # Sửa hồ sơ
│   │       └── widgets/
│   │           ├── service_editor.dart
│   │           ├── working_hours_editor.dart
│   │           ├── hairstyle_picker.dart
│   │           └── location_picker.dart
│   │
│   ├── admin/
│   │   └── presentation/
│   │       ├── admin_panel_screen.dart
│   │       └── approve_barbers_screen.dart
│   │
│   └── profile/
│       └── presentation/
│           ├── profile_screen.dart
│           └── edit_profile_screen.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── home_provider.dart
│   ├── ai_consult_provider.dart
│   ├── search_provider.dart
│   ├── booking_provider.dart
│   ├── appointment_provider.dart
│   └── admin_provider.dart
│
└── routing/
    └── app_router.dart                           # GoRouter configuration
```

---

## 4. MÔ HÌNH DỮ LIỆU

### 4.1 Firestore Collections

```
Firestore Root
├── users/{uid}                    → Tài khoản
├── barberProfiles/{uid}           → Hồ sơ thợ
├── hairstyleCatalog/{styleId}     → Danh mục kiểu tóc
├── appointments/{appointmentId}   → Lịch hẹn
└── bookedSlots/{slotId}           → Slot đã đặt
```

### 4.2 Schema Chi Tiết

**users/{uid}:**
```
uid: String (Firebase Auth UID)
email: String
displayName: String
avatarUrl: String (default "")
role: "customer" | "barber" | "admin"
isBlocked: bool (default false)
createdAt: Timestamp
updatedAt: Timestamp
```

**barberProfiles/{uid}:**
```
uid: String (= users.uid)
displayName: String
avatarUrl: String
bio: String
address: String
location: { latitude: double, longitude: double }
priceMin: int (VNĐ, tự tính = min(services.price))
priceMax: int (VNĐ, tự tính = max(services.price))
ratingAvg: double (0-5, computed)
ratingCount: int (computed)
approvalStatus: "pending" | "approved" | "rejected"
hairstyleIds: List<String> (IDs từ hairstyleCatalog)
services: List<{
  id: String,
  name: String,
  price: int,
  durationMinutes: int (bội số 30),
  active: bool
}>
workingHours: {
  mon: { closed: bool, open: "HH:mm", close: "HH:mm" },
  tue: { ... }, wed: { ... }, thu: { ... },
  fri: { ... }, sat: { ... }, sun: { ... }
}
exceptions: List<{ date: "yyyy-MM-dd", closed: bool, reason: String }>
createdAt: Timestamp
updatedAt: Timestamp
```

**hairstyleCatalog/{styleId}:**
```
id: String
name: String
description: String
imageUrl: String (URL ảnh minh họa kiểu tóc)
faceShapes: List<String> (["oval", "round", "square", "heart", "oblong"])
tags: List<String>
active: bool
```

**appointments/{appointmentId}:**
```
id: String (auto-generated)
customerId: String (users.uid)
barberId: String (users.uid)
barberName: String (denormalized)
customerName: String (denormalized)
serviceId: String
serviceName: String (denormalized)
price: int (VNĐ)
durationMinutes: int
date: String ("yyyy-MM-dd")
startTime: String ("HH:mm")
endTime: String ("HH:mm")
startTimestamp: Timestamp (cho query/logic)
endTimestamp: Timestamp
timezone: "Asia/Ho_Chi_Minh"
slotIds: List<String> (IDs trong bookedSlots)
hairstyleId: String
note: String
status: "pending" | "confirmed" | "completed" | "cancelled" | "rejected"
createdAt: Timestamp
updatedAt: Timestamp
```

**bookedSlots/{slotId}:**
```
Format slotId: "{barberId}_{yyyy-MM-dd}_{HH-mm}"
Ví dụ: "barber_456_2026-10-10_09-00"

barberId: String
date: String ("yyyy-MM-dd")
time: String ("HH:mm")
appointmentId: String
startTimestamp: Timestamp
createdAt: Timestamp
```

---

## 5. HẰNG SỐ NGHIỆP VỤ

```dart
// file: lib/core/constants/business_constants.dart

class BusinessConstants {
  static const int slotMinutes = 30;
  static const int leadTimeMinutes = 30;
  static const int maxBookingDaysAhead = 30;
  static const int maxActiveBookingsPerCustomer = 2;
  static const String timezone = 'Asia/Ho_Chi_Minh';
}
```

---

## 6. LOGIC NGHIỆP VỤ QUAN TRỌNG

### 6.1 Sinh Slot Trống

```
Input: barberProfile, selectedDate, selectedService, existingBookedSlots

Bước 1: Kiểm tra ngày
  - Ngày có phải ngày nghỉ (workingHours[dayOfWeek].closed == true)?
  - Ngày có trong exceptions (exceptions.any(e => e.date == selectedDate && e.closed == true))?
  - Nếu có → Không có slot, hiện thông báo

Bước 2: Lấy giờ mở/đóng
  - open = workingHours[dayOfWeek].open  (VD: "09:00")
  - close = workingHours[dayOfWeek].close (VD: "19:00")

Bước 3: Sinh tất cả slot 30 phút
  - startSlot = open
  - Số slot cần cho dịch vụ = service.durationMinutes / 30
  - Ví dụ: 60 phút = 2 slot liên tiếp
  - Vòng lặp: từ open → (close - durationMinutes), bước 30 phút
  - Mỗi vị trí: kiểm tra TẤT CẢ slot liên tiếp cần thiết đều trống

Bước 4: Loại bỏ slot không hợp lệ
  - Slot ở quá khứ
  - Slot < now + LEAD_TIME_MINUTES (30 phút)
  - Slot đã có trong bookedSlots
  - Ngày > now + MAX_BOOKING_DAYS_AHEAD (30 ngày)

Output: List<AvailableSlot> (startTime, endTime, isAvailable)
```

### 6.2 Transaction Đặt Lịch

```dart
Future<void> createBooking({
  required String customerId,
  required String barberId,
  required String serviceId,
  required String date,
  required String startTime,
  required int durationMinutes,
  required String hairstyleId,
  String? note,
}) async {
  // 1. Kiểm tra số lịch active (pending/confirmed) của customer
  final activeCount = await _countActiveBookings(customerId);
  if (activeCount >= BusinessConstants.maxActiveBookingsPerCustomer) {
    throw MaxBookingsExceededException();
  }

  // 2. Sinh danh sách slotIds cần giữ
  final slotIds = _generateSlotIds(barberId, date, startTime, durationMinutes);

  // 3. Transaction
  await firestore.runTransaction((transaction) async {
    // Kiểm tra mỗi slot
    for (final slotId in slotIds) {
      final slotDoc = await transaction.get(
        firestore.collection('bookedSlots').doc(slotId)
      );
      if (slotDoc.exists) throw SlotAlreadyBookedException(slotId);
    }

    // Tạo appointment
    final appointmentRef = firestore.collection('appointments').doc();
    transaction.set(appointmentRef, {
      'id': appointmentRef.id,
      'customerId': customerId,
      'barberId': barberId,
      // ... tất cả fields
      'slotIds': slotIds,
      'status': 'pending',
    });

    // Tạo bookedSlots
    for (final slotId in slotIds) {
      transaction.set(
        firestore.collection('bookedSlots').doc(slotId),
        {
          'barberId': barberId,
          'date': date,
          'time': slotId.split('_').last.replaceAll('-', ':'),
          'appointmentId': appointmentRef.id,
          'startTimestamp': _parseTimestamp(date, slotId),
          'createdAt': FieldValue.serverTimestamp(),
        }
      );
    }
  });
}
```

### 6.3 Transaction Hủy Lịch

```dart
Future<void> cancelBooking(String appointmentId) async {
  await firestore.runTransaction((transaction) async {
    final appointmentDoc = await transaction.get(
      firestore.collection('appointments').doc(appointmentId)
    );
    final data = appointmentDoc.data()!;

    // Kiểm tra trạng thái
    if (!['pending', 'confirmed'].contains(data['status'])) {
      throw CannotCancelException('Lịch đã hoàn tất hoặc đã hủy');
    }

    // Kiểm tra thời gian
    final startTimestamp = (data['startTimestamp'] as Timestamp).toDate();
    if (DateTime.now().isAfter(
      startTimestamp.subtract(Duration(minutes: BusinessConstants.leadTimeMinutes))
    )) {
      throw CannotCancelException('Chỉ được hủy trước giờ hẹn ít nhất 30 phút');
    }

    // Cập nhật status
    transaction.update(appointmentDoc.reference, {
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Xóa bookedSlots → giải phóng slot
    final slotIds = List<String>.from(data['slotIds']);
    for (final slotId in slotIds) {
      transaction.delete(firestore.collection('bookedSlots').doc(slotId));
    }
  });
}
```

### 6.4 Luồng AI Tư Vấn

```dart
// file: lib/features/ai_consult/domain/ai_consultant_service.dart

class AIConsultantService {
  final FaceValidationService _faceValidator;
  final FaceShapeAnalyzer _faceShapeAnalyzer;
  final HairstyleRecommendationEngine _recommendationEngine;

  AIConsultantService({
    FaceValidationService? faceValidator,
    FaceShapeAnalyzer? faceShapeAnalyzer,
    HairstyleRecommendationEngine? recommendationEngine,
  })  : _faceValidator = faceValidator ?? FaceValidationService(),
        _faceShapeAnalyzer = faceShapeAnalyzer ?? const FaceShapeAnalyzer(),
        _recommendationEngine = recommendationEngine ?? const HairstyleRecommendationEngine();

  Future<AIConsultResult> consultHairstyle({
    required InputImage image,
    required List<HairstyleModel> catalog,
    String? gender,
    String? hairLength,
    String? hairTexture,
  }) async {
    // ═══ TẦNG 1: ML Kit Quality Gate & Contours (on-device, < 40ms) ═══
    final validation = await _faceValidator.validateFace(image);
    if (!validation.isValid || validation.face == null) {
      return AIConsultResult.validationFailed(
        message: validation.errorMessage ?? 'Ảnh không hợp lệ',
        hint: validation.errorHint ?? 'Vui lòng căn chỉnh lại khuôn mặt',
      );
    }

    // ═══ TẦNG 2: FaceShapeAnalyzer - Hình học nhân trắc (on-device, < 10ms) ═══
    final metrics = _faceShapeAnalyzer.analyze(validation.face!);
    final detectedShape = metrics.faceShape;

    // ═══ TẦNG 3: HairstyleRecommendationEngine - Ma trận quy tắc chuyên gia (on-device, < 5ms) ═══
    final recommendation = _recommendationEngine.recommend(
      faceShape: detectedShape,
      catalog: catalog,
      gender: gender,
      preferredLength: hairLength,
      preferredTexture: hairTexture,
    );

    final suggestions = recommendation.primaryRecommendations.take(3).map((rec) {
      return HairstyleSuggestion(
        id: rec.style.id,
        reason: rec.matchReasonVi,
      );
    }).toList();

    return AIConsultResult.success(
      faceShape: detectedShape,
      suggestions: suggestions,
      metrics: metrics,
      recommendation: recommendation,
    );
  }
}
```

### 6.5 ML Kit Face Validation

```dart
// file: lib/features/ai_consult/data/face_validation_service.dart

class FaceValidationService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<FaceValidationResult> validateFace(InputImage image) async {
    final faces = await _faceDetector.processImage(image);

    // Không có mặt
    if (faces.isEmpty) {
      return FaceValidationResult.invalid(
        error: 'Không phát hiện khuôn mặt',
        hint: 'Đảm bảo khuôn mặt nằm trong khung hình',
      );
    }

    // Chọn mặt lớn nhất (nếu nhiều mặt)
    final face = faces.reduce((a, b) =>
      a.boundingBox.width > b.boundingBox.width ? a : b);

    // Kiểm tra góc quay
    if ((face.headEulerAngleY ?? 0).abs() > 20) {
      return FaceValidationResult.invalid(
        error: 'Vui lòng nhìn thẳng vào camera',
        hint: 'Không quay đầu sang trái/phải',
      );
    }
    if ((face.headEulerAngleX ?? 0).abs() > 15) {
      return FaceValidationResult.invalid(
        error: 'Vui lòng giữ đầu thẳng',
        hint: 'Không ngửa hoặc cúi đầu',
      );
    }

    // Kiểm tra kích thước mặt (> 25% ảnh)
    // Lưu ý: cần biết kích thước ảnh để so sánh
    // Tạm thời kiểm tra bounding box width > 100px
    if (face.boundingBox.width < 100) {
      return FaceValidationResult.invalid(
        error: 'Đưa khuôn mặt gần hơn',
        hint: 'Khuôn mặt cần chiếm ít nhất 25% khung hình',
      );
    }

    return FaceValidationResult.valid(face: face);
  }

  void dispose() => _faceDetector.close();
}
```

### 6.6 Hairstyle Recommendation Engine (On-Device Rules Matrix)

```dart
// file: lib/features/ai_consult/domain/hairstyle_recommendation_engine.dart

class HairstyleRecommendationEngine {
  const HairstyleRecommendationEngine();

  RecommendationResult recommend({
    required FaceShape faceShape,
    required List<HairstyleModel> catalog,
    String? gender,
    String? preferredLength,
    String? preferredTexture,
  }) {
    // 1. Lọc theo giới tính & dáng mặt phù hợp
    final matchedStyles = catalog.where((style) {
      if (gender != null && gender.isNotEmpty && style.gender != 'unisex') {
        if (style.gender.toLowerCase() != gender.toLowerCase()) return false;
      }
      return style.faceShapes.contains(faceShape.keyName);
    }).toList();

    // 2. Tính điểm tương thích (Match Score) và xếp hạng gợi ý
    final scoredRecommendations = matchedStyles.map((style) {
      final reason = _generateMatchReason(faceShape, style);
      return ScoredHairstyle(
        style: style,
        matchScore: 0.95,
        matchReasonVi: reason,
      );
    }).toList();

    return RecommendationResult(
      faceShape: faceShape,
      primaryRecommendations: scoredRecommendations,
      generalAdviceVi: faceShape.descriptionVi,
      avoidAdviceVi: _getAvoidAdvice(faceShape),
    );
  }
}
```

---

## 7. ROUTING (GoRouter)

```dart
// file: lib/routing/app_router.dart

// Cấu trúc route:
// /splash
// /login
// /register
// /forgot-password
//
// Customer Shell:
// /customer/home
// /customer/search
// /customer/ai-consult
// /customer/ai-result
// /customer/manual-select
// /customer/profile
// /customer/barber/:barberId
// /customer/booking/:barberId
// /customer/appointments
//
// Barber Shell:
// /barber/appointments
// /barber/profile-setup (nếu chưa có hồ sơ)
// /barber/profile-edit
// /barber/pending (chờ duyệt)
//
// Admin Shell:
// /admin/approve-barbers
```

---

## 8. DESIGN SYSTEM

### 8.1 Colors

```dart
class AppColors {
  static const primary = Color(0xFF1A1A2E);      // Dark Navy
  static const accent = Color(0xFFE94560);        // Coral Red (CTA)
  static const secondary = Color(0xFF16213E);     // Deep Blue
  static const surface = Color(0xFFFFFFFF);       // White
  static const background = Color(0xFFF5F6FA);    // Light Gray
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF8E8E93);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);
  static const divider = Color(0xFFE5E5EA);
}
```

### 8.2 Typography

Font: **Be Vietnam Pro** (thêm vào assets/fonts/)

### 8.3 Spacing

```dart
class AppDimensions {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
}
```

---

## 9. ENUMS & STATUS

```dart
enum UserRole { customer, barber, admin }

enum ApprovalStatus { pending, approved, rejected }

enum AppointmentStatus { pending, confirmed, completed, cancelled, rejected }

enum FaceShape { oval, round, square, heart, oblong }
```

### Transition Rules cho AppointmentStatus:
```
pending    → confirmed (barber action)
pending    → rejected  (barber action) → XÓA bookedSlots
pending    → cancelled (customer action) → XÓA bookedSlots
confirmed  → completed (barber action)
confirmed  → cancelled (customer/barber) → XÓA bookedSlots
completed  → TERMINAL
cancelled  → TERMINAL
rejected   → TERMINAL
```

---

## 10. SECURITY RULES (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() { return request.auth != null; }
    function isAdmin() {
      return isSignedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    function isBlocked() {
      return isSignedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isBlocked == true;
    }

    match /users/{uid} {
      allow read: if isSignedIn() && (request.auth.uid == uid || isAdmin());
      allow create: if isSignedIn()
        && request.auth.uid == uid
        && request.resource.data.role in ['customer', 'barber']
        && request.resource.data.isBlocked == false;
      allow update: if isAdmin();
      // User tự update thông tin cá nhân (không được đổi role, isBlocked)
      allow update: if isSignedIn()
        && request.auth.uid == uid
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'displayName', 'avatarUrl', 'updatedAt'
        ]);
    }

    match /barberProfiles/{uid} {
      allow read: if isSignedIn() && (
        isAdmin() ||
        request.auth.uid == uid ||
        resource.data.approvalStatus == 'approved'
      );
      allow create: if isSignedIn()
        && request.auth.uid == uid
        && request.resource.data.approvalStatus == 'pending';
      allow update: if isAdmin();
      allow update: if isSignedIn()
        && request.auth.uid == uid
        && !isBlocked()
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'displayName', 'avatarUrl', 'bio', 'address', 'location',
          'priceMin', 'priceMax', 'hairstyleIds', 'services',
          'workingHours', 'exceptions', 'updatedAt'
        ]);
    }

    match /hairstyleCatalog/{styleId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    match /appointments/{appointmentId} {
      allow read: if isSignedIn() && (
        resource.data.customerId == request.auth.uid ||
        resource.data.barberId == request.auth.uid ||
        isAdmin()
      );
      allow create: if isSignedIn()
        && !isBlocked()
        && request.resource.data.customerId == request.auth.uid
        && request.resource.data.status == 'pending';
      // Customer chỉ hủy lịch của mình
      allow update: if isSignedIn() && !isBlocked()
        && request.auth.uid == resource.data.customerId
        && request.resource.data.status == 'cancelled'
        && resource.data.status in ['pending', 'confirmed'];
      // Barber chỉ thao tác lịch liên quan
      allow update: if isSignedIn() && !isBlocked()
        && request.auth.uid == resource.data.barberId
        && request.resource.data.status in ['confirmed', 'rejected', 'completed'];
      // Admin toàn quyền
      allow update: if isAdmin();
    }

    match /bookedSlots/{slotId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && !isBlocked();
      // MVP limitation: delete chỉ xảy ra trong Transaction (atomic)
      // Lý tưởng: kiểm tra user là chủ appointment liên quan
      allow delete: if isSignedIn() && !isBlocked();
    }
  }
}
```

---

## 11. SEED DATA

### 11.1 Hairstyle Catalog (10 items)

| id | name | faceShapes |
|---|---|---|
| undercut | Undercut | round, square, oval |
| side_part | Side Part | oval, square, round |
| layer | Layer | oval, heart, oblong |
| buzz_cut | Buzz Cut | square, oval |
| two_block | Two Block | oval, round, heart |
| middle_part | Middle Part | oval, heart |
| pompadour | Pompadour | round, oval |
| textured_crop | Textured Crop | round, square |
| fade | Fade | round, square, oval |
| mohican | Mohican | square, oval |

### 11.2 Barber Seed (5 items)

1. **barber_demo_1** — approved, gần vị trí demo, 5 kiểu tóc
2. **barber_demo_2** — approved, gần vị trí demo, 3 kiểu tóc
3. **barber_demo_3** — approved, xa hơn, 6 kiểu tóc
4. **barber_demo_4** — approved, trung bình, 2 kiểu tóc
5. **barber_demo_5** — **pending** (để demo admin duyệt)

### 11.3 Accounts Seed

| email | role | status |
|---|---|---|
| admin@hairfit.com | admin | — |
| customer@hairfit.com | customer | — |
| barber1@hairfit.com | barber | approved |
| barber5@hairfit.com | barber | pending |
| blocked@hairfit.com | customer | isBlocked=true |

---

## 12. QUY TẮC CODE

### 12.1 Naming Convention
- File: `snake_case.dart`
- Class: `PascalCase`
- Variable/function: `camelCase`
- Constant: `camelCase` (Dart convention, KHÔNG dùng UPPER_SNAKE)
- Riverpod Provider: `camelCaseProvider`

### 12.2 Comment Bắt Buộc
- Đầu mỗi file: comment 1-2 dòng mô tả file làm gì
- Mỗi function public: comment mô tả ngắn
- Logic phức tạp: comment inline tiếng Việt

### 12.3 Error Handling Pattern

```dart
// Mọi repository/service function quan trọng phải:
try {
  // Logic
  // Loading indicator
  // Success toast
} on FirebaseException catch (e) {
  // Firebase error
} on TimeoutException {
  // Timeout
} catch (e) {
  // Generic error
}
// Luôn có: loading indicator + success feedback + error dialog/snackbar
```

### 12.4 State Pattern (Riverpod)

```dart
// Dùng AsyncValue hoặc sealed class:
sealed class BookingState {}
class BookingInitial extends BookingState {}
class BookingLoading extends BookingState {}
class BookingSuccess extends BookingState { final Appointment appointment; }
class BookingError extends BookingState { final String message; }
```

---

## 13. CHỈNH DẪN CHO AI AGENT

### 13.1 Khi Nhận Yêu Cầu Code

1. **Đọc file này** để nắm ngữ cảnh tổng thể
2. **Kiểm tra `HairFit_AI_Specification.md`** nếu cần chi tiết nghiệp vụ
3. **Kiểm tra `HairFit_AI_Timeline.md`** nếu cần biết task đang ở tuần nào
4. **Tuân thủ cấu trúc thư mục** đã định nghĩa ở Mục 3.2
5. **Dùng đúng packages** đã liệt kê ở Mục 2.1
6. **Comment tiếng Việt** ở đầu file và logic phức tạp

### 13.2 Khi Tạo File Mới

- Đặt đúng thư mục theo feature-first structure
- Import từ `core/` cho shared widgets, constants, utils
- Import từ `models/` cho data models
- Dùng Riverpod cho state, GoRouter cho navigation

### 13.3 Khi Sửa Bug

- Kiểm tra edge cases trong `HairFit_AI_Specification.md` Mục 14
- Đảm bảo UI có loading/empty/error states
- Transaction booking/cancel phải atomic (tất cả hoặc không gì)

### 13.4 Thứ Tự Ưu Tiên Khi Triển Khai

```
1. Models + Constants (nền tảng)
2. Services + Repositories (data layer)
3. Providers (state management)
4. Screens + Widgets (UI)
5. Routing (kết nối screens)
6. Edge cases + Polish
```

---

> **File này là "bản đồ" để bất kỳ AI Agent nào đều có thể nhảy vào hỗ trợ triển khai HairFit AI ngay lập tức. Luôn tham chiếu file này khi có thắc mắc về kiến trúc, logic, hoặc quy ước dự án.**
