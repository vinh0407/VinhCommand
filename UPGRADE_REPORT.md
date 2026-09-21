# Báo cáo nâng cấp VinhCommand

Ngày kiểm tra: 18/09/2026. Phạm vi: Flutter Windows + Kotlin Android. Nhánh TypeScript trong `vinhcommand/` được giữ nguyên.

## Ý tưởng và đánh giá

VinhCommand là trung tâm quản lý dự án và tác vụ AI trên máy Windows, với ứng dụng Android để xem trạng thái và gửi yêu cầu. Bản nguồn ban đầu có nhiều mô hình nghiệp vụ nhưng các repository không khớp interface, các màn hình còn giả lập và hai ứng dụng chưa có luồng kết nối hoàn chỉnh. Baseline Flutter: 490 diagnostics, gồm 203 lỗi biên dịch.

Bản nâng cấp tập trung vào một luồng dùng được: thêm workspace → quét dự án và Codex → tạo tác vụ → duyệt trên desktop → chạy Codex chỉ đọc → lưu kết quả. Android ghép đôi qua LAN, xem dự án/agent/tác vụ và gửi yêu cầu vào hàng chờ.

## Đã thay đổi

- Thay repository không tương thích bằng kho JSON lưu trên máy; ghi tuần tự qua file tạm, lưu workspace, project, task/log và tùy chọn. Dữ liệu ở thư mục application support của Windows (`vinhcommand-state.json`).
- Sửa discovery để nhận cả thư mục gốc, tránh trùng dự án khi quét lại, bỏ qua thư mục phụ thuộc/build và giới hạn độ sâu/số file khi nhận diện ngôn ngữ.
- Tìm Codex CLI thực tế, ưu tiên bản đi kèm ứng dụng Codex. CLI cũ trên PATH không tương thích cấu hình model của máy này; bản đi kèm đã chạy thành công, không thay cấu hình model toàn cục.
- Task runner thực thi process thật tại thư mục dự án, truyền prompt qua stdin, lưu stdout/stderr, mã thoát, giới hạn đầu ra và thời gian. Có duyệt/chạy/dừng, không dùng kết quả giả lập.
- Sửa terminal đọc/ghi process thật và cập nhật trạng thái thoát; dọn process/controller khi đóng. Rời trang Terminal sẽ kết thúc phiên đó.
- Sửa kiểm tra quyền đường dẫn tránh nhận nhầm thư mục có cùng tiền tố; thu hồi phiên khi emergency lock.
- Thêm API LAN tắt mặc định: mã ghép đôi 6 số hết hạn sau 5 phút, giới hạn thử mã, bearer token trong bộ nhớ hết hạn sau 1 giờ, thu hồi khi ngắt kết nối/tắt bridge.
- Android bỏ IP cố định và log nội dung mạng; cho nhập endpoint, dùng bearer token, đồng bộ Room mỗi 3 giây, giao diện Projects/Agents/Tasks hoạt động và xếp hàng tác vụ qua HTTP.
- Trợ năng: cỡ chữ tối thiểu 100–200%, tôn trọng cỡ chữ hệ điều hành lớn hơn, chế độ tương phản cao/giảm chuyển động, nhãn điều khiển, bố cục cuộn, điều hướng bàn phím và Ctrl+K/Ctrl+B/Ctrl+`.
- Thu gọn điều hướng vào các chức năng MVP đã nối dữ liệu. Những module nâng cao còn ở mã nguồn không được trình bày như tính năng đã hoàn thiện.

## Kết quả kiểm chứng

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| Flutter regression | 9 passed; 2 bài tích hợp tùy chọn được skip trong lượt mặc định | `vinhcommand_desktop/final-tests.txt` |
| Phân tích Dart | 0 error, 0 warning; còn 9 lint mức info trong module cũ | `vinhcommand_desktop/final-analysis.txt` |
| Lưu dữ liệu, shell thật, đường dẫn, discovery, task runner, HTTP auth | Đạt trong bộ regression | `vinhcommand_desktop/test/` |
| Trợ năng | Kiểm tra nhãn, điều hướng bằng phím, cửa sổ hẹp và chữ 200% đạt; chưa chứng nhận WCAG hay kiểm tra đầy đủ bằng screen reader | `test/accessibility_test.dart`, `test/widget_test.dart` |
| Codex thật | 1 passed; đọc token từ README fixture, tác vụ completed, nội dung file không đổi | `vinhcommand_desktop/live-ai-test-log.txt`, `live-ai-result.txt` |
| Android máy ảo | 1 passed: ghép đôi → đồng bộ dự án → gửi prompt → server xác nhận đúng 1 tác vụ QUEUED | `vinhcommand_desktop/companion-smoke-log.txt`, `vinhcommand-android/android-task-preview.png` |
| Android unit/build | 2 unit tests passed; debug APK build thành công | `vinhcommand-android/android-final-build.txt` |

Lượt emulator đầu hết timeout khi thao tác thủ công. Lượt chạy lại đã đạt, không bỏ qua assertion. AI được dùng để phân tích/sửa/điều khiển kiểm thử, và có riêng bài chạy Codex thật; kết quả được xác nhận bằng assertion và process exit, không chỉ dựa vào nhận xét của AI.

## Dùng thử

1. Giải nén toàn bộ gói Windows và chạy `vinhcommand_desktop.exe`; giữ DLL và thư mục data bên cạnh.
2. Vào Projects → thêm workspace → Scan. Vào Agents → Scan; cần Codex CLI đã đăng nhập để chạy tác vụ.
3. Vào Tasks → chọn project → nhập yêu cầu → xếp hàng → duyệt/chạy trên desktop → xem đầu ra.
4. Cài APK debug lên Android. Hai thiết bị cần cùng mạng LAN tin cậy.
5. Desktop Settings → Android companion → bật LAN. Nhập địa chỉ được hiển thị, Desktop ID và mã ghép đôi vào điện thoại. Nếu Windows hỏi firewall, chỉ cho phép mạng riêng mà bạn tin cậy.
6. Android → Open command center → Tasks → chọn project → nhập prompt → Queue task. Quay lại desktop để duyệt/chạy.

## Giới hạn và phần tiếp theo

- Đây là bản MVP dùng thử. HTTP LAN chưa mã hóa; chưa hỗ trợ truy cập Internet an toàn, TLS, đăng nhập nhiều người, QR pairing hoặc lưu token lâu dài.
- Chỉ chạy review bằng Codex ở sandbox read-only. Chưa bật tác vụ tự sửa code, autonomous loops, stream màn hình hay điều khiển chuột từ xa.
- Terminal dùng pipe, chưa có PTY/ConPTY cho ứng dụng toàn màn hình.
- Chưa tự phục hồi tác vụ đang chạy sau khi ứng dụng/máy bị tắt đột ngột; chưa quản lý đầy đủ process con và chưa có giao diện khôi phục file dữ liệu hỏng. Kho JSON phù hợp quy mô MVP, cần chuyển sang giao dịch DB khi tải lớn.
- Chưa kiểm tra trên điện thoại vật lý, nhiều phiên bản Windows hoặc toàn bộ các module cũ không nằm trong luồng MVP. UI hiện chủ yếu dùng tiếng Anh.
- Ưu tiên đợt tiếp: TLS + quản lý phiên/thiết bị, phục hồi trạng thái sau crash, ConPTY, test screen reader và tiếng Việt; sau đó mới mở quyền AI sửa code kèm diff/duyệt.

## Chạy lại kiểm tra

Tại thư mục gốc, chạy `./verify.ps1` với Flutter, Android SDK và JDK 17 được cấu hình. Gradle wrapper đã được thêm. Bài Codex thật tùy chọn: đặt `VINH_CODEX_CLI` thành đường dẫn CLI đã đăng nhập rồi chạy `flutter test --no-pub test/live_ai_test.dart` trong desktop; lượt này sử dụng hạn mức tài khoản.

Backups trước sửa: `backups/desktop-before-upgrade.zip` và `backups/android-before-upgrade.zip`. Không khởi tạo Git hay tạo commit vì thư mục hiện tại chưa có repository Git.

Windows Release build: thành công (64,9 giây); log: vinhcommand_desktop/final-windows-build.txt. Gói phát hành thử: releases/VinhCommand-Windows-x64.zip và releases/VinhCommand-Android-debug.apk; SHA256SUMS.txt đi kèm. Script verify.ps1 đã kiểm tra cú pháp; các lệnh kiểm thử/build đã được chạy riêng, chưa chạy lại toàn script qua wrapper mới tải.
