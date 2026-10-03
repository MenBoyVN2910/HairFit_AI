# 💈 HairFit AI

## 🌟 1. Giới Thiệu Dự Án
**HairFit AI** là một ứng dụng di động thông minh giúp kết nối khách hàng với các thợ cắt tóc chuyên nghiệp, đồng thời tích hợp công nghệ Trí tuệ nhân tạo (AI) ngay trên điện thoại để tư vấn kiểu tóc phù hợp nhất với từng cá nhân.

**Vấn đề giải quyết:**
- **Đối với khách hàng:** Thường xuyên băn khoăn không biết khuôn mặt mình hợp với kiểu tóc nào, sợ rủi ro khi thử kiểu mới và mất thời gian chờ đợi tại salon.
- **Đối với thợ cắt tóc:** Khó khăn trong việc tiếp cận khách hàng mới, quản lý lịch hẹn thủ công dễ bị trùng lặp hoặc quên lịch.

**Ai cần đến HairFit AI?**
- **Người dùng cá nhân:** Những người muốn làm mới bản thân, tìm kiếm kiểu tóc chân ái và muốn đặt lịch cắt tóc nhanh chóng, tiện lợi.
- **Thợ cắt tóc/Salon:** Các chuyên gia tạo mẫu tóc muốn số hóa quy trình quản lý lịch hẹn, xây dựng hồ sơ chuyên nghiệp và tiếp cận đúng tệp khách hàng.

## ✨ 2. Tính Năng Nổi Bật
- **🤖 Chuyên Gia AI Tư Vấn (On-Device AI):** Chỉ cần chụp một bức ảnh, AI tích hợp sẵn trên điện thoại sẽ tự động phân tích tỷ lệ khuôn mặt của bạn (tròn, vuông, trái xoan,...) và đề xuất các kiểu tóc phù hợp nhất, kèm theo lời khuyên về những kiểu nên tránh. Tốc độ phân tích cực nhanh (dưới 1 giây) và bảo mật tuyệt đối vì ảnh không bao giờ bị gửi đi đâu.
- **🗺️ Tìm Kiếm Thợ Quanh Đây:** Tích hợp bản đồ số thông minh giúp bạn dễ dàng quét và tìm ra những thợ cắt tóc, salon uy tín đang ở gần khu vực của bạn nhất.
- **📅 Đặt Lịch Chống Trùng Lặp:** Hệ thống đặt lịch theo từng khung giờ (30 phút/slot), sử dụng công nghệ chống tranh chấp giao dịch đảm bảo không bao giờ có chuyện hai khách hàng đặt trùng vào một thời điểm của cùng một thợ.
- **💼 Quản Lý Hồ Sơ Chuyên Nghiệp:** Thợ cắt tóc có thể tạo trang cá nhân (Profile) với thông tin chi tiết, dịch vụ cung cấp, giá cả và hình ảnh các mẫu tóc đã thực hiện.
- **💬 Nhắn Tin & Đánh Giá:** Hỗ trợ chat trực tiếp giữa khách và thợ để trao đổi chi tiết trước khi cắt. Sau khi trải nghiệm, khách hàng có thể để lại đánh giá và điểm số (Rating).

## 🛠️ 3. Công Nghệ Sử Dụng
HairFit AI được xây dựng theo tiêu chuẩn phát triển ứng dụng di động hiện đại:
- **Nền tảng phát triển:** Flutter (Dart) - giúp ứng dụng chạy mượt mà trên cả hai hệ điều hành Android và iOS từ một mã nguồn duy nhất.
- **Trí tuệ nhân tạo (AI):** Google ML Kit - giúp nhận diện và trích xuất đặc điểm khuôn mặt trực tiếp trên điện thoại mà không cần phải gọi API trả phí từ bên thứ 3.
- **Lưu trữ & Hệ thống (Backend):** Firebase (Authentication & Cloud Firestore) - quản lý tài khoản, lưu trữ dữ liệu thời gian thực và xử lý chống trùng lặp dữ liệu (Transaction) khi đặt lịch.
- **Bản đồ số:** OpenStreetMap kết hợp thư viện Flutter Map.
- **Kiến trúc quản lý trạng thái:** Riverpod.

## 📂 4. Cấu Trúc Tổng Quan Của Dự Án
Dự án được phân chia thư mục theo chuẩn **Feature-First** (Nhóm theo tính năng), giúp mã nguồn dễ đọc, dễ bảo trì và mở rộng:

```text
HairFit_AI/
├── docs/           # Toàn bộ tài liệu đặc tả, kế hoạch triển khai, timeline, kịch bản test
├── lib/
│   ├── core/           # Chứa các tài nguyên dùng chung: Màu sắc, Fonts, các Widget nút bấm, định dạng thời gian...
│   ├── features/       # Chứa các tính năng chính của app (mỗi tính năng nằm trong 1 thư mục riêng):
│   │   ├── admin/          # Quản trị viên duyệt hồ sơ thợ
│   │   ├── ai_consult/     # Tính năng AI quét mặt & tư vấn kiểu tóc
│   │   ├── appointments/   # Quản lý lịch hẹn
│   │   ├── auth/           # Đăng nhập, Đăng ký, Quên mật khẩu
│   │   ├── barber_profile/ # Hồ sơ của thợ cắt tóc
│   │   ├── booking/        # Chức năng chọn dịch vụ & đặt lịch
│   │   ├── chat/           # Hệ thống nhắn tin
│   │   ├── home/           # Màn hình chính của khách hàng
│   │   ├── profile/        # Hồ sơ khách hàng & chỉnh sửa thông tin
│   │   └── search_map/     # Bản đồ tìm kiếm thợ
│   ├── models/         # Các khuôn mẫu dữ liệu (Tài khoản, Lịch hẹn, Kiểu tóc...)
│   ├── providers/      # Nơi quản lý trạng thái và logic liên kết dữ liệu
│   └── routing/        # Điều hướng (chuyển trang) trong ứng dụng
└── test/               # Các kịch bản kiểm thử (test) để đảm bảo app luôn chạy đúng
```

## 🚀 5. Hướng Dẫn Cài Đặt Chi Tiết (Dành Cho Lập Trình Viên)
Để có thể chạy dự án này trên máy tính của bạn, vui lòng làm theo các bước sau:

**Bước 1: Chuẩn bị môi trường**
- Đảm bảo máy tính của bạn đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản 3.x trở lên).
- Cài đặt một phần mềm lập trình (IDE) như Android Studio hoặc Visual Studio Code (có cài extension Flutter & Dart).
- Chuẩn bị một máy ảo (Android Emulator/iOS Simulator) hoặc cắm cáp kết nối máy tính với điện thoại thật.

**Bước 2: Tải dự án và cài đặt thư viện**
Mở phần mềm dòng lệnh (Terminal / Command Prompt) tại thư mục gốc của dự án và chạy lệnh sau để tải các thư viện cần thiết:
```bash
flutter pub get
```

**Bước 3: Cấu hình Firebase (Tùy chọn)**
Dự án hiện tại đã được liên kết sẵn với một dự án Firebase mặc định (thông qua `google-services.json`). Nếu bạn muốn chạy trên hệ thống cơ sở dữ liệu của riêng mình để tự quản lý:
1. Truy cập [Firebase Console](https://console.firebase.google.com/), tạo một dự án mới.
2. Tải file `google-services.json` cho Android và thả vào thư mục `android/app/`.
3. Tải file `GoogleService-Info.plist` cho iOS và thả vào thư mục `ios/Runner/`.

**Bước 4: Chạy ứng dụng**
Khởi chạy ứng dụng lên máy ảo hoặc thiết bị thật của bạn bằng lệnh:
```bash
flutter run
```

*(Lưu ý: Tính năng bản đồ yêu cầu có kết nối internet để tải dữ liệu bản đồ).*

## 🤝 6. Đóng Góp & Hỗ Trợ
Nếu bạn có bất kỳ đóng góp nào để cải thiện ứng dụng, vui lòng tạo **Pull Request** hoặc mở một **Issue** trên kho lưu trữ (Repository) này. 
Mọi góp ý đều được trân trọng để giúp HairFit AI ngày càng hoàn thiện hơn!

---
*HairFit AI - Định Hình Phong Cách, Đặt Lịch Trong Tầm Tay.*
