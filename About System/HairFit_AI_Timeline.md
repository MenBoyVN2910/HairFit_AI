# LỘ TRÌNH 7 TUẦN — HAIRFIT AI
## Dành cho 1 Developer | Flutter + Firebase + AI

> **Ngày tạo:** 2026-09-27  
> **Tổng thời gian:** 7 tuần (bắt đầu tuần tới)  
> **Nguyên tắc:** P0 trước, ổn định trước, không thêm tính năng mới từ tuần 6

---

## TỔNG QUAN TIMELINE

```
Tuần 1 ▓▓▓▓▓▓▓▓▓▓ Nền tảng + Firebase + Spike AI
Tuần 2 ▓▓▓▓▓▓▓▓▓▓ Auth + Hồ sơ thợ + Admin
Tuần 3 ▓▓▓▓▓▓▓▓▓▓ Bản đồ + Tìm thợ
Tuần 4 ▓▓▓▓▓▓▓▓▓▓ Đặt lịch + Quản lý lịch
Tuần 5 ▓▓▓▓▓▓▓▓▓▓ Tích hợp AI vào luồng chính
Tuần 6 ▓▓▓▓▓▓▓▓░░ Ổn định + Polish + P1 (nếu kịp)
Tuần 7 ▓▓▓▓▓▓░░░░ Kiểm thử + Demo + Slide
```

---

## TUẦN 1: NỀN TẢNG + SPIKE AI

### 🎯 Mục tiêu
Setup toàn bộ hạ tầng kỹ thuật và chứng minh AI khả thi trên máy thật.

### 📋 Nhiệm vụ

| # | Task | Ưu tiên | Thời gian | Độ khó |
|---|---|---|---|---|
| 1.1 | Tạo Flutter project (`hairfit_ai`), cấu trúc thư mục feature-first | P0 | 2h | 🟢 Dễ |
| 1.2 | Setup Firebase project (Auth + Firestore) | P0 | 2h | 🟡 Vừa |
| 1.3 | Cấu hình `pubspec.yaml` — thêm tất cả packages chính | P0 | 1h | 🟢 Dễ |
| 1.4 | Tạo file `core/constants/` (colors, text styles, dimensions, business constants) | P0 | 2h | 🟢 Dễ |
| 1.5 | Tạo `app_theme.dart` (ThemeData) | P0 | 1h | 🟢 Dễ |
| 1.6 | Tạo shared widgets (`app_button`, `app_text_field`, `loading_shimmer`, `empty_state`, `error_retry`) | P0 | 3h | 🟡 Vừa |
| 1.7 | Tạo tất cả models (`user_model`, `barber_profile_model`, `hairstyle_model`, `appointment_model`, `booked_slot_model`, `service_model`) | P0 | 4h | 🟡 Vừa |
| 1.8 | Seed `hairstyleCatalog` (10 kiểu tóc) vào Firestore | P0 | 1h | 🟢 Dễ |
| 1.9 | Seed `barberProfiles` mẫu (5 thợ) vào Firestore | P0 | 1h | 🟢 Dễ |
| 1.10 | **SPIKE AI:** Test ML Kit Face Detection (Quality gate & 132 điểm Contours) trên máy thật | P0 | 3h | 🔴 Khó |
| 1.11 | **SPIKE AI:** Test FaceShapeAnalyzer (hình học nhân trắc) + HairstyleRecommendationEngine (On-Device) | P0 | 3h | 🟡 Vừa |
| 1.12 | Tạo `.env` template, thêm `.env` vào `.gitignore` | P0 | 0.5h | 🟢 Dễ |
| 1.13 | Setup GoRouter cơ bản (splash, login, register, home shell) | P0 | 2h | 🟡 Vừa |
| 1.14 | Setup Riverpod (ProviderScope trong main.dart) | P0 | 0.5h | 🟢 Dễ |

### ✅ Deliverables (Kết quả cần đạt cuối tuần)
- [x] Flutter project chạy được trên máy thật
- [x] Firebase kết nối thành công
- [x] ML Kit detect được khuôn mặt và trích xuất điểm viền trên máy thật
- [x] On-Device FaceShapeAnalyzer phân tích dáng mặt chuẩn xác trong < 50ms
- [x] HairstyleRecommendationEngine đề xuất kiểu tóc tức thì kèm lý do chuyên gia
- [x] Có dữ liệu seed (10 hairstyles, 5 barbers)
- [x] Độ trễ On-Device ấn tượng: ML Kit ~40ms, Thuật toán hình học ~10ms (Tổng < 60ms)
- [x] Shared widgets + theme + models sẵn sàng

### ⚠️ Rủi ro tuần này
| Rủi ro | Giải pháp |
|---|---|
| ML Kit không chạy trên emulator | Bắt buộc test máy thật |
| Ảnh chụp không rõ nét / quá tối | ML Kit Face Validation thông báo lỗi và hướng dẫn khách chụp lại |
| Firebase setup lâu | Dùng `flutterfire configure` CLI tự động |

---

## TUẦN 2: AUTH + HỒ SƠ THỢ + ADMIN

### 🎯 Mục tiêu
Hoàn thành toàn bộ hệ thống tài khoản, hồ sơ thợ, và admin duyệt.

### 📋 Nhiệm vụ

| # | Task | Ưu tiên | Thời gian | Độ khó |
|---|---|---|---|---|
| 2.1 | `auth_service.dart` — register, login, logout, resetPassword, checkBlocked | P0 | 3h | 🟡 Vừa |
| 2.2 | `auth_provider.dart` — state management cho auth | P0 | 2h | 🟡 Vừa |
| 2.3 | UI: `login_screen.dart` (email + password + validation + loading/error) | P0 | 3h | 🟢 Dễ |
| 2.4 | UI: `register_screen.dart` (email + password + chọn role + validation) | P0 | 3h | 🟢 Dễ |
| 2.5 | UI: `forgot_password_screen.dart` (email input + send reset) | P0 | 1.5h | 🟢 Dễ |
| 2.6 | UI: Splash screen (check auth state → điều hướng) | P0 | 1.5h | 🟡 Vừa |
| 2.7 | Routing theo role: Customer shell / Barber shell / Admin shell | P0 | 3h | 🔴 Khó |
| 2.8 | `barber_profile_repository.dart` — CRUD hồ sơ thợ | P0 | 3h | 🟡 Vừa |
| 2.9 | UI: `barber_registration_screen.dart` — form tạo hồ sơ (tên, địa chỉ, chọn vị trí map, dịch vụ, kiểu tóc, giờ làm việc) | P0 | 6h | 🔴 Khó |
| 2.10 | Widget: chọn vị trí trên bản đồ (flutter_map picker) | P0 | 3h | 🔴 Khó |
| 2.11 | Widget: quản lý danh sách dịch vụ (thêm/sửa/xóa, validate durationMinutes) | P0 | 2h | 🟡 Vừa |
| 2.12 | Widget: chọn kiểu tóc hỗ trợ (multi-select chips từ catalog) | P0 | 1.5h | 🟢 Dễ |
| 2.13 | Widget: thiết lập giờ làm việc (7 ngày, open/close/closed toggle) | P0 | 2h | 🟡 Vừa |
| 2.14 | UI: Màn hình chờ duyệt cho barber pending | P0 | 1h | 🟢 Dễ |
| 2.15 | `admin_provider.dart` + `approve_barbers_screen.dart` — danh sách pending, nút duyệt/từ chối | P0 | 3h | 🟡 Vừa |
| 2.16 | Viết Security Rules cơ bản cho `users`, `barberProfiles` | P0 | 2h | 🔴 Khó |

### ✅ Deliverables
- [ ] Đăng ký/đăng nhập/quên mật khẩu hoạt động
- [ ] Barber tạo hồ sơ → status `pending`
- [ ] Admin approve → barber status `approved`
- [ ] Customer không thấy barber pending
- [ ] Tài khoản blocked không vào được app
- [ ] Routing đúng theo role

---

## TUẦN 3: BẢN ĐỒ + TÌM THỢ

### 🎯 Mục tiêu
Hiển thị thợ trên bản đồ OpenStreetMap, tính khoảng cách, danh sách sắp xếp.

### 📋 Nhiệm vụ

| # | Task | Ưu tiên | Thời gian | Độ khó |
|---|---|---|---|---|
| 3.1 | `location_service.dart` — xin quyền, lấy vị trí, xử lý từ chối | P0 | 2h | 🟡 Vừa |
| 3.2 | `barber_repository.dart` — query barberProfiles approved | P0 | 2h | 🟢 Dễ |
| 3.3 | `distance_helper.dart` — tính khoảng cách Haversine | P0 | 1h | 🟢 Dễ |
| 3.4 | `search_provider.dart` — load thợ, sắp xếp khoảng cách, filter | P0 | 3h | 🟡 Vừa |
| 3.5 | UI: `search_map_screen.dart` — bản đồ flutter_map + marker thợ | P0 | 5h | 🔴 Khó |
| 3.6 | Widget: Bottom sheet thông tin thợ (bấm marker) | P0 | 2h | 🟡 Vừa |
| 3.7 | Widget: Danh sách thợ (list view, có chuyển đổi map/list) | P0 | 3h | 🟡 Vừa |
| 3.8 | Widget: Card thợ (tên, khoảng cách, giá, badge "Phù hợp") | P0 | 2h | 🟢 Dễ |
| 3.9 | Filter kiểu tóc: nếu có `selectedHairstyleId` → ưu tiên thợ phù hợp | P0 | 2h | 🟡 Vừa |
| 3.10 | UI: `barber_detail_screen.dart` — thông tin chi tiết + dịch vụ + nút đặt lịch | P0 | 4h | 🟡 Vừa |
| 3.11 | Xử lý edge cases: không có vị trí, không có thợ, GPS yếu | P0 | 2h | 🔴 Khó |
| 3.12 | UI: Trang chủ `customer_home_screen.dart` — banner AI, danh mục phổ biến, thợ nổi bật | P0 | 4h | 🟡 Vừa |

### ✅ Deliverables
- [ ] Bản đồ hiển thị thợ approved với marker
- [ ] Danh sách thợ sắp xếp theo khoảng cách
- [ ] Bấm marker → bottom sheet thông tin
- [ ] Bấm vào thợ → màn hình chi tiết
- [ ] Filter kiểu tóc hoạt động
- [ ] Không crash khi không có vị trí
- [ ] Trang chủ Customer hoàn chỉnh

---

## TUẦN 4: ĐẶT LỊCH + QUẢN LÝ LỊCH

### 🎯 Mục tiêu
Booking flow end-to-end: sinh slot, transaction đặt, hủy, confirm/reject/complete.

### 📋 Nhiệm vụ

| # | Task | Ưu tiên | Thời gian | Độ khó |
|---|---|---|---|---|
| 4.1 | `slot_service.dart` — sinh slot trống theo ngày + giờ làm việc + dịch vụ | P0 | 4h | 🔴 Cực Khó |
| 4.2 | Xử lý ngày nghỉ / exception trong sinh slot | P0 | 1h | 🟡 Vừa |
| 4.3 | Xử lý thời lượng dịch vụ (60min = 2 slot, 90min = 3 slot) | P0 | 2h | 🔴 Khó |
| 4.4 | `booking_repository.dart` — transaction đặt lịch (create appointment + bookedSlots) | P0 | 4h | 🔴 Cực Khó |
| 4.5 | Validate: đặt trước 30 phút, trong 30 ngày, max 2 lịch active | P0 | 2h | 🟡 Vừa |
| 4.6 | `booking_provider.dart` — state management booking flow | P0 | 2h | 🟡 Vừa |
| 4.7 | UI: `booking_screen.dart` — chọn dịch vụ → ngày → slot → tóm tắt → xác nhận | P0 | 6h | 🔴 Khó |
| 4.8 | Widget: `time_slot_grid.dart` — hiển thị slot (trống/đã đặt/quá khứ) | P0 | 3h | 🟡 Vừa |
| 4.9 | Transaction hủy lịch — cập nhật status + xóa bookedSlots | P0 | 3h | 🔴 Khó |
| 4.10 | `appointment_repository.dart` — query lịch theo customer/barber | P0 | 2h | 🟡 Vừa |
| 4.11 | `appointment_provider.dart` — state management | P0 | 1h | 🟢 Dễ |
| 4.12 | UI: `customer_appointments_screen.dart` — danh sách lịch + hủy | P0 | 3h | 🟡 Vừa |
| 4.13 | UI: `barber_appointments_screen.dart` — danh sách lịch + confirm/reject/complete | P0 | 3h | 🟡 Vừa |
| 4.14 | Widget: appointment card (status badge, thời gian, actions) | P0 | 2h | 🟢 Dễ |
| 4.15 | Security Rules cho `appointments`, `bookedSlots` | P0 | 2h | 🔴 Khó |

### ✅ Deliverables
- [ ] Đặt lịch thành công, slot bị giữ
- [ ] 2 máy tranh slot → 1 thành công, 1 thất bại
- [ ] Hủy lịch → slot được giải phóng
- [ ] Thợ confirm/reject/complete hoạt động
- [ ] Quy tắc 30 phút trước / 30 ngày tới / max 2 lịch

### ⚠️ Rủi ro tuần này
| Rủi ro | Giải pháp |
|---|---|
| Logic slot phức tạp | Viết unit test cho `slot_service.dart` |
| Transaction fail không rõ lý do | Log chi tiết, test trên 2 máy thật |

---

## TUẦN 5: TÍCH HỢP AI VÀO LUỒNG CHÍNH

### 🎯 Mục tiêu
AI tư vấn hoàn chỉnh: consent → chụp ảnh → ML Kit Contours → FaceShapeAnalyzer → HairstyleRecommendationEngine → kết quả → tìm thợ → đặt lịch.

### 📋 Nhiệm vụ

| # | Task | Ưu tiên | Thời gian | Độ khó |
|---|---|---|---|---|
| 5.1 | `face_validation_service.dart` — ML Kit validate (Quality gate + 132 điểm viền Face Contours) | P0 | 3h | 🔴 Khó |
| 5.2 | `face_shape_analyzer.dart` — Tính toán hình học nhân trắc từ 132 điểm Contours (On-Device, < 50ms) | P0 | 3h | 🔴 Khó |
| 5.3 | `hairstyle_recommendation_engine.dart` — Ma trận quy tắc chuyên gia gợi ý kiểu tóc (On-Device, < 5ms) | P0 | 3h | 🟡 Vừa |
| 5.4 | `ai_consult_result.dart` — Mô hình hóa kết quả phân tích on-device & gợi ý kiểu tóc | P0 | 1h | 🟢 Dễ |
| 5.5 | `ai_consultant_service.dart` — Orchestrator kết nối On-Device Core hoàn chỉnh (<60ms) | P0 | 2h | 🟡 Vừa |
| 5.6 | `hairstyle_repository.dart` — lấy catalog từ Firestore | P0 | 1h | 🟢 Dễ |
| 5.7 | `ai_consult_provider.dart` — state management toàn bộ luồng AI | P0 | 3h | 🟡 Vừa |
| 5.8 | UI: Consent popup (SharedPreferences lưu flag) | P0 | 1h | 🟢 Dễ |
| 5.9 | UI: `ai_consult_screen.dart` — chọn gender/hair length/texture + chụp/chọn ảnh | P0 | 4h | 🔴 Khó |
| 5.10 | Widget: Camera overlay hướng dẫn căn mặt (khung oval) | P0 | 2h | 🟡 Vừa |
| 5.11 | UI: Loading animation (Lottie hoặc shimmer) khi đang phân tích | P0 | 1.5h | 🟢 Dễ |
| 5.12 | UI: `ai_result_screen.dart` — dáng mặt + chỉ số hình học + kiểu tóc card + lý do + mẹo vuốt | P0 | 4h | 🟡 Vừa |
| 5.13 | UI: `manual_select_screen.dart` — chọn dáng mặt thủ công → gợi ý kiểu tóc từ catalog | P0 | 2h | 🟢 Dễ |
| 5.14 | Kết nối AI result → Search Map (truyền `selectedHairstyleId`) | P0 | 1.5h | 🟡 Vừa |
| 5.15 | Xử lý edge cases: Chụp ảnh thiếu sáng, góc nghiêng quá đà, offline hoàn toàn (100% On-Device hoạt động bình thường) | P0 | 2h | 🟡 Vừa |

### ✅ Deliverables
- [ ] Luồng AI end-to-end hoạt động trên máy thật
- [ ] Chụp ảnh hợp lệ → 3 kiểu tóc + lý do
- [ ] AI lỗi → fallback thủ công vẫn dùng được
- [ ] Chọn kiểu tóc AI → bản đồ filter thợ phù hợp
- [ ] Từ chối consent/camera → không crash, có fallback
- [ ] Không lưu ảnh vào Firebase

---

## TUẦN 6: ỔN ĐỊNH + POLISH

### 🎯 Mục tiêu
**KHÔNG THÊM TÍNH NĂNG MỚI LỚN.** Chỉ sửa lỗi, polish UI, seed dữ liệu đẹp.

### 📋 Nhiệm vụ Chính

| # | Task | Ưu tiên | Thời gian | Độ khó |
|---|---|---|---|---|
| 6.1 | Sửa tất cả lỗi phát hiện được (bug fix) | P0 | 8h | 🔴 Khó |
| 6.2 | Thêm loading/empty/error states cho MỌI màn hình | P0 | 4h | 🟡 Vừa |
| 6.3 | Polish UI: spacing, alignment, color consistency | P0 | 4h | 🟡 Vừa |
| 6.4 | Profile screen (avatar, tên, email, lịch sử, đăng xuất) | P0 | 3h | 🟢 Dễ |
| 6.5 | Barber edit screen (sửa hồ sơ đã tạo) | P0 | 3h | 🔴 Khó |
| 6.6 | Test trên máy thật — cả Customer, Barber, Admin flows | P0 | 4h | 🟡 Vừa |
| 6.7 | Seed lại dữ liệu sạch, đẹp cho demo (ngày gần demo) | P0 | 2h | 🟢 Dễ |
| 6.8 | Tối ưu UI cho demo: flow mượt, không giật | P0 | 3h | 🟡 Vừa |

### 📋 P1 — Nếu Còn Thời Gian

| # | Task | Thời gian ước tính | Độ khó |
|---|---|---|---|
| 6.9 | Review đơn giản (rating 1-5 + comment sau completed) | 4h | 🟡 Vừa |
| 6.10 | Chat text cực đơn giản (chỉ text, 1:1) | 6h | 🔴 Khó |
| 6.11 | Filter giá đơn giản (slider) | 2h | 🟢 Dễ |

### ✅ Deliverables
- [ ] Mọi màn hình có loading/empty/error
- [ ] UI nhất quán, không lỗi hiển thị
- [ ] Tất cả flows chạy mượt trên máy thật
- [ ] Dữ liệu seed sạch cho demo

### ⚠️ Quy tắc tuần 6
> **🚫 FREEZE:** Không thêm P0 mới  
> **✅ CHỈ:** Bug fix, polish, test  
> **⚡ P1:** Chỉ làm nếu P0 đã 100% ổn định

---

## TUẦN 7: KIỂM THỬ + DEMO

### 🎯 Mục tiêu
App ổn định, video dự phòng, slide thuyết trình sẵn sàng.

### 📋 Nhiệm vụ Kiểm Thử

| # | Test Case | Kết quả |
|---|---|---|
| 7.1 | Đăng ký customer → đăng nhập → vào Home | ☐ |
| 7.2 | Đăng ký barber → tạo hồ sơ → pending | ☐ |
| 7.3 | Admin login → duyệt thợ → approved | ☐ |
| 7.4 | Quên mật khẩu → nhận email reset | ☐ |
| 7.5 | Tài khoản blocked → không vào app | ☐ |
| 7.6 | AI: ảnh hợp lệ → kết quả 3 kiểu tóc | ☐ |
| 7.7 | AI: ảnh không có mặt → báo lỗi | ☐ |
| 7.8 | AI: mặt nghiêng → báo lỗi | ☐ |
| 7.9 | AI: Không có mạng → Vẫn phân tích On-Device thành công (<60ms) | ☐ |
| 7.10 | AI: từ chối consent → fallback | ☐ |
| 7.11 | Bản đồ: thợ approved hiện, pending ẩn | ☐ |
| 7.12 | Bản đồ: không có vị trí → không crash | ☐ |
| 7.13 | Bản đồ: filter kiểu tóc từ AI | ☐ |
| 7.14 | Đặt lịch: slot đúng, đặt thành công | ☐ |
| 7.15 | Đặt lịch: 2 máy tranh slot → 1 thất bại | ☐ |
| 7.16 | Hủy lịch: slot giải phóng | ☐ |
| 7.17 | Hủy lịch: < 30 phút trước giờ → chặn | ☐ |
| 7.18 | Đặt lịch: > 30 ngày → chặn | ☐ |
| 7.19 | Thợ: confirm → complete | ☐ |
| 7.20 | Thợ: reject → slot giải phóng | ☐ |
| 7.21 | Test không internet → banner lỗi | ☐ |
| 7.22 | Seed data khớp (appointments ↔ bookedSlots) | ☐ |

### 📋 Nhiệm vụ Demo

| # | Task | Thời gian |
|---|---|---|
| 7.23 | Quay video demo dự phòng (toàn bộ luồng 5 phút) | 2h |
| 7.24 | Chuẩn bị 3-4 ảnh khuôn mặt khác nhau cho demo AI | 0.5h |
| 7.25 | Seed dữ liệu demo FINAL (ngày gần ngày demo) | 1h |
| 7.26 | Chuẩn bị slide thuyết trình | 4h |
| 7.27 | Tập demo 2-3 lần | 2h |
| 7.28 | Build APK release cho demo | 1h |

### ✅ Deliverables
- [ ] 22/22 test cases PASS
- [ ] Video demo dự phòng (MP4)
- [ ] APK release chạy ổn
- [ ] Slide thuyết trình hoàn chỉnh
- [ ] Dữ liệu demo sạch, ngày/giờ hợp lệ

---

## TỔNG HỢP CÔNG VIỆC THEO TUẦN

| Tuần | Module chính | Số tasks | Trạng thái |
|---|---|---|---|
| 1 | Nền tảng + Spike AI | 14 | ☐ |
| 2 | Auth + Hồ sơ thợ + Admin | 16 | ☐ |
| 3 | Bản đồ + Tìm thợ + Home | 12 | ☐ |
| 4 | Đặt lịch + Quản lý lịch | 15 | ☐ |
| 5 | Tích hợp AI luồng chính | 14 | ☐ |
| 6 | Ổn định + Polish | 8-11 | ☐ |
| 7 | Kiểm thử + Demo | 28 | ☐ |

---

## MẸO QUẢN LÝ THỜI GIAN (1 DEVELOPER)

### Quy tắc hàng ngày
1. **Buổi sáng:** Code tính năng mới (não tỉnh táo nhất)
2. **Buổi chiều:** Fix bug + polish UI
3. **Cuối ngày (15 phút):** Commit code + ghi chú tiến độ ngắn

### Quy tắc hàng tuần
1. **Thứ 2-5:** Code theo kế hoạch
2. **Thứ 6:** Test toàn bộ tính năng mới trong tuần
3. **Thứ 7-CN:** Fix bug còn lại + chuẩn bị tuần sau

### Nếu bị trễ tiến độ
| Trễ bao nhiêu | Hành động |
|---|---|
| Trễ 1-2 ngày | Cắt P1, tập trung P0 |
| Trễ 3-5 ngày | Đơn giản hóa UI (bớt animation, dùng default widget) |
| Trễ > 1 tuần | Cắt bớt P0: bỏ Home nâng cao, đơn giản Barber edit |

### Nguyên tắc sống còn
> 🔴 **KHÔNG** thêm tính năng mới từ tuần 6  
> 🔴 **KHÔNG** refactor lớn sau tuần 4  
> 🟢 **CÓ** test trên máy thật MỖI TUẦN  
> 🟢 **CÓ** commit code MỖI NGÀY  
> 🟢 **CÓ** video demo dự phòng trước ngày demo

---

## SLIDE THUYẾT TRÌNH ĐỀ XUẤT (8 slide)

| # | Slide | Nội dung |
|---|---|---|
| 1 | Vấn đề & Giải pháp | "Khách không biết chọn kiểu tóc nào" → HairFit AI |
| 2 | Kiến trúc 100% On-Device AI | Sơ đồ ML Kit Contours + FaceShapeAnalyzer + Rule-based Engine |
| 3 | Tại sao On-Device? | Bảng so sánh 3 cách tiếp cận (On-Device vs Cloud vs TFLite) |
| 4 | Pipeline AI | Luồng từ chụp ảnh → trích xuất 36 điểm → tính tỷ lệ → kết quả |
| 5 | Thuật Toán Nhân Trắc Học | 36 điểm Face Contours, 4 mặt cắt ngang tỷ lệ vàng |
| 6 | Demo trực tiếp | Chụp ảnh → kết quả → tìm thợ → đặt lịch |
| 7 | Xử lý Edge Cases | Demo 1-2 trường hợp lỗi |
| 8 | Kết luận & Mở rộng | Tổng kết + hướng phát triển |

---

> **Ghi nhớ:** Timeline này được thiết kế cho 1 developer. Ưu tiên ổn định hơn số lượng tính năng. Luôn có fallback cho mọi tình huống.
