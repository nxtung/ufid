# UFID (User Follow ID)

Thư viện Flutter Plugin định danh thiết bị bền vững và phát hiện cài đặt lại (Re-install Detection) cho Android & iOS.

- 📖 **[Tài liệu đặc tả API chi tiết (API.md)](file:///Users/tungnx/Documents/dgx/ufid/API.md)**
- 🎯 **[Tài liệu mục tiêu & kiến trúc dự án (PROJECT_GOALS.md)](file:///Users/tungnx/Documents/dgx/ufid/PROJECT_GOALS.md)**
- 📜 **[Giấy phép bản quyền MIT (LICENSE)](file:///Users/tungnx/Documents/dgx/ufid/LICENSE)**

---

## Tính Năng Cốt Lõi
- **Android ID Native (Deep Settings API):** Lấy Android ID trực tiếp qua API sâu trong `android.provider.Settings` / `ContentResolver` IPC Call (hoàn toàn không dùng `PackageManager`).
- **iOS Keychain Native:** Tự động sinh và lưu trữ key UUID an toàn trong iOS Keychain (`Security.framework`), dữ liệu không bị xóa khi người dùng gỡ app.
- **Phát hiện Re-install:** Nhận biết chính xác người dùng đang mở app lần đầu (First-time install) hay là cài đặt lại sau khi đã gỡ bỏ (Re-install).
- **API Flutter Tinh Gọn:** Dễ dàng tích hợp vào bất kỳ dự án Flutter nào với các hàm tĩnh `Ufid.getUFID()`, `Ufid.isReinstalled()`, `Ufid.getInfo()`.

---

## Cài Đặt Nhanh

Thêm vào `pubspec.yaml`:
```yaml
dependencies:
  ufid:
    path: path/to/ufid
```

## Sử Dụng Cơ Bản

```dart
import 'package:ufid/ufid.dart';

// Lấy thông tin tổng hợp (UFID + trạng thái Re-install)
final info = await Ufid.getInfo();
print('Device UFID: ${info.ufid}');
print('Is Re-installed: ${info.isReinstalled}');

// Hoặc gọi riêng lẻ:
final String? ufid = await Ufid.getUFID();
final bool isReinstalled = await Ufid.isReinstalled();
```
