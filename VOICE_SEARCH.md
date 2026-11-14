# HƯỚNG DẪN ĐIỀU KHIỂN & TÌM KIẾM GIỌNG NÓI (VOICE CONTROL ENGINE) — TV LAUNCHER

Tài liệu này mô tả chi tiết kiến trúc kỹ thuật, thuật toán xử lý và hướng dẫn cú pháp câu lệnh điều khiển bằng giọng nói trên TV Launcher (Android TV 11 - ROM Xiaomi MiTV).

---

## 1. Kiến Trúc Hoạt Động (Voice Engine Pipeline)

Hệ thống giọng nói hoạt động theo mô hình luồng thời gian thực không độ trễ (Real-time Pipeline) kết hợp giữa hệ điều hành Android TV, trợ năng Accessibility và Launcher:

```
[Remote Bluetooth Mic]
        │
        ▼ (Audio Stream)
[Google Katniss / Assistant STT] ──► Chuyển giọng nói thành văn bản thời gian thực
        │
        ▼ (Accessibility Event: TYPE_VIEW_TEXT_CHANGED)
[VoiceAccessibilityService] ─────► Trích xuất chuỗi văn bản (getKatnissSpokenText)
        │
        ▼ (HomeActivity.handleVoiceQuery)
 ┌────────────────────────────────────────────────────────┐
 │ BỘ ĐIỀU PHỐI GIỌNG NÓI 3 TẦNG (VOICE DISPATCHER ENGINE) │
 ├────────────────────────────────────────────────────────┤
 │ 1. ƯU TIÊN SỐ 1: Bắt kênh truyền hình VTV (1-9, VTV Go)│
 │ 2. BỘ LỌC NỘI DUNG: Nhận diện nhạc, phim, karaoke...   │
 │ 3. ƯU TIÊN SỐ 2: Khởi chạy App (3 Tầng Fuzzy Matching) │
 └────────────────────────────────────────────────────────┘
        │
   ┌────┴──────────────────────────────┐
   ▼ (Khớp Kênh / App)                 ▼ (Không khớp lệnh / Tìm video)
[Mở Deeplink VTV Go / Mở App]     [Chuyển giao Katniss / YouTube Search]
```

### Các thành phần cốt lõi trong mã nguồn:
1. [**`VoiceAccessibilityService`**](file:///e:/Antigravity_Code/CODE_LAUNCHER_TV/tv_launcher/src/vn/herotran/launcher/VoiceAccessibilityService.java):
   - Đón bắt phím Mic remote (`KEYCODE_VOICE_ASSIST`, `KEYCODE_SEARCH`, `KEYCODE_ASSIST`, `KEYCODE_UNKNOWN`).
   - Khởi chạy Katniss (`startVoiceSearch`). Khi nhả phím mic (`ACTION_UP`), tự động thực hiện thao tác hoàn tất thu âm (`finishAndSubmitSearch`) qua View click hoặc tap cử chỉ fallback.
   - Giám sát văn bản STT hiển thị trên màn hình Katniss để đánh chặn tức thì nếu người dùng phát lệnh điều khiển.
2. [**`HomeActivity.handleVoiceQuery`**](file:///e:/Antigravity_Code/CODE_LAUNCHER_TV/tv_launcher/src/vn/herotran/launcher/HomeActivity.java):
   - Chuẩn hóa văn bản tiếng Việt ([`normalize`](file:///e:/Antigravity_Code/CODE_LAUNCHER_TV/tv_launcher/src/vn/herotran/launcher/HomeActivity.java#L819)): loại bỏ dấu thanh điệu, dấu câu, chuẩn hóa chữ đ/d.
   - Bóc tách tiền tố lệnh mở rộng ([`stripVoiceCommandPrefix`](file:///e:/Antigravity_Code/CODE_LAUNCHER_TV/tv_launcher/src/vn/herotran/launcher/HomeActivity.java#L846)).
   - Phân loại ngữ nghĩa: Tự động tách biệt giữa **lệnh điều khiển mở app/kênh** và **truy vấn tìm kiếm nội dung**.
3. [**`VoiceHelper`**](file:///e:/Antigravity_Code/CODE_LAUNCHER_TV/tv_launcher/src/vn/herotran/launcher/VoiceHelper.java) & [**`VoiceLangFixer`**](file:///e:/Antigravity_Code/CODE_LAUNCHER_TV/tv_launcher/src/vn/herotran/launcher/VoiceLangFixer.java):
   - Cố định dịch vụ Voice Assistant và đảm bảo Katniss luôn nhận diện chuẩn tiếng Việt (`vi-VN`).

---

## 2. Các Cải Tiến Lớn Trong Bộ Nhận Diện Giọng Nói (v1.6)

> [!TIP]
> **Điểm mới vượt trội:** Người dùng **KHÔNG CÒN BẮT BUỘC** phải nói từ *"Mở/Bật"* mới kích hoạt được ứng dụng hoặc kênh truyền hình!

### 2.1. Tự do câu lệnh (Prefix-Free Command)
- Trước đây: Bắt buộc phải nói *"Mở YouTube"*, *"Bật VTV1"*. Nếu chỉ nói *"YouTube"* hay *"VTV3"*, hệ thống sẽ bỏ qua và đẩy sang tìm kiếm web.
- Bây giờ: Bạn có thể nói tự nhiên:
  - Chỉ cần nói: *"VTV1"*, *"Kênh 3"*, *"YouTube"*, *"TizenTube"*, *"Netflix"*, *"FPT Play"* $\rightarrow$ Launcher tự động nhận diện và mở ngay lập tức!
  - Vẫn hỗ trợ trọn vẹn mọi tiền tố điều khiển quen thuộc: *"Mở"*, *"Bật"*, *"Vào"*, *"Xem"*, *"Chạy"*, *"Chuyển sang"*, *"Chuyển đến"*, *"Chuyển qua"*, *"Chuyển kênh"*, *"Cho xem"*, *"Cho tôi xem"*, *"Mở app"*, *"Mở ứng dụng"*.

### 2.2. Bộ lọc phân tách nội dung thông minh (`isContentSearchQuery`)
Để tránh việc người dùng tìm kiếm video YouTube bị nhận nhầm thành mở app, hệ thống áp dụng bộ lọc từ khóa nội dung:
- Khi câu nói bắt đầu bằng: `"bài "`, `"bài hát "`, `"video "`, `"nhạc "`, `"phim "`, `"karaoke "`, `"clip "`, `"remix "`, `"hài "`, `"tin tức "`, `"kênh youtube "`...
- Launcher sẽ nhận biết ngay đây là **truy vấn nội dung** và chủ động nhường quyền cho Google Katniss / YouTube tìm kiếm chính xác, không can thiệp mở app.

### 2.3. Thuật toán Fuzzy Matching 3 Tầng Cho Ứng Dụng
Hệ thống kết hợp 3 tầng so khớp để nhận diện tên app một cách chính xác nhất:
1. **Tầng 1 - Bảng âm vị tiếng Việt (Phonics Alias Table):**
   - Ánh xạ trực tiếp các biến thể phát âm tiếng bồi, từ viết tắt và nhận diện sai của STT (ví dụ: *"du túp"*, *"u tub"*, *"tai zen"*, *"net phờ lích"*, *"ai ci di"*, *"ba sáu không"*...).
2. **Tầng 2 - Khớp chuỗi con (Substring Matching):**
   - Chấm điểm ưu tiên từ 0.85 đến 0.95 dựa trên tỷ lệ độ dài chuỗi con so với tên ứng dụng gốc.
3. **Tầng 3 - Khoảng cách Levenshtein (Fuzzy Edit Distance):**
   - Thuật toán Levenshtein được tối ưu bộ nhớ 1D DP $O(\min(M, N))$, không gây áp lực RAM trên TV.
   - Áp dụng ngưỡng tương quan linh hoạt:
     - Khi có tiền tố lệnh (*"Mở..."*): Ngưỡng tin cậy **0.65** (linh hoạt nhận diện cả khi phát âm chưa chuẩn).
     - Khi không có tiền tố lệnh: Ngưỡng tin cậy **0.75** kèm giới hạn độ dài câu $\le 3$ từ để loại trừ triệt để câu tìm kiếm video thông thường.

---

## 3. Bảng Cú Pháp Mở Kênh Truyền Hình VTV (Qua VTV Go)

Hệ thống tích hợp mở trực tiếp luồng truyền hình quốc gia VTV thông qua Deeplink VTV Go (`vtvgo://play?channelId=...`).

### 3.1. Các dạng câu lệnh được hỗ trợ
Người dùng có thể đọc theo bất kỳ phong cách nào dưới đây:
- **Đọc số kênh:** *"Kênh 1"*, *"Kênh 3"*, *"Mở kênh sáu"*, *"Chuyển sang kênh 9"*.
- **Đọc tên đài + số:** *"VTV1"*, *"VTV 3"*, *"Mở VTV hai"*, *"Xem VTV3 HD"*, *"VTV kênh 5"*.
- **Kênh đặc thù:** *"VTV Cần Thơ"*, *"Xem VTV Cần Thơ HD"* $\rightarrow$ Tự động mở kênh VTV6.

### 3.2. Bảng ánh xạ kênh VTV1 - VTV9

| Kênh phát | Cú pháp ví dụ | Kênh ID VTV Go | Thể loại |
| :--- | :--- | :--- | :--- |
| **VTV1** | *"VTV1"*, *"Kênh 1"*, *"Mở VTV một"* | `channelId=1` | Thời sự - Chính luận |
| **VTV2** | *"VTV2"*, *"Kênh 2"*, *"Xem VTV hai"* | `channelId=2` | Khoa học & Giáo dục |
| **VTV3** | *"VTV3"*, *"Kênh 3"*, *"Bật VTV ba HD"* | `channelId=3` | Thể thao & Giải trí |
| **VTV4** | *"VTV4"*, *"Kênh 4"*, *"Kênh tư"*, *"Mở VTV bốn"* | `channelId=4` | Truyền hình Đối ngoại |
| **VTV5** | *"VTV5"*, *"Kênh 5"*, *"Xem VTV năm"* | `channelId=5` | Tiếng Dân tộc thiểu số |
| **VTV6 / Cần Thơ**| *"VTV6"*, *"Kênh 6"*, *"VTV Cần Thơ"*, *"VTV sáu"* | `channelId=13` | Kênh VTV Cần Thơ / Thể thao |
| **VTV7** | *"VTV7"*, *"Kênh 7"*, *"Bật VTV bảy"* | `channelId=27` | Truyền hình Giáo dục |
| **VTV8** | *"VTV8"*, *"Kênh 8"*, *"Mở VTV tám"* | `channelId=36` | Khu vực Miền Trung - Tây Nguyên |
| **VTV9** | *"VTV9"*, *"Kênh 9"*, *"Xem VTV chín"* | `channelId=39` | Khu vực Nam Bộ |

*(Hệ thống đã tự động lọc bỏ dấu chấm và gạch nối như `V.T.V 1` hay `V-T-V 3`).*

---

## 4. Bảng Cú Pháp Mở Nhanh Ứng Dụng (App Launching)

Người dùng có thể nói trực tiếp tên app hoặc kèm tiền tố *"Mở / Bật / Vào / Chạy"*:

| Ứng dụng | Cách phát âm được hỗ trợ | Cơ chế & Package kích hoạt |
| :--- | :--- | :--- |
| **YouTube / TizenTube** | *"YouTube"*, *"TizenTube"*, *"Tizen"*, *"Du túp"*, *"Du tub"*, *"Ti zen"*, *"Tai zen"*, *"Iutub"*, *"U túp"* | Ưu tiên mở bản mod **TizenTube** (`io.gh.reisxd.tizentube.cobalt`). Nếu không có sẽ mở YouTube gốc (`com.google.android.youtube.tv`). |
| **SmartTube** | *"SmartTube"*, *"Smart Tube"*, *"Xmát túp"*, *"Smat tub"* | `com.teamsmart.videomanager.tv` |
| **Netflix** | *"Netflix"*, *"Net phờ lích"*, *"Net phich"*, *"Net flix"* | `com.netflix.ninja` |
| **VTV Go** | *"VTV Go"*, *"VTV"*, *"Vê tê vê"* | `vn.vtv.vtvgotv` (Trang chủ VTV Go) |
| **FPT Play** | *"FPT Play"*, *"FPT"*, *"Ép pê tê"*, *"Ép pi ti"* | `net.fptplay.ottbox` / `com.fpt.play` |
| **TV360** | *"TV360"*, *"TV 360"*, *"Viettel TV"*, *"Ba sáu không"* | `com.viettel.tv360.tv` |
| **VieON** | *"VieON"*, *"Vi e on"*, *"Vi on"*, *"Vai on"* | `com.vieon.tv` |
| **iQIYI** | *"iQIYI"*, *"Ai ci di"*, *"Ai ki di"*, *"Ai ky di"* | `com.iqiyi.i18n.tv` |
| **Quản lý File** | *"File"*, *"Tập tin"*, *"AnExplorer"*, *"Quản lý tập tin"* | `dev.dworks.apps.anexplorer` |
| **Kho Ứng Dụng** | *"DL Store"*, *"Cửa hàng"*, *"Store"* | `com.downloader.store` |
| **Cài đặt Hệ thống** | *"Cài đặt"*, *"Thiết lập"*, *"Settings"*, *"Cài đặt TV"* | `com.xiaomi.mitv.settings` |
| **Mọi app khác** | Đọc tên app hiển thị trên màn hình (vd: *"VLC"*, *"Monster"*...) | So khớp tự động qua danh sách ứng dụng đã cài đặt trên TV (Levenshtein Distance). |

---

## 5. Tìm Kiếm Video & Nội Dung Trực Tuyến

Khi câu nói không khớp với kênh truyền hình hay ứng dụng, câu lệnh sẽ tự động được gửi tới công cụ tìm kiếm:

1. **Tìm kiếm Video / Nhạc trên YouTube:**
   - Cú pháp: *"Tìm kiếm [tên video]"*, *"Nhạc [thể loại]"*, *"Karaoke [tên bài hát]"*, *"Phim [tên phim]"*...
   - Ví dụ:
     - *"Karaoke Hoa Nở Về Đêm tone nam"*
     - *"Nhạc trẻ remix sôi động"*
     - *"Video 4K thiên nhiên OLED"*
     - *"Hài Hoài Linh Chí Tài"*
   - Kết quả: Hệ thống tự động chuyển tiếp tới YouTube (hoặc TizenTube) để hiển thị danh sách video hoặc phát trực tiếp.
2. **Tìm kiếm thời tiết, thông tin tổng hợp:**
   - Bấm mic và hỏi: *"Thời tiết hôm nay thế nào?"*, *"Giá vàng hôm nay"*, *"Mấy giờ rồi?"* $\rightarrow$ Google Assistant trả lời trực quan bằng giọng nói và hiển thị thẻ thông tin trên TV.

---

## 6. Mẹo Sử Dụng Cho Độ Nhạy Cao Nhất

1. **Thao tác bấm nút Mic:**
   - Bấm **1 lần dứt khoát** vào nút Mic trên Remote Xiaomi MiTV.
   - Nhìn dải màu Google Assistant xuất hiện ở cạnh dưới màn hình rồi bắt đầu nói.
2. **Khoảng cách thu âm lý tưởng:**
   - Đặt đầu remote cách miệng từ **10 - 20 cm**.
   - Nói với âm lượng vừa phải, rõ ràng, không cần hét lớn.
3. **Phát âm liền mạch:**
   - Tránh ngập ngừng ở giữa câu nói (ví dụ thay vì đọc *"Mở... [nghỉ 1 giây]... VTV3"*, hãy đọc dứt khoát *"VTV3"* hoặc *"Kênh 3"*).
4. **Tận dụng cú pháp ngắn:**
   - Càng nói ngắn gọn (*"VTV1"*, *"YouTube"*, *"FPT"*, *"Kênh 3"*), hệ thống xử lý càng nhanh và độ chính xác càng tiệm cận 100%.

---

## 7. Xử Lý Các Tình Huống Thường Gặp

| Vấn đề | Nguyên nhân | Giải pháp |
| :--- | :--- | :--- |
| **Bấm Mic nhưng TV không hiện trợ lý Katniss** | Dịch vụ Trợ Năng bị hệ thống đưa vào danh sách chờ hoặc mất kết nối remote | Khởi động lại remote bằng cách tháo lắp pin; hoặc vào Cài đặt kiểm tra kết nối Bluetooth. Launcher đã có cơ chế tự động khôi phục Accessibility Service định kỳ. |
| **Muốn xem VTV3 nhưng bị mở trang chủ VTV Go** | Đọc ngắt quãng khiến Katniss gửi chữ "VTV" trước khi người dùng kịp đọc số kênh | Chuyển sang đọc ngắn gọn: **"Kênh 3"** hoặc nói liền hơi: **"VTV ba"**. |
| **Nói "YouTube" nhưng TV không mở TizenTube** | Gói TizenTube chưa được cài đặt hoặc bị tắt quyền | Launcher sẽ tự động fallback sang YouTube gốc nếu máy chưa cài TizenTube Mod. Cài đặt lại `tizentube-cobalt-arm-mod.apk` để trải nghiệm không quảng cáo. |
| **Bị mở nhầm app khi đang tìm bài hát** | Tên bài hát trùng hoặc chứa tên một app | Thêm các từ chỉ định nội dung phía trước như: *"Bài hát..."*, *"Video..."*, *"Nhạc..."* để kích hoạt bộ lọc nội dung. |
