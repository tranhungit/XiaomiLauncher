# HƯỚNG DẪN ĐIỀU KHIỂN & TÌM KIẾM GIỌNG NÓI (VOICE CONTROL ENGINE) — TV LAUNCHER

Tài liệu này mô tả chi tiết kiến trúc kỹ thuật, thuật toán xử lý và hướng dẫn cú pháp câu lệnh điều khiển bằng giọng nói trên TV Launcher (Android TV 11 - ROM Xiaomi MiTV, phiên bản hiện tại: **v5.5.55**).

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
 │ BỘ ĐIỀU PHỐI GIỌNG NÓI 4 TẦNG (VOICE DISPATCHER ENGINE) │
 ├────────────────────────────────────────────────────────┤
 │ 0. ƯU TIÊN SỐ 0: Cài đặt Hệ thống Xiaomi (Sound/Display/Net)│
 │ 1. ƯU TIÊN SỐ 1: Bắt kênh truyền hình VTV (12 kênh VTV)│
 │ 2. BỘ LỌC NỘI DUNG: Nhận diện nhạc, phim, karaoke...   │
 │ 3. ƯU TIÊN SỐ 2: Khởi chạy App (3 Tầng Fuzzy Matching) │
 └────────────────────────────────────────────────────────┘
        │
   ┌────┴──────────────────────────────┐
   ▼ (Khớp Cài đặt / Kênh / App)       ▼ (Không khớp lệnh / Tìm video)
[Mở Cài đặt / Kênh VTV / App]     [Mở Trang Kết quả Tìm kiếm YouTube]
                                  (Dừng chờ chọn, KHÔNG tự động phát)
```

## 2. Các Tính Năng & Cải Tiến Nổi Bật (v5.5.55)

> [!TIP]
> **Điểm mới vượt trội:**
> 1. Người dùng **KHÔNG CÒN BẮT BUỘC** phải nói từ *"Mở/Bật"* mới kích hoạt được ứng dụng hoặc kênh truyền hình!
> 2. Hỗ trợ điều khiển **Cài đặt Hệ thống Xiaomi** (Âm thanh, Hình ảnh, Mạng) hoàn toàn bằng giọng nói.
> 3. Tìm kiếm YouTube **hiển thị danh sách kết quả và dừng lại**, không tự phát làm phiền người dùng.

### 2.1. Tự do câu lệnh (Prefix-Free Command)
- Trước đây: Bắt buộc phải nói *"Mở YouTube"*, *"Bật VTV1"*. Nếu chỉ nói *"YouTube"* hay *"VTV3"*, hệ thống sẽ bỏ qua và đẩy sang tìm kiếm web.
- Bây giờ: Bạn có thể nói tự nhiên:
  - Chỉ cần nói: *"VTV1"*, *"Kênh 3"*, *"YouTube"*, *"TizenTube"*, *"Netflix"*, *"FPT Play"* $\rightarrow$ Launcher tự động nhận diện và mở ngay lập tức!
  - Vẫn hỗ trợ trọn vẹn mọi tiền tố điều khiển quen thuộc: *"Mở"*, *"Bật"*, *"Vào"*, *"Xem"*, *"Chạy"*, *"Chuyển sang"*, *"Khởi động"*.

### 2.2. Nhận diện giọng nói vùng miền & từ đồng âm
- Kênh truyền hình: *"Kênh một"*, *"Kênh ba"*, *"Kênh chín"*, *"VTV ba"*, *"VTV năm Tây Nguyên"*, *"VTV Cần Thơ"*.
- Tiếng Anh phiên âm Việt: *"Du túp"*, *"Iu túp"*, *"Ti zen"*, *"Tai zen"*, *"Net phờ lích"*, *"Ép pi ti"*, *"Vai on"*.

---

## 3. Điều Khiển Cài Đặt Hệ Thống Xiaomi (System Settings)

Hệ thống tích hợp đánh chặn sớm các câu lệnh điều khiển cài đặt Xiaomi để mở trực tiếp menu tương ứng:

| Mục Cài Đặt | Câu lệnh giọng nói hỗ trợ | Cơ chế kỹ thuật |
| :--- | :--- | :--- |
| **Cài đặt Âm thanh** | *"Cài đặt âm thanh"*, *"Mở cài đặt âm thanh"*, *"Thiết lập âm thanh"*, *"Chỉnh âm thanh"*, *"Sound settings"*, *"Sound setting"* | Gửi Broadcast `com.xiaomi.mitv.settings.sound_settings` $\rightarrow$ Mở popup Sound settings gốc của Xiaomi (Loa TV, Âm lượng phím, Hiệu ứng âm thanh...). |
| **Cài đặt Hình ảnh** | *"Cài đặt hình ảnh"*, *"Mở cài đặt hình ảnh"*, *"Thiết lập hình ảnh"*, *"Chỉnh hình ảnh"*, *"Display settings"*, *"Image settings"* | Gửi Broadcast `com.xiaomi.mitv.settings.display_settings` $\rightarrow$ Mở popup Image settings gốc của Xiaomi (Đèn nền động, Bảo vệ mắt, Nhiệt độ màu...). |
| **Cài đặt Mạng / Wi-Fi** | *"Cài đặt mạng"*, *"Mở cài đặt mạng"*, *"Cài đặt wifi"*, *"Mở wifi"*, *"Thiết lập mạng"*, *"Kết nối mạng"*, *"Network settings"*, *"Wifi settings"* | Khởi chạy Activity `com.xiaomi.mitv.settings/.entry.MainActivity` $\rightarrow$ Mở trang Connection settings và focus sẵn vào tab Network settings (Wi-Fi, Ethernet, Kiểm tra tốc độ mạng...). |

---

## 4. Điều Khiển Kênh Truyền Hình VTV

Hệ thống hỗ trợ cơ chế phát đa tầng thông minh:
1. **Tầng 1 (Ưu tiên số 1):** Mở trực tiếp kênh qua app **VTV Online** (`vn.vtv.vtvtivi`).
2. **Tầng 2:** Nếu chưa cài VTV Online, tự động fallback sang **VTV Go** (`vn.vtv.vtvgotv`).
3. **Tầng 3:** Nếu cả 2 app trên đều không có, mở kênh qua **FPT Play** (`net.fptplay.ottbox` / `com.fpt.play`).

| Kênh Truyền Hình | Các câu lệnh tương đương | Kênh số |
| :--- | :--- | :---: |
| **VTV1 HD** | *"VTV1"*, *"VTV 1"*, *"Kênh 1"*, *"Kênh một"*, *"Xem thời sự"* | 1 |
| **VTV2 HD** | *"VTV2"*, *"VTV 2"*, *"Kênh 2"*, *"Kênh hai"*, *"Khoa học giáo dục"* | 2 |
| **VTV3 HD** | *"VTV3"*, *"VTV 3"*, *"Kênh 3"*, *"Kênh ba"*, *"Giải trí"* | 3 |
| **VTV4 HD** | *"VTV4"*, *"VTV 4"*, *"Kênh 4"*, *"Kênh bốn"*, *"Đối ngoại"* | 4 |
| **VTV5 HD** | *"VTV5"*, *"VTV 5"*, *"Kênh 5"*, *"Kênh năm"*, *"Dân tộc"* | 5 |
| **VTV5 Tây Nam Bộ** | *"VTV5 Tây Nam Bộ"*, *"VTV5 Nam Bộ"*, *"VTV5 tnb"* | 6 |
| **VTV5 Tây Nguyên** | *"VTV5 Tây Nguyên"*, *"VTV5 tn"* | 7 |
| **VTV6 HD** | *"VTV6"*, *"VTV 6"*, *"Kênh 6"*, *"Kênh sáu"* | 8 |
| **VTV7 HD** | *"VTV7"*, *"VTV 7"*, *"Kênh 7"*, *"Kênh bảy"*, *"Giáo dục"* | 9 |
| **VTV8 HD** | *"VTV8"*, *"VTV 8"*, *"Kênh 8"*, *"Kênh tám"*, *"Miền Trung"* | 10 |
| **VTV9 HD** | *"VTV9"*, *"VTV 9"*, *"Kênh 9"*, *"Kênh chín"*, *"Nam Bộ"* | 11 |
| **VTV Cần Thơ (VTV10)** | *"VTV Cần Thơ"*, *"VTV10"*, *"VTV 10"*, *"Kênh 10"*, *"Kênh mười"* | 12 |

---

## 5. Khởi Chạy Nhanh Ứng Dụng (App Launching)

Người dùng có thể đọc tên ứng dụng trần hoặc đi kèm các tiền tố:

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
| **Cài đặt TV** | *"Cài đặt"*, *"Thiết lập"*, *"Settings"*, *"Cài đặt TV"* | `com.xiaomi.mitv.settings` |
| **Mọi app khác** | Đọc tên app hiển thị trên màn hình (vd: *"VLC"*, *"Monster"*...) | So khớp tự động qua danh sách ứng dụng đã cài đặt trên TV (Levenshtein Distance). |

---

## 6. Tìm Kiếm Video & Nội Dung (Tắt Auto-Play)

Khi câu nói không khớp với kênh truyền hình hay ứng dụng, câu lệnh sẽ tự động chuyển sang tìm kiếm video trên YouTube / TizenTube:

1. **Cơ chế tìm kiếm (Từ v5.5.53):**
   - **Tắt Auto-Play hoàn toàn:** Hệ thống **không tự động phát video ngay lập tức**.
   - **Mở trang kết quả tìm kiếm:** Kích hoạt intent `https://www.youtube.com/results?search_query=` kèm cờ `FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TOP`.
   - **Dừng chờ người dùng thao tác:** Cả YouTube TV và TizenTube Cobalt Mod đều hiển thị trọn vẹn danh sách kết quả, focus sẵn ở video đầu tiên để người dùng tự dùng D-Pad remote di chuyển và bấm OK để chọn xem.
2. **Các ví dụ tìm kiếm phổ biến:**
   - *"Nhạc trẻ remix sôi động"*
   - *"Karaoke Hoa Nở Về Đêm tone nam"*
   - *"Video 4K thiên nhiên OLED"*
   - *"Hài Hoài Linh Chí Tài"*
   - *"Phim hoạt hình thiếu nhi"*
3. **Tìm kiếm thông tin tổng hợp qua Google Assistant:**
   - Bấm mic và hỏi: *"Thời tiết hôm nay thế nào?"*, *"Giá vàng hôm nay"*, *"Mấy giờ rồi?"* $\rightarrow$ Google Assistant trả lời trực quan bằng giọng nói và hiển thị thẻ thông tin trên TV.

---

## 7. Mẹo Sử Dụng Cho Độ Nhạy Cao Nhất

1. **Thao tác bấm nút Mic:**
   - Bấm **1 lần dứt khoát** vào nút Mic trên Remote Xiaomi MiTV.
   - Nhìn dải màu Google Assistant xuất hiện ở cạnh dưới màn hình rồi bắt đầu nói.
2. **Khoảng cách thu âm lý tưởng:**
   - Đặt đầu remote cách miệng từ **10 - 20 cm**.
   - Nói với âm lượng vừa phải, rõ ràng, không cần hét lớn.
3. **Phát âm liền mạch:**
   - Tránh ngập ngừng ở giữa câu nói (ví dụ thay vì đọc *"Mở... [nghỉ 1 giây]... VTV3"*, hãy đọc dứt khoát *"VTV3"* hoặc *"Kênh 3"*).
4. **Tận dụng cú pháp ngắn:**
   - Càng nói ngắn gọn (*"VTV1"*, *"YouTube"*, *"FPT"*, *"Cài đặt âm thanh"*), hệ thống xử lý càng nhanh và độ chính xác càng tiệm cận 100%.

---

## 8. Xử Lý Các Tình Huống Thường Gặp

| Vấn đề | Nguyên nhân | Giải pháp |
| :--- | :--- | :--- |
| **Bấm Mic nhưng TV không hiện trợ lý Katniss** | Dịch vụ Trợ Năng bị hệ thống đưa vào danh sách chờ hoặc mất kết nối remote | Khởi động lại remote bằng cách tháo lắp pin; hoặc vào Cài đặt kiểm tra kết nối Bluetooth. Launcher đã có cơ chế tự động khôi phục Accessibility Service định kỳ. |
| **Muốn xem VTV3 nhưng bị mở trang chủ VTV Go** | Đọc ngắt quãng khiến Katniss gửi chữ "VTV" trước khi người dùng kịp đọc số kênh | Chuyển sang đọc ngắn gọn: **"Kênh 3"** hoặc nói liền hơi: **"VTV ba"**. |
| **Nói "YouTube" nhưng TV không mở TizenTube** | Gói TizenTube chưa được cài đặt hoặc bị tắt quyền | Launcher sẽ tự động fallback sang YouTube gốc nếu máy chưa cài TizenTube Mod. Cài đặt lại `tizentube-cobalt-arm-mod.apk` để trải nghiệm không quảng cáo. |
| **Bị mở nhầm app khi đang tìm bài hát** | Tên bài hát trùng hoặc chứa tên một app | Thêm các từ chỉ định nội dung phía trước như: *"Bài hát..."*, *"Video..."*, *"Nhạc..."* để kích hoạt bộ lọc nội dung. |
