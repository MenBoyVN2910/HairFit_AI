# 💈 HairFit AI

> **Ứng dụng Tư Vấn Kiểu Tóc & Đặt Lịch Cắt Tóc Thông Minh bằng On-Device AI**  
> Xây dựng bằng **Flutter 3.x**, **Dart**, **Firebase (Auth & Firestore)** và **Google ML Kit**.

---

## 🚀 Tính Năng Nổi Bật

1. **AI Tư Vấn Kiểu Tóc (100% On-Device AI):**
   - **Tầng 1 (ML Kit Contours):** Trích xuất 132 điểm viền khuôn mặt và kiểm tra chất lượng ảnh (Euler X/Y, bounding box) trong `~40ms`.
   - **Tầng 2 (FaceShapeAnalyzer):** Phân tích hình học nhân trắc qua 4 lát cắt giải phẫu (Trán, Gò má, Quai hàm, Cằm) để phân loại dáng mặt (Oval, Tròn, Vuông, Trái tim, Dài) trong `~10ms`.
   - **Tầng 3 (HairstyleRecommendationEngine):** Khớp ma trận quy tắc chuyên gia tạo mẫu tóc theo dáng mặt, đưa ra lời khuyên tạo kiểu, kiểu tóc nên tránh và mẹo vuốt sáp trong `< 5ms`.
   - **Đặc điểm:** Tốc độ tức thì (< 60ms tổng cộng), 100% offline, chi phí 0đ, ảnh không bao giờ gửi ra ngoài thiết bị.

2. **Bản Đồ Tìm Thợ (OpenStreetMap):**
   - Tìm kiếm các thợ cắt tóc xung quanh hiển thị trên bản đồ số, lọc theo kiểu tóc AI đề xuất.

3. **Đặt Lịch Chống Trùng (Firestore Transaction):**
   - Quản lý khung giờ slot 30 phút, chống race-condition tranh chấp slot giữa các khách hàng bằng Firestore Transaction.

---

## 🛠️ Công Nghệ & Thư Viện

- **Mobile Framework:** Flutter 3.x (Android SDK 26 - 34)
- **State Management:** Riverpod (`flutter_riverpod: ^2.6.1`)
- **Navigation:** GoRouter (`go_router: ^14.8.1`)
- **Backend Services:** Firebase Auth, Cloud Firestore (`firebase_core`, `firebase_auth`, `cloud_firestore`)
- **On-Device Vision:** Google ML Kit Face Detection (`google_mlkit_face_detection: ^0.11.1`)
- **Map & Location:** Flutter Map (`flutter_map: ^7.0.2`), Geolocator (`geolocator: ^12.0.0`), LatLong2

---

## 📂 Cấu Trúc Thư Mục (Feature-First)

```
lib/
├── core/                       # Thành phần dùng chung toàn app
│   ├── constants/              # Màu sắc, font chữ, kích thước, hằng số nghiệp vụ
│   ├── services/               # Firebase service, options, seed data, connectivity
│   ├── theme/                  # ThemeData chuẩn Material 3
│   ├── utils/                  # Format tiền tệ, ngày giờ, tính khoảng cách, validate form
│   └── widgets/                # AppButton, AppTextField, Shimmer, EmptyState, v.v.
├── features/                   # Các module chức năng theo từng feature
│   ├── ai_consult/             # Luồng AI tư vấn (ML Kit, Analyzer, Recommendation Engine, Spike Screen)
│   ├── auth/                   # Màn hình Splash, Đăng nhập, Đăng ký, Quên mật khẩu
│   └── home/                   # Màn hình Customer Home Shell
├── models/                     # UserModel, BarberProfileModel, HairstyleModel, AppointmentModel, v.v.
├── providers/                  # Toàn bộ Provider dùng chung
└── routing/                    # Cấu hình GoRouter
```

---

## 🧪 Kiểm Thử (Testing)

Dự án bao gồm bộ kiểm thử tự động toàn diện:
- Kiểm thử hình học nhân trắc 5 dáng mặt chuẩn
- Kiểm thử ma trận gợi ý kiểu tóc và lời khuyên chuyên gia
- Kiểm thử toàn bộ 6 Data Models (Serialization / Deserialization)
- Kiểm thử bộ Validators, DateFormatter và DistanceHelper
- Kiểm thử Widget Splash Screen & Navigation Flow

Chạy kiểm thử:
```bash
flutter test
```

Phân tích tĩnh mã nguồn:
```bash
flutter analyze
```

---

## 📱 Cài Đặt & Chạy Ứng Dụng

1. Cài đặt các gói phụ thuộc:
   ```bash
   flutter pub get
   ```
2. Chạy ứng dụng trên thiết bị Android:
   ```bash
   flutter run -d <device-id>
   ```
