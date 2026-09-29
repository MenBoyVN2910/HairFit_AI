# ĐẶC TẢ CHI TIẾT DỰ ÁN HAIRFIT AI
## App Đặt Lịch Cắt Tóc & Tư Vấn Kiểu Tóc Bằng AI — Flutter / Android

> **Phiên bản:** v2.1 — 100% On-Device AI  
> **Ngày tạo:** 2026-09-27 (Cập nhật 2026-09-28)  
> **Công nghệ:** Flutter 3.x · Dart · Firebase · ML Kit (On-Device Contours & Geometric Engine)  
> **Nền tảng mục tiêu:** Android (minSdk API 26, targetSdk 34)  
> **Thời gian:** 7 tuần | 1 thành viên  
> **Múi giờ nghiệp vụ:** Asia/Ho_Chi_Minh

---

## MỤC LỤC

1. [Tổng Quan Dự Án](#1-tổng-quan-dự-án)
2. [Phạm Vi & Phân Cấp Ưu Tiên](#2-phạm-vi--phân-cấp-ưu-tiên)
3. [Vai Trò Người Dùng & Phân Quyền](#3-vai-trò-người-dùng--phân-quyền)
4. [Yêu Cầu Chức Năng Chi Tiết](#4-yêu-cầu-chức-năng-chi-tiết)
5. [Module AI Tư Vấn Kiểu Tóc (TRỌNG TÂM)](#5-module-ai-tư-vấn-kiểu-tóc-trọng-tâm)
6. [Module Bản Đồ & Tìm Thợ](#6-module-bản-đồ--tìm-thợ)
7. [Module Đặt Lịch & Chống Trùng Slot](#7-module-đặt-lịch--chống-trùng-slot)
8. [Mô Hình Dữ Liệu Firestore](#8-mô-hình-dữ-liệu-firestore)
9. [Kiến Trúc Kỹ Thuật](#9-kiến-trúc-kỹ-thuật)
10. [Cấu Trúc Thư Mục Dự Án](#10-cấu-trúc-thư-mục-dự-án)
11. [UI/UX & Design System](#11-uiux--design-system)
12. [Luồng Người Dùng (User Flows)](#12-luồng-người-dùng-user-flows)
13. [Bảo Mật & Security Rules](#13-bảo-mật--security-rules)
14. [Xử Lý Lỗi & Edge Cases](#14-xử-lý-lỗi--edge-cases)
15. [Yêu Cầu Phi Chức Năng](#15-yêu-cầu-phi-chức-năng)
16. [Dữ Liệu Seed Cho Demo](#16-dữ-liệu-seed-cho-demo)
17. [Tiêu Chí Nghiệm Thu](#17-tiêu-chí-nghiệm-thu)
18. [Kịch Bản Demo 5 Phút](#18-kịch-bản-demo-5-phút)
19. [Rủi Ro & Giải Pháp](#19-rủi-ro--giải-pháp)
20. [Phụ Lục](#20-phụ-lục)

---

## 1. Tổng Quan Dự Án

### 1.1 Ý Tưởng Cốt Lõi

HairFit AI là ứng dụng Android giúp kết nối khách hàng với thợ cắt tóc thông qua **3 trụ cột chính**:

1. **AI Tư Vấn Kiểu Tóc (100% On-Device)** — Chụp ảnh khuôn mặt → ML Kit trích xuất 132 điểm viền Face Contours → Phân tích hình học nhân trắc → Khớp ma trận quy tắc chuyên gia (< 60ms)
2. **Bản Đồ Tìm Thợ** — Hiển thị thợ gần nhất trên bản đồ, lọc theo kiểu tóc AI gợi ý
3. **Đặt Lịch Thông Minh** — Chọn dịch vụ + slot thời gian, chống trùng lịch bằng Firestore Transaction

### 1.2 Luồng Giá Trị Cốt Lõi

```
Khách chụp ảnh khuôn mặt
→ ML Kit kiểm tra ảnh hợp lệ & trích xuất 132 điểm viền (on-device, < 40ms)
→ FaceShapeAnalyzer tính toán hình học nhân trắc (< 10ms)
→ HairstyleRecommendationEngine đối soát ma trận quy tắc chuyên gia (< 5ms)
→ Khách chọn kiểu tóc
→ Hệ thống hiển thị thợ gần nhất cắt được kiểu tóc đó
→ Khách chọn thợ → chọn dịch vụ → chọn slot trống
→ Đặt lịch (Transaction chống trùng)
→ Thợ xác nhận → Hoàn tất
```

### 1.3 Giá Trị Khác Biệt

| Giá trị | Mô tả |
|---|---|
| **AI 100% On-Device** | Tốc độ < 60ms, bảo mật tuyệt đối (ảnh không gửi lên cloud), hoạt động offline trơn tru |
| **Giải thích chi tiết** | Không chỉ gợi ý tên kiểu tóc mà giải thích TẠI SAO phù hợp kèm mẹo tạo nếp thực tế |
| **Bản đồ trực quan** | Trải nghiệm dễ tìm thợ xung quanh với OpenStreetMap |
| **Chống trùng slot** | Hai người đặt cùng slot → chỉ 1 người thành công |
| **Miễn phí hoàn toàn** | Không dùng API có phí (OSM thay Google Maps, On-Device AI 0đ API cost) |

### 1.4 Tiêu Chí Thành Công

Dự án đạt yêu cầu nếu demo được:

1. ✅ Khách đăng ký/đăng nhập bằng Email/Password
2. ✅ Khách quên mật khẩu → nhận email đặt lại
3. ✅ Thợ tạo hồ sơ → Admin duyệt → Hiển thị trên bản đồ
4. ✅ Khách chụp ảnh → AI phân tích dáng mặt → 3 kiểu tóc gợi ý + lý do
5. ✅ Khách chọn kiểu tóc → Xem thợ phù hợp gần nhất trên bản đồ
6. ✅ Khách đặt lịch theo slot trống → Transaction chống trùng
7. ✅ Hủy lịch hợp lệ → Slot được giải phóng
8. ✅ Thợ xác nhận/từ chối/hoàn tất lịch
9. ✅ AI phân tích offline hoàn toàn < 60ms
10. ✅ Tài khoản bị khóa → Không vào được app

---

## 2. Phạm Vi & Phân Cấp Ưu Tiên

> **Nguyên tắc vàng cho 1 dev:** Làm ít nhưng làm ổn định. Không ôm tính năng phụ khi tính năng chính chưa chạy.

### 2.1 P0 — Bắt Buộc Hoàn Thành (MVP)

| # | Module | Chi tiết |
|---|---|---|
| 1 | **Auth** | Đăng ký/đăng nhập Email + Password, quên mật khẩu, chọn role (customer/barber) |
| 2 | **Hồ Sơ Thợ** | Tạo hồ sơ (tên, địa chỉ, vị trí map, dịch vụ, kiểu tóc, giờ làm việc), trạng thái duyệt |
| 3 | **Admin Duyệt** | Xem danh sách pending, duyệt/từ chối hồ sơ thợ |
| 4 | **AI Tư Vấn** | Consent → Camera/Gallery → ML Kit Contours → FaceShapeAnalyzer → HairstyleRecommendationEngine → Kết quả |
| 5 | **Bản Đồ Tìm Thợ** | OpenStreetMap, marker thợ approved, danh sách theo khoảng cách, lọc theo kiểu tóc |
| 6 | **Đặt Lịch** | Chọn dịch vụ → ngày → slot trống → Transaction → Tạo appointment + bookedSlots |
| 7 | **Quản Lý Lịch** | Khách xem/hủy lịch, Thợ confirm/reject/complete, giải phóng slot khi hủy |
| 8 | **Danh Mục Kiểu Tóc** | 10-15 kiểu tóc seed sẵn vào Firestore |
| 9 | **Trang Chủ** | Banner AI CTA, danh mục phổ biến, thợ nổi bật gần bạn |
| 10 | **Profile** | Thông tin cá nhân, lịch sử đặt lịch, đăng xuất |

### 2.2 P1 — Làm Nếu Còn Thời Gian

| Tính năng | Phạm vi tối thiểu |
|---|---|
| **Chat text** | Chỉ text, chỉ giữa khách-thợ liên quan, không media |
| **Đánh giá** | Rating 1-5 sao + comment sau khi lịch completed |
| **Filter giá** | Slider lọc khoảng giá đơn giản |
| **Thợ yêu thích** | Danh sách thợ đã lưu |

### 2.3 P2 / Ngoài Phạm Vi MVP

- ❌ Thanh toán online (VNPay, Momo)
- ❌ Push Notification (FCM)
- ❌ Portfolio ảnh before/after
- ❌ Google Sign-In / SMS OTP
- ❌ Newsfeed mạng xã hội
- ❌ Video call tư vấn
- ❌ Dark Mode
- ❌ Chat media/voice/image
- ❌ Geo query nâng cao (geohash)
- ❌ KYC xác minh danh tính

---

## 3. Vai Trò Người Dùng & Phân Quyền

### 3.1 Danh Sách Vai Trò

| Vai trò | Mô tả | Navigation |
|---|---|---|
| **Customer** | Dùng AI, tìm thợ, đặt lịch | BottomNav: Home, Search, AI, Profile |
| **Barber** | Quản lý hồ sơ, nhận lịch | BottomNav: Lịch, Hồ sơ, Profile |
| **Admin** | Duyệt hồ sơ thợ | Drawer menu |

### 3.2 Ma Trận Phân Quyền

| Chức năng | Customer | Barber | Admin |
|---|---|---|---|
| Đăng ký/đăng nhập | ✅ | ✅ | Tạo sẵn |
| Quên mật khẩu | ✅ | ✅ | ✅ |
| Dùng AI tư vấn | ✅ | ❌ | ❌ |
| Xem thợ đã duyệt | ✅ | ❌ | ✅ |
| Đặt lịch | ✅ | ❌ | ❌ |
| Hủy lịch của mình | ✅ | ❌ | ❌ |
| Xác nhận/từ chối/hoàn tất lịch | ❌ | ✅ | ❌ |
| Tạo/sửa hồ sơ thợ | ❌ | ✅ (của mình) | ❌ |
| Duyệt hồ sơ thợ | ❌ | ❌ | ✅ |
| Tự sửa role | ❌ | ❌ | ❌ |
| Tự sửa isBlocked | ❌ | ❌ | ❌ |

### 3.3 Nguyên Tắc Phân Quyền

- Người dùng **KHÔNG** được tự đổi `role`
- Thợ **KHÔNG** được tự đổi `approvalStatus` thành `approved`
- Khách chỉ thấy thợ đã `approved`
- Khách chỉ thao tác lịch hẹn của mình
- Thợ chỉ thao tác lịch liên quan đến mình
- Mọi thay đổi quyền phải được chặn ở **cả UI lẫn Security Rules**

---

## 4. Yêu Cầu Chức Năng Chi Tiết

### 4.1 UC-01: Quản Lý Tài Khoản

**Auth Method:** Firebase Auth — Email/Password

**Đăng ký:**
- Email hợp lệ (format check)
- Mật khẩu ≥ 6 ký tự
- Chọn role: `customer` hoặc `barber`
- Tạo document `users/{uid}` với `isBlocked = false`

**Đăng nhập:**
- Kiểm tra `users/{uid}.isBlocked` — nếu `true` → đăng xuất + thông báo
- Điều hướng theo role

**Quên mật khẩu:**
- Nhập email → Firebase Password Reset Email
- Thông báo chung "Nếu email tồn tại, liên kết đặt lại đã được gửi"

**Trạng thái UI:** Loading, lỗi email sai, lỗi mật khẩu yếu, lỗi email tồn tại, lỗi sai thông tin

### 4.2 UC-02: Hồ Sơ Thợ

**Thông tin bắt buộc:**
- Tên hiển thị
- Địa chỉ
- Vị trí trên bản đồ (GeoPoint)
- Ít nhất 1 dịch vụ (với `durationMinutes` là bội số 30)
- Ít nhất 1 kiểu tóc hỗ trợ (từ catalog)
- Giờ làm việc ít nhất 1 ngày/tuần

**Validation dịch vụ:**
- `price >= 0`
- `durationMinutes` ∈ {30, 60, 90, 120, 150, 180}
- Không chấp nhận 45, 75 phút trong MVP

**Trạng thái:** Hồ sơ mới = `pending` → Admin duyệt → `approved` / `rejected`

**Thợ có thể sửa:** dịch vụ, kiểu tóc, giờ làm việc, địa chỉ, vị trí, mô tả  
**Thợ KHÔNG được sửa:** `approvalStatus`, `ratingAvg`, `ratingCount`, `uid`, `createdAt`

> **Ghi chú MVP:** Khi thợ đã `approved` mà sửa hồ sơ, `approvalStatus` **KHÔNG** bị reset về `pendin### 5.1 Kiến Trúc Đa Tầng: On-Device Core (Chủ Đạo) + Cloud Advisor (Tùy Chọn)

```
┌────────────────────────────────────────────────────────────────────────┐
│   KIẾN TRÚC HYBRID ĐA TẦNG: ON-DEVICE CORE + CLOUD ADVISOR (TÙY CHỌN)  │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  TẦNG 1: ML Kit Face Detection (ON-DEVICE)                       │  │
│  │  Vai trò: "NGƯỜI GÁC CỔNG" — Lọc ảnh & Trích xuất Contours        │  │
│  │  ✓ Có khuôn mặt? (faces.length >= 1)                             │  │
│  │  ✓ Góc Euler Y <= 20° (nhìn thẳng), Euler X <= 15° (không ngửa) │  │
│  │  ✓ Bounding box >= 100px                                         │  │
│  │  ✓ Trích xuất 132 điểm viền khuôn mặt (Face Contours)            │  │
│  │  🔒 Offline · ⚡ < 100ms · 💰 100% Miễn phí                      │  │
│  └──────────────────────────────┬───────────────────────────────────┘  │
│                                 │ Trích xuất 132 điểm Contours         │
│                                 ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  TẦNG 2: FaceShapeAnalyzer - Hình Học Nhân Trắc (ON-DEVICE)      │  │
│  │  Vai trò: "CHẨN ĐOÁN DÁNG MẶT TOÁN HỌC"                          │  │
│  │  ✓ Đo: Chiều cao mặt, độ rộng trán, gò má, xương quai hàm, cằm   │  │
│  │  ✓ Tính tỷ lệ: Dài/Rộng, Trán/Hàm, Hàm/Gò má, Độ vuông góc hàm    │  │
│  │  ✓ Phân loại chuẩn xác: Oval, Tròn, Vuông, Trái tim, Dài         │  │
│  │  🔒 Offline · ⚡ < 50ms · 💰 100% Miễn phí · Ổn định 100%       │  │
│  └──────────────────────────────┬───────────────────────────────────┘  │
│                                 │ Dáng mặt đã phân loại                │
│                                 ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  TẦNG 3: HairstyleRecommendationEngine - Rule-Based (ON-DEVICE)   │  │
│  │  Vai trò: "CHUYÊN GIA TẠO MẪU TÓC THEO MA TRẬN QUY TẮC"          │  │
│  │  ✓ Đối soát với ma trận quy tắc chuyên gia HairFit AI            │  │
│  │  ✓ Lọc và xếp hạng kiểu tóc phù hợp nhất từ Catalog              │  │
│  │  ✓ Tạo lý do tạo kiểu chi tiết riêng biệt + mẹo tạo nếp thực tế │  │
│  │  🔒 Offline · ⚡ < 5ms · 💰 100% Miễn phí · Nhất quán tuyệt đối   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Bảng So Sánh Các Giải Pháp

| Tiêu chí | ❌ Tự Train (TFLite) | ❌ Cloud LLM Thuần (Cloud API) | ✅ 100% On-Device AI (HairFit AI) |
|---|---|---|---|
| **Thời gian phản hồi** | 200-500ms | 3-15 giây (chậm, dễ timeout) | **< 60ms tức thì** |
| **Độ ổn định** | Trung bình | Kém (Lỗi 503, hết quota, ngắt chuỗi) | **100% ổn định, không lỗi** |
| **Chi phí API** | Miễn phí | Tốn tiền/Hết quota | **0đ (Hoàn toàn miễn phí)** |
| **Phụ thuộc mạng** | Offline | Bắt buộc có internet | **Chạy offline hoàn toàn** |
| **Tính nhất quán** | Tương đối | Cùng 1 ảnh có thể ra kết quả khác nhau | **Tuyệt đối nhất quán & minh bạch** |
| **Khả năng kiểm soát** | Khó chỉnh sửa rule | Phụ thuộc vào prompt bên ngoài | **Toàn quyền tùy biến ma trận dữ liệu** |

### 5.3 Pipeline Xử Lý Hoàn Chỉnh

```
User mở AI Tư Vấn
│
├─ Consent popup & Chọn ảnh / Chụp ảnh chân dung
│
├─ ═══ TẦNG 1: ML Kit Face Detection (< 40ms) ═══
│   ├─ faces == 0 → "Không phát hiện khuôn mặt" → Hướng dẫn căn chỉnh
│   ├─ EulerY > 20° hoặc EulerX > 15° → "Vui lòng nhìn thẳng"
│   ├─ Box < 100px → "Đưa mặt lại gần hơn"
│   └─ Hợp lệ → Trích xuất 132 điểm viền Contours → Chuyển sang Tầng 2
│
├─ ═══ TẦNG 2: FaceShapeAnalyzer (< 10ms) ═══
│   ├─ Trích xuất toạ độ: Trán, Gò má, Quai hàm, Cằm
│   ├─ Tính tỷ lệ nhân trắc học:
│   │   • Tỷ lệ Dài / Rộng (Aspect Ratio)
│   │   • Tỷ lệ Trán / Hàm (Forehead-to-Jaw)
│   │   • Độ vuông góc xương hàm (Jaw Squareness)
│   └─ Phân loại chính xác: Oval, Round, Square, Heart, Oblong
│
└─ ═══ TẦNG 3: HairstyleRecommendationEngine (< 5ms) ═══
    ├─ Lấy Catalog kiểu tóc từ Firestore / Local Cache
    ├─ Khớp với ma trận quy tắc chuyên gia theo dáng mặt
    ├─ Xếp hạng điểm tương thích (Match Score)
    ├─ Đưa ra: Lời khuyên vàng, điều nên tránh, lý do phù hợp riêng biệt và mẹo vuốt sáp
    └─ HIỂN THỊ KẾT QUẢ NGAY LẬP TỨC CHO KHÁCH HÀNG (< 60ms)!
```

### 5.4 Thuật Toán Phân Loại Dáng Mặt Hình Học (Anatomical Slicing)

Hệ thống phân chia 36 điểm đường viền khuôn mặt (`FaceContourType.face`) thành 4 phân vùng giải phẫu dọc theo trục Y (từ đỉnh trán đến đáy cằm):
1. **Vùng Trán (Forehead Band)**: $y \in [y_{min} + 0.15H, y_{min} + 0.32H]$ $\rightarrow W_{forehead}$
2. **Vùng Gò Má (Cheekbone Band)**: $y \in [y_{min} + 0.40H, y_{min} + 0.60H]$ $\rightarrow W_{cheek}$
3. **Vùng Quai Hàm (Jawline Band)**: $y \in [y_{min} + 0.70H, y_{min} + 0.85H]$ $\rightarrow W_{jaw}$
4. **Vùng Cằm (Chin Band)**: $y \in [y_{min} + 0.90H, y_{max}]$ $\rightarrow W_{chin}$

**Quy tắc phân loại định lượng:**
- **Mặt Dài (Oblong)**: Tỷ lệ $H / W_{cheek} > 1.55$.
- **Mặt Vuông (Square)**: Độ vuông xương hàm $W_{jaw} / W_{cheek} \ge 0.86$ và tỷ lệ $H / W_{cheek} \le 1.35$.
- **Mặt Trái Tim (Heart)**: Tỷ lệ trán/hàm $W_{forehead} / W_{jaw} \ge 1.22$ và độ thuôn cằm $W_{chin} / W_{jaw} \le 0.45$.
- **Mặt Tròn (Round)**: Tỷ lệ $H / W_{cheek} < 1.28$ và xương hàm bo tròn mềm ($W_{jaw} / W_{cheek} < 0.86$).
- **Mặt Trái Xoan (Oval)**: Tỷ lệ cân đối hoàng kim $1.28 \le H / W_{cheek} \le 1.55$ với gò má nở rộng nhẹ nhàng và cằm thuôn đều.

### 5.5 Fallback & Độ Tin Cậy Hệ Thống

| Tình huống | Hành vi hệ thống |
|---|---|
| Không có internet | Vẫn phân tích dáng mặt và gợi ý kiểu tóc bình thường 100% nhờ On-Device Core (< 60ms) |
| Ảnh bị nghiêng đầu / quá xa | ML Kit báo lỗi cụ thể kèm hướng dẫn căn chỉnh trực quan (Euler X/Y, bounding box) |
| Người dùng từ chối cấp quyền camera | Màn hình cho phép chọn ảnh từ thư viện hoặc chọn dáng mặt thủ công |
| Khuôn mặt bị che khuất (khẩu trang, kính râm) | Thông báo yêu cầu tháo phụ kiện để nhận diện đủ 132 điểm Contours |

### 5.5 Fallback Thủ Công (Manual Selection)

Trường hợp người dùng không muốn chụp ảnh hoặc camera gặp sự cố phần cứng:
```
Người dùng chọn dáng mặt trực quan:
- Oval (Trái xoan - Cân đối)
- Tròn (Round - Trẻ trung)
- Vuông (Square - Nam tính, góc cạnh)
- Trái tim (Heart - Trán rộng, cằm nhọn)
- Dài (Oblong - Thanh thoát)
→ HairstyleRecommendationEngine lập tức lọc và xếp hạng kiểu tóc từ Catalog tương ứng
```

### 5.6 Quyền Riêng Tư

- ✅ Hiển thị consent popup lần đầu
- ✅ Không lưu ảnh vào Firebase Storage
- ✅ Không lưu đường dẫn ảnh vào Firestore
- ✅ Chỉ giữ ảnh trong bộ nhớ tạm cho phiên hiện tại
- ✅ API key trong `.env`, không commit lên Git

---

## 6. Module Bản Đồ & Tìm Thợ

### 6.1 Công Nghệ

| Thành phần | Package |
|---|---|
| Bản đồ | `flutter_map` + OpenStreetMap tile (miễn phí) |
| Vị trí | `geolocator` |
| Khoảng cách | `latlong2` |

### 6.2 Chiến Lược Truy Vấn (MVP)

```
Query: barberProfiles WHERE approvalStatus == "approved"
→ Tải toàn bộ (tối đa ~200 thợ trong phạm vi demo)
→ Tính khoảng cách phía client (Haversine formula)
→ Sắp xếp theo khoảng cách tăng dần
```

**Giới hạn MVP:** Chỉ đảm bảo "gần nhất" khi số thợ approved nhỏ (5-20 thợ demo). Dữ liệu lớn cần geohash (P2).

### 6.3 Xử Lý Vị Trí

| Trường hợp | Xử lý |
|---|---|
| Cấp quyền | Dùng vị trí hiện tại |
| Từ chối quyền | Cho kéo bản đồ, dùng tâm map làm tham chiếu. Vị trí mặc định: trung tâm TP demo |
| GPS yếu | Hiển thị thông báo, vẫn cho dùng danh sách |

### 6.4 Filter Kiểu Tóc (Từ AI)

- Nếu từ AI → truyền `selectedHairstyleId`
- Ưu tiên thợ có `hairstyleIds` chứa kiểu tóc đó
- Badge "Phù hợp" trên card thợ
- Không có thợ phù hợp → hiển thị tất cả thợ gần + thông báo

### 6.5 Hiển Thị

- Marker trên bản đồ cho mỗi thợ approved
- Bấm marker → Bottom sheet thông tin (tên, khoảng cách, giá, nút đặt lịch)
- Danh sách thợ (có thể chuyển giữa map view / list view)
- Nút "Vị trí của tôi" (quay về GPS)

---

## 7. Module Đặt Lịch & Chống Trùng Slot

### 7.1 Hằng Số Nghiệp Vụ

| Hằng số | Giá trị | Ý nghĩa |
|---|---|---|
| `SLOT_MINUTES` | 30 | Độ dài mỗi slot |
| `LEAD_TIME_MINUTES` | 30 | Đặt trước giờ bắt đầu tối thiểu |
| `MAX_BOOKING_DAYS_AHEAD` | 30 | Chỉ đặt trong 30 ngày tới |
| `MAX_ACTIVE_BOOKINGS_PER_CUSTOMER` | 2 | Tối đa lịch pending/confirmed |

### 7.2 Sinh Slot Trống

**Input:** barberProfile, date, service.durationMinutes, bookedSlots đã tồn tại, thời điểm hiện tại

**Quy tắc:**
1. Ngày không phải ngày nghỉ / exception closed
2. Giờ bắt đầu trong giờ làm việc
3. Giờ kết thúc ≤ giờ đóng cửa
4. Slot không ở quá khứ
5. Giờ bắt đầu cách hiện tại ≥ 30 phút
6. Tất cả slot cần giữ đều chưa bị đặt
7. Ngày ≤ 30 ngày từ hôm nay

**Ví dụ:** Dịch vụ 60 phút, chọn 09:00 → Giữ slot `09:00` + `09:30`

### 7.3 Transaction Đặt Lịch

```dart
await firestore.runTransaction((transaction) async {
  // 1. Kiểm tra từng slot đã tồn tại chưa
  for (final slotRef in slotRefs) {
    final doc = await transaction.get(slotRef);
    if (doc.exists) throw SlotTakenException();
  }
  // 2. Tạo appointment
  transaction.set(appointmentRef, appointmentData);
  // 3. Tạo bookedSlots
  for (final slotRef in slotRefs) {
    transaction.set(slotRef, bookedSlotData);
  }
});
```

### 7.4 Hủy Lịch

**Điều kiện:** `status ∈ {pending, confirmed}` AND `now <= startTimestamp - 30 phút`

**Transaction hủy:**
1. Đọc appointment → kiểm tra trạng thái + thời gian
2. Cập nhật `status = "cancelled"`
3. Xóa các `bookedSlots` tương ứng → Slot được giải phóng

### 7.5 Trạng Thái Lịch Hẹn

```
pending → confirmed (Thợ xác nhận)
pending → rejected (Thợ từ chối) → giải phóng slot
pending → cancelled (Khách hủy) → giải phóng slot
confirmed → completed (Thợ hoàn tất)
confirmed → cancelled (Khách/Thợ hủy) → giải phóng slot
completed → Terminal (có thể đánh giá nếu làm P1)
cancelled → Terminal
rejected → Terminal
```

---

## 8. Mô Hình Dữ Liệu Firestore

### 8.1 Tổng Quan Collections

```
users/                  ← Tài khoản người dùng
barberProfiles/         ← Hồ sơ thợ
hairstyleCatalog/       ← Danh mục kiểu tóc (seed)
appointments/           ← Lịch hẹn
bookedSlots/            ← Slot đã đặt (chống trùng)
reviews/                ← P1: Đánh giá (bỏ qua trong MVP)
conversations/          ← P1: Chat (bỏ qua trong MVP)
```

### 8.2 users/{uid}

```json
{
  "uid": "abc123",
  "email": "user@gmail.com",
  "displayName": "Nguyễn Văn A",
  "avatarUrl": "",
  "role": "customer | barber | admin",
  "isBlocked": false,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 8.3 barberProfiles/{uid}

```json
{
  "uid": "barber_123",
  "displayName": "HairFit Barber",
  "avatarUrl": "",
  "bio": "Chuyên cắt tóc nam...",
  "address": "123 Nguyễn Văn Linh, Đà Nẵng",
  "location": { "latitude": 16.0544, "longitude": 108.2022 },
  "priceMin": 70000,
  "priceMax": 120000,
  "ratingAvg": 0,
  "ratingCount": 0,
  "approvalStatus": "pending | approved | rejected",
  "hairstyleIds": ["undercut", "side_part", "fade"],
  "services": [
    {
      "id": "cut_male",
      "name": "Cắt tóc nam",
      "price": 70000,
      "durationMinutes": 60,
      "active": true
    }
  ],
  "workingHours": {
    "mon": { "closed": false, "open": "09:00", "close": "19:00" },
    "sun": { "closed": true, "open": "00:00", "close": "00:00" }
  },
  "exceptions": [
    { "date": "2026-10-15", "closed": true, "reason": "Nghỉ cá nhân" }
  ],
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

> **Ghi chú:** `priceMin` / `priceMax` được tự tính từ `min(services.price)` / `max(services.price)` khi lưu hồ sơ.

### 8.4 hairstyleCatalog/{styleId}

```json
{
  "id": "undercut",
  "name": "Undercut",
  "description": "Gọn hai bên, phù hợp với mặt tròn và vuông.",
  "imageUrl": "https://example.com/undercut.jpg",
  "faceShapes": ["round", "square", "oval"],
  "tags": ["nam", "gọn", "hiện đại"],
  "active": true
}
```

### 8.5 appointments/{appointmentId}

```json
{
  "id": "appointment_abc",
  "customerId": "customer_123",
  "barberId": "barber_456",
  "barberName": "HairFit Barber",
  "customerName": "Nguyễn Văn A",
  "serviceId": "cut_male",
  "serviceName": "Cắt tóc nam",
  "price": 70000,
  "durationMinutes": 60,
  "date": "2026-10-10",
  "startTime": "09:00",
  "endTime": "10:00",
  "startTimestamp": "Timestamp",
  "endTimestamp": "Timestamp",
  "timezone": "Asia/Ho_Chi_Minh",
  "slotIds": ["barber_456_2026-10-10_09-00", "barber_456_2026-10-10_09-30"],
  "hairstyleId": "undercut",
  "note": "",
  "status": "pending",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 8.6 bookedSlots/{slotId}

**Format ID:** `{barberId}_{yyyy-MM-dd}_{HH-mm}`

```json
{
  "barberId": "barber_456",
  "date": "2026-10-10",
  "time": "09:00",
  "appointmentId": "appointment_abc",
  "startTimestamp": "Timestamp",
  "createdAt": "Timestamp"
}
```

---

## 9. Kiến Trúc Kỹ Thuật

### 9.1 Tech Stack

| Lớp | Công nghệ |
|---|---|
| **UI** | Flutter 3.x |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Auth** | Firebase Auth (Email/Password) |
| **Database** | Cloud Firestore |
| **AI (100% On-Device)** | Google ML Kit (Face Contours) + FaceShapeAnalyzer + HairstyleRecommendationEngine |
| **Map** | flutter_map + OpenStreetMap |
| **Location** | geolocator + latlong2 |
| **Env** | flutter_dotenv |

### 9.2 Packages Chính

```yaml
dependencies:
  # Core Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0

  # AI - On-Device Face Detection & Contours
  google_mlkit_face_detection: ^0.11.0

  # Map & Location
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
  geolocator: ^12.0.0

  # Image
  image_picker: ^1.0.0

  # State & Navigation
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0

  # Utils
  flutter_dotenv: ^5.1.0
  intl: ^0.19.0
  connectivity_plus: ^6.0.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  shared_preferences: ^2.2.0
```

### 9.3 Sơ Đồ Kiến Trúc

```
┌─────────────────────────────────────────────┐
│               FLUTTER APP                    │
│                                              │
│  Presentation (Screens, Widgets)             │
│       ↕                                      │
│  Application (Riverpod Providers)            │
│       ↕                                      │
│  Domain (Models, Enums, AI Geometric Engine) │
│       ↕                                      │
│  Data (Services, Repositories)               │
│       ↕                                      │
│  ┌──────────┐  ┌──────────┐                  │
│  │ ML Kit   │  │ Services │                  │
│  │(on-device)│  │(Firebase)│                  │
│  └──────────┘  └──────────┘                  │
└──────────────────┬──────────────────────────┘
                   │ Internet
┌──────────────────┴──────────────────────────┐
│  Firebase (Auth, Firestore)                  │
│  OpenStreetMap Tiles                         │
└─────────────────────────────────────────────┘
```

---

## 10. Cấu Trúc Thư Mục Dự Án

```
hairfit_ai/
├── android/
├── assets/
│   ├── images/
│   ├── animations/
│   └── fonts/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   ├── app_dimensions.dart
│   │   │   └── business_constants.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── date_formatter.dart
│   │   │   └── distance_helper.dart
│   │   ├── services/
│   │   │   ├── firebase_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── location_service.dart
│   │   │   └── connectivity_service.dart
│   │   └── widgets/
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       ├── loading_shimmer.dart
│   │       ├── empty_state.dart
│   │       ├── error_retry.dart
│   │       ├── status_badge.dart
│   │       └── rating_stars.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── barber_profile_model.dart
│   │   ├── hairstyle_model.dart
│   │   ├── appointment_model.dart
│   │   ├── booked_slot_model.dart
│   │   └── service_model.dart
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── ai_consult/
│   │   ├── search_map/
│   │   ├── booking/
│   │   ├── appointments/
│   │   ├── barber_profile/
│   │   ├── admin/
│   │   ├── profile/
│   │   └── chat/               # P1
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── home_provider.dart
│   │   ├── ai_consult_provider.dart
│   │   ├── search_provider.dart
│   │   ├── booking_provider.dart
│   │   ├── appointment_provider.dart
│   │   └── admin_provider.dart
│   └── routing/
│       └── app_router.dart
├── .env
├── .gitignore
├── pubspec.yaml
└── README.md
```

---

## 11. UI/UX & Design System

### 11.1 Color Palette

```
Primary:     #1A1A2E   (Dark Navy)
Accent:      #E94560   (Coral Red — CTA)
Secondary:   #16213E   (Deep Blue)
Surface:     #FFFFFF   (White)
Background:  #F5F6FA   (Light Gray)
Text:        #1A1A2E
Text Light:  #8E8E93
Success:     #34C759
Warning:     #FF9500
Error:       #FF3B30
Divider:     #E5E5EA
```

### 11.2 Typography

Font: **Be Vietnam Pro** (Google Font, hỗ trợ tiếng Việt)

| Thành phần | Size | Weight |
|---|---|---|
| Heading 1 | 24sp | Bold (700) |
| Heading 2 | 20sp | SemiBold (600) |
| Heading 3 | 16sp | SemiBold (600) |
| Body | 14sp | Regular (400) |
| Caption | 12sp | Regular (400) |
| Button | 14sp | SemiBold (600) |

### 11.3 Spacing & Radius

| Token | Giá trị |
|---|---|
| `space_xs` | 4dp |
| `space_sm` | 8dp |
| `space_md` | 12dp |
| `space_lg` | 16dp |
| `space_xl` | 24dp |
| `radius_sm` | 8dp |
| `radius_md` | 12dp |
| `radius_lg` | 16dp |

### 11.4 Phong Cách Thiết Kế

- Minimalist, sạch sẽ, tương phản tốt
- Nút CTA nổi bật (Accent color)
- Mọi màn hình có: Loading shimmer, Empty state, Error + Retry

---

## 12. Luồng Người Dùng (User Flows)

### 12.1 Luồng Tổng Thể

```
Mở app → Splash (1.5s)
├─ Đã login → Kiểm tra isBlocked → Kiểm tra role → Shell tương ứng
└─ Chưa login → Login / Register

Sau đăng nhập:
├─ Customer → BottomNav (Home | Search | AI | Profile)
├─ Barber (pending) → Màn hình chờ duyệt
├─ Barber (approved) → BottomNav (Lịch | Hồ sơ | Profile)
└─ Admin → Drawer (Duyệt hồ sơ)
```

### 12.2 Luồng Đặt Lịch (Happy Path)

```
Chọn thợ → Chọn dịch vụ → Chọn ngày → Chọn slot trống
→ Ghi chú (tùy chọn) → Xem tóm tắt → Xác nhận
→ Transaction → Thành công / Slot đã bị đặt
```

---

## 13. Bảo Mật & Security Rules

### 13.1 Pseudo Security Rules

```js
// users
match /users/{uid} {
  allow read: if auth.uid == uid || isAdmin();
  allow create: if auth.uid == uid
    && data.role in ['customer', 'barber']
    && data.isBlocked == false;
  allow update: if isAdmin();
  // User tự update thông tin cá nhân
  allow update: if auth.uid == uid
    && !changedFields(['role', 'isBlocked', 'uid', 'email', 'createdAt']);
}

// barberProfiles
match /barberProfiles/{uid} {
  allow read: if isAdmin() || auth.uid == uid
    || resource.data.approvalStatus == 'approved';
  allow create: if auth.uid == uid
    && data.approvalStatus == 'pending';
  allow update: if isAdmin();
  allow update: if auth.uid == uid
    && !changedFields(['approvalStatus','ratingAvg','ratingCount','uid','createdAt']);
}

// appointments
match /appointments/{id} {
  allow read: if resource.data.customerId == auth.uid
    || resource.data.barberId == auth.uid
    || isAdmin();
  allow create: if data.customerId == auth.uid
    && data.status == 'pending'
    && data.startTimestamp > now + 30min
    && data.startTimestamp < now + 30days;
  // Customer chỉ hủy lịch của mình
  allow update: if auth.uid == resource.data.customerId
    && data.status == 'cancelled';
  // Barber thao tác lịch liên quan
  allow update: if auth.uid == resource.data.barberId
    && data.status in ['confirmed', 'rejected', 'completed'];
  allow update: if isAdmin();
}

// bookedSlots (client transaction)
match /bookedSlots/{slotId} {
  allow read: if isSignedIn();
  allow create: if isSignedIn() && !isBlocked();
  // MVP limitation: delete chỉ xảy ra trong Transaction (atomic)
  allow delete: if isSignedIn() && !isBlocked();
}
```

---

## 14. Xử Lý Lỗi & Edge Cases

| Tình huống | Xử lý |
|---|---|
| Không có internet | Vẫn phân tích AI on-device bình thường; Banner khi truy cập phần cần mạng |
| AI chụp lỗi góc nghiêng / quá xa | ML Kit thông báo căn chỉnh góc thẳng + đưa mặt lại gần |
| Người dùng không muốn chụp ảnh | Fallback thủ công chọn dáng mặt trực quan |
| Slot bị đặt (race condition) | Transaction fail → "Slot đã bị đặt, chọn slot khác" |
| Hủy lịch < 30 phút trước giờ | Chặn + thông báo lý do |
| Barber bị khóa có lịch cũ | Lịch cũ giữ, ẩn khỏi tìm kiếm |
| Camera bị từ chối quyền | Thông báo + fallback thủ công |
| Tài khoản blocked | Đăng xuất + thông báo |

**UI States bắt buộc:** Loading shimmer, Empty (illustration + text + CTA), Error (thông báo + Thử lại)

---

## 15. Yêu Cầu Phi Chức Năng

| Yêu cầu | Chi tiết |
|---|---|
| Nền tảng | Android, minSdk API 26 |
| Ngôn ngữ giao diện | Tiếng Việt |
| Bảo mật | Firebase Security Rules, API key trong .env |
| Hiệu năng | AI on-device < 500ms, lazy loading, image caching |
| Responsive | Hỗ trợ 5.5" - 6.7" |
| Offline | Không hỗ trợ offline trong MVP |
| Dark Mode | Không hỗ trợ trong MVP |
| Code quality | Chú thích rõ ràng bằng tiếng Việt |

---

## 16. Dữ Liệu Seed Cho Demo

### 16.1 Hairstyle Catalog (10 kiểu)

| ID | Tên | Dáng mặt |
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

### 16.2 Tài Khoản Seed

- 1 admin, 1 customer demo, 1 blocked account
- 4 barber approved + 1 barber pending

### 16.3 Lịch Hẹn Seed

- 1 pending + bookedSlots, 1 confirmed + bookedSlots, 1 completed

---

## 17. Tiêu Chí Nghiệm Thu

- ✅ Auth Email/Password + quên mật khẩu
- ✅ Tài khoản blocked bị chặn
- ✅ Hồ sơ thợ pending → Admin approve → hiển thị bản đồ
- ✅ AI: ảnh hợp lệ → kết quả + lý do; ảnh lỗi → báo lỗi; AI lỗi → fallback
- ✅ Bản đồ: thợ approved, sắp xếp khoảng cách, filter kiểu tóc
- ✅ Đặt lịch: slot đúng, transaction chống trùng, hủy giải phóng slot
- ✅ Quy tắc 30 phút trước / 30 ngày tới

---

## 18. Kịch Bản Demo 5 Phút

1. **Giới thiệu** (30s): HairFit AI — AI tư vấn + tìm thợ + đặt lịch
2. **Admin duyệt** (30s): Login admin → duyệt thợ pending
3. **AI tư vấn** (90s): Login customer → chụp ảnh → AI kết quả
4. **Tìm thợ** (30s): Chọn kiểu tóc → bản đồ → thợ phù hợp
5. **Đặt lịch** (60s): Chọn dịch vụ → slot → đặt thành công
6. **Thợ xác nhận** (30s): Login barber → confirm
7. **Kết luận** (30s): Luồng end-to-end hoàn chỉnh

---

## 19. Rủi Ro & Giải Pháp

| Rủi ro | Mức | Giải pháp |
|---|---|---|
| 1 dev, 7 tuần | 🔴 | Cắt P1/P2 sớm, freeze P0 từ tuần 6 |
| Ảnh chụp mờ / thiếu sáng | 🟡 | ML Kit Face Validation thông báo lỗi và hướng dẫn chụp lại |
| ML Kit lỗi emulator | 🟡 | Test máy thật từ tuần 1 |
| Race condition booking | 🟡 | Firestore Transaction |
| API key lộ | 🟡 | .env + .gitignore |
| Ôm tính năng phụ | 🔴 | Tuân thủ P0/P1/P2 |

---

## 20. Phụ Lục

### 20.1 Enums

```
Role: customer, barber, admin
ApprovalStatus: pending, approved, rejected
AppointmentStatus: pending, confirmed, completed, cancelled, rejected
FaceShape: oval, round, square, heart, oblong
```

### 20.2 Format

```
date: yyyy-MM-dd
time: HH:mm
slotId: {barberId}_{yyyy-MM-dd}_{HH-mm}
timezone: Asia/Ho_Chi_Minh
```

### 20.3 Quyền Android

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 20.4 Hằng Số

```
SLOT_MINUTES = 30
LEAD_TIME_MINUTES = 30
MAX_BOOKING_DAYS_AHEAD = 30
MAX_ACTIVE_BOOKINGS_PER_CUSTOMER = 2
```

---

> **Câu chốt phạm vi:** HairFit AI tập trung vào luồng cốt lõi: khách chụp ảnh khuôn mặt để AI tư vấn kiểu tóc phù hợp, sau đó xem bản đồ tìm thợ gần nhất, chọn dịch vụ và slot trống, rồi đặt lịch ổn định với cơ chế chống trùng slot. Các tính năng phụ được đưa ra khỏi MVP để đảm bảo 1 developer hoàn thành trong 7 tuần.
