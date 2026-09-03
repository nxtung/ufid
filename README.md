# UFID (User Follow ID)

Thư viện Flutter Plugin định danh thiết bị bền vững và phát hiện cài đặt lại (Re-install Detection) cho Android & iOS.

> 📄 **Xem tài liệu chi tiết về mục tiêu dự án:** [PROJECT_GOALS.md](file:///Users/tungnx/Documents/dgx/ufid/PROJECT_GOALS.md)

---

## Tính Năng Cốt Lõi
- **Android ID Native (Deep Settings API):** Lấy Android ID trực tiếp qua API sâu trong `android.provider.Settings` / `ContentResolver` IPC Call (hoàn toàn không dùng `PackageManager`).
- **iOS Keychain Native:** Tự động sinh và lưu trữ key UUID an toàn trong iOS Keychain (`Security.framework`), dữ liệu không bị xóa khi người dùng gỡ app.
- **Phát hiện Re-install:** Nhận biết chính xác người dùng đang mở app lần đầu (First-time install) hay là cài đặt lại sau khi đã gỡ bỏ (Re-install).
- **API Flutter Tinh Gọn:** Dễ dàng tích hợp vào bất kỳ dự án Flutter nào với hàm `Ufid.getUFID()` và `Ufid.isReinstalled()`.
