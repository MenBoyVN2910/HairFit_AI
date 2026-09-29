# Hướng Dẫn Kỹ Thuật Prompting Cho AI Agent (HairFit AI)
## Chiến lược giao việc cho AI để tránh lỗi Context Window

**Mục đích:** Hướng dẫn chi tiết cách sử dụng 3 file tài liệu (`Execution_Plan`, `Specification`, `Timeline`) để chỉ đạo các AI Agent (Claude, Cursor, ChatGPT, CodeX...) code dự án một cách hoàn hảo, không bị tràn bộ nhớ hay "ảo giác" (hallucination).

---

### 1. NGUYÊN TẮC SỐNG CÒN (KHÔNG ĐƯỢC VI PHẠM)

1. **KHÔNG BAO GIỜ bảo AI "Hãy code toàn bộ app này đi".** Nó sẽ sinh ra mã rác, thiếu logic, mất cấu trúc và bị kiệt sức (hết token/context window).
2. **Luôn đi theo `HairFit_AI_Timeline.md`.** Timeline chính là kịch bản bẻ nhỏ (Task breakdown) hoàn hảo. Hãy giao việc cho AI theo từng gạch đầu dòng trong Timeline.
3. **Mỗi khi làm xong 1 module lớn (ví dụ: xong Tuần 1, Tuần 2), HÃY TẠO PHIÊN CHAT MỚI.** Khi đoạn chat quá dài, AI sẽ "nhớ nhớ quên quên" và phá hỏng các file đã code. Tạo chat mới giúp "làm mới" bộ não của AI.

---

### 2. QUY TRÌNH GIAO VIỆC (3 BƯỚC CHUẨN)

#### Bước 1: Khởi tạo ngữ cảnh (Ở mỗi phiên chat mới)
Mở một cửa sổ chat mới, đính kèm 3 file:
- `HairFit_AI_Execution_Plan.md`
- `HairFit_AI_Specification.md`
- `HairFit_AI_Timeline.md`

**Sử dụng Prompt (câu lệnh) khởi tạo sau:**
> "Tôi đang xây dựng ứng dụng HairFit AI. Hãy đọc kỹ 3 file đính kèm. 
> File Execution_Plan chứa cấu trúc thư mục, tech stack và quy tắc code. 
> File Specification chứa logic nghiệp vụ và schema database. 
> File Timeline chứa tiến độ.
> 
> Hãy đóng vai trò là Senior Flutter Developer. Nhiệm vụ của bạn bây giờ CHỈ LÀ đọc, hiểu và phản hồi: 'Tôi đã hiểu rõ toàn bộ kiến trúc và quy ước của dự án, hãy giao task đầu tiên cho tôi'. Tuyệt đối CHƯA code gì cả."

#### Bước 2: Giao việc "Cuốn Chiếu" theo Task (Iterative Prompting)
Mở file `Timeline.md`, copy từng dòng task để giao cho AI. Giao tối đa 2-3 task nhỏ mỗi lần.

**Ví dụ Prompt chuẩn (Giao task UI/Setup cơ bản):**
> "Chúng ta bắt đầu Tuần 1. Hãy làm cho tôi các task sau dựa vào cấu trúc thư mục trong Execution_Plan:
> - Task 1.4: Tạo file core/constants/ (colors, text styles, dimensions, business constants).
> - Task 1.5: Tạo app_theme.dart (ThemeData).
> Hãy code thật hoàn chỉnh, tuân thủ đúng Design System (bảng màu và font Be Vietnam Pro)."

**Ví dụ Prompt chuẩn (Khi làm tính năng khó như Đặt Lịch):**
> "Bây giờ làm Task 4.1: Tạo `slot_service.dart`.
> Hãy mở file Execution_Plan, phần 6.1 (Sinh Slot Trống). Đọc kỹ logic 4 bước ở đó và code đúng y như vậy.
> Sau khi code xong, hãy tự review lại xem code của bạn đã xử lý trường hợp 'ngày nghỉ' (exceptions) trong schema BarberProfile chưa."

#### Bước 3: Reset Context (Cắt cầu dao khi quá tải)
Dấu hiệu AI đang bị đầy bộ nhớ (Context Window Limit):
- AI bắt đầu quên cấu trúc thư mục (đặt nhầm file, sai đường dẫn).
- Code sinh ra bị cắt ngang giữa chừng.
- AI tự ý bịa ra các field không có trong Schema (ví dụ: tự thêm field `phoneNumber`).

**Cách xử lý lập tức:**
1. Copy lưu lại các file đã code tốt. Commit vào Git.
2. Mở một **New Chat**.
3. Lặp lại **Bước 1** (Nạp lại 3 file `md`).
4. Thêm 1 câu nối tiếp: *"Chúng ta đã code xong đến hết Tuần 2. Dưới đây là code hiện tại của file `X` (nếu cần). Bây giờ chúng ta tiếp tục làm Tuần 3, bắt đầu từ Task 3.1..."*

---

### 3. CÁC MẸO XỬ LÝ LỖI (DEBUG) CÙNG AI

**❌ Không nên nói:** *"Code chạy bị lỗi rồi, sửa đi."*
**✅ Nên nói (Đưa Context + Log):** 
> "Khi tôi chạy hàm `createBooking`, console báo lỗi: `[paste_dòng_log_lỗi_vào_đây]`. 
> Hãy kiểm tra lại file `booking_repository.dart`. Nhớ lưu ý phần 6.2 trong Execution_Plan về Transaction chống trùng slot. Phân tích nguyên nhân và sửa lại hàm đó cho tôi."

**❌ Không nên nói:** *"Màn hình này xấu quá."*
**✅ Nên nói (Đưa tiêu chuẩn):**
> "File `login_screen.dart` bạn viết bị sát lề quá. Hãy sửa lại, bọc nội dung bằng Padding và sử dụng `AppDimensions.lg` từ file constants mà chúng ta đã định nghĩa. Đổi màu nút bấm thành màu `AppColors.accent` để nổi bật hơn."

---

### TÓM LẠI: VÒNG LẶP THÀNH CÔNG CHO BẠN
1. Mở New Chat → Nạp 3 file.
2. Mở `Timeline.md` → Copy Task giao cho AI.
3. Code xong → Chạy thử máy ảo/máy thật.
4. Lỗi → Copy Error Log đưa AI sửa.
5. Code chạy ổn định → Commit Git.
6. Chuyển sang tính năng (Tuần) mới → Quay lại bước 1.

---

### 4. NHỮNG RÀO CẢN KHIẾN AI CODE LỖI VÀ GIẢI PHÁP PHÒNG TRÁNH (QUAN TRỌNG)

Để giảm thiểu tối đa tỷ lệ lỗi app (bug) khi AI code, bạn cần chủ động áp dụng các giải pháp ép buộc (forcing constraints) sau đây trong quá trình ra lệnh:

#### 4.1. Lỗi "Ảo giác" về phiên bản thư viện (Dùng code cũ)
- **Rào cản:** AI dùng các hàm đã bị loại bỏ (deprecated) của Flutter hoặc Firebase.
- **Giải pháp:** 
  - Ngay trong câu prompt đầu tiên khi làm tính năng mới, hãy gắn thêm: *"Lưu ý sử dụng cú pháp Flutter 3.x và Riverpod 2.x mới nhất. Không dùng StateNotifier, hãy dùng Notifier/AsyncNotifier."*
  - Nếu Editor (VS Code/Android Studio) báo gạch chân vàng/đỏ, copy nguyên dòng cảnh báo đó đưa lại cho AI để ép nó update cú pháp.

#### 4.2. Lỗi cấu hình Native (Android, Gradle, Permissions)
- **Rào cản:** AI chỉ lo viết code Dart mà quên/viết sai cấu hình `build.gradle` hoặc `AndroidManifest.xml` (rất dễ xảy ra khi cài Firebase, ML Kit, Camera).
- **Giải pháp:** 
  - Khi đến các task setup thư viện (Tuần 1, Tuần 3, Tuần 5), hãy ra lệnh: *"Hãy hướng dẫn tôi TỪNG BƯỚC để cấu hình file `android/app/build.gradle` và `AndroidManifest.xml`. Tôi cần copy đoạn code nào, đặt ở đâu?"*
  - Luôn luôn gõ lệnh `flutter clean` rồi `flutter run` lại từ đầu ngay sau khi đụng vào các file Native này. Không dùng Hot Reload.

#### 4.3. Bệnh "Lười biếng" của AI (Viết tắt, bỏ sót logic)
- **Rào cản:** AI tự ý thêm comment `// ... thêm code ở đây` thay vì viết code hoàn chỉnh.
- **Giải pháp:** 
  - Gắn "câu thần chú" này vào cuối prompt khi giao việc khó: *"YÊU CẦU: Viết ra TẤT CẢ code hoàn chỉnh 100%, tuyệt đối không được viết tắt, không dùng comment //... để bỏ qua logic."*
  - Rà soát lại code AI trả về, nếu thấy lười biếng, bắt nó làm lại (Regenerate).

#### 4.4. Code Camera/ML Kit bị crash trên thiết bị thật
- **Rào cản:** AI viết code xử lý khung hình Camera truyền vào ML Kit theo lý thuyết. Khi chạy trên điện thoại thật dễ bị giật, sai định dạng ảnh hoặc văng app (crash).
- **Giải pháp:** 
  - Bắt AI viết log: *"Hãy thêm try-catch và dùng `debugPrint` ở từng bước xử lý ảnh để tôi dễ debug."*
  - **Bắt buộc** test tính năng chụp ảnh trên ĐIỆN THOẠI THẬT. Nếu app bị văng (crash), copy toàn bộ đoạn **StackTrace (dòng lỗi màu đỏ dài dằng dặc trong console)** đưa cho AI, nó sẽ tìm ra ngay biến số nào bị `null` hoặc sai format.

#### 4.5. Lỗi tràn màn hình (RenderFlex Overflow)
- **Rào cản:** AI thiết kế UI cứng nhắc, chạy trên máy nhỏ hoặc khi bàn phím ảo hiện lên sẽ bị lỗi sọc vàng đen che màn hình.
- **Giải pháp:** 
  - Ép khuôn UI: *"Mọi màn hình có ô nhập text (TextField) phải được bọc trong `SingleChildScrollView`."*
  - *"Không fix cứng chiều cao (height) bằng các con số cố định, hãy ưu tiên dùng Padding, Expanded hoặc Flexible để giao diện tự co giãn."*
