# Mục Tiêu Dự Án: Thư Viện Flutter UFID (User Follow ID)

## 1. Giới thiệu tổng quan (Overview)
**UFID (User Follow ID)** là một thư viện Flutter Plugin gọn nhẹ, độc lập, được thiết kế để các ứng dụng Flutter khác tích hợp vào dự án.

Mục tiêu cốt lõi của thư viện:
- **Định danh thiết bị duy nhất & bền vững (Persistent Device Identifier):** Sinh hoặc lấy mã định danh duy nhất cho thiết bị.
- **Phát hiện tái cài đặt (Re-install Detection):** Xác định chính xác ứng dụng đang được mở lần đầu tiên (First-time install) hay là vừa được cài đặt lại sau khi đã gỡ bỏ (Re-installed) trên cùng thiết bị.

---

## 2. Mục tiêu cốt lõi (Core Objectives)

### 2.1. Nhận diện thiết bị bền vững
- Cung cấp một mã định danh duy nhất (UFID) cho mỗi thiết bị di động.
- Mã định danh này không thay đổi ngay cả khi người dùng xóa ứng dụng và cài đặt lại.

### 2.2. Nhận biết trạng thái Re-install
- Phân biệt rõ 2 trạng thái khi app khởi chạy:
  1. **First Install:** Thiết bị chưa từng cài đặt ứng dụng này trước đây.
  2. **Re-install:** Ứng dụng đã từng được cài đặt trên thiết bị, sau đó bị xóa và nay được cài đặt lại.
- Tự động khôi phục lại UFID ban đầu đã cấp cho thiết bị ở lần cài đặt đầu tiên.

---

## 3. Kiến trúc & Giải pháp Kỹ thuật Native (Technical Architecture)

Thư viện sử dụng cơ chế **Flutter Platform Channel** (`MethodChannel`) giao tiếp trực tiếp với Native Code của Android và iOS.

```
+-------------------------------------------------------+
|                   Flutter Client App                  |
+-------------------------------------------------------+
                           |
                           v
+-------------------------------------------------------+
|                    UFID Flutter API                   |
|          Ufid.getUFID()  |  Ufid.isReinstalled()      |
+-------------------------------------------------------+
                           |
                 [MethodChannel: "ufid"]
                /                       \
               v                         v
+-----------------------------+ +-----------------------------+
|       Android (Native)      | |         iOS (Native)        |
|        Kotlin / Java        | |        Swift / Obj-C        |
|                             | |                             |
| - API sâu trong Settings    | | - iOS Keychain Services     |
|   (ContentResolver IPC Call | | - Lưu & đọc UUID an toàn    |
|   GET_secure ANDROID_ID)    | | - Không bị xóa khi gỡ app   |
| - KHÔNG dùng PackageManager | |                             |
+-----------------------------+ +-----------------------------+
```

### 3.1. Phía Android (Native Kotlin)
- **Tuyệt đối KHÔNG dùng `PackageManager`:**
  - Không truy vấn danh sách ứng dụng hay gói cài đặt.
  - Không vướng các rào cản về Package Visibility (Android 11+ / API 30+).
  - Không cần xin quyền nhạy cảm `QUERY_ALL_PACKAGES` trên Google Play.
- **Sử dụng API sâu trong `android.provider.Settings`:**
  - **Truy vấn sâu qua ContentResolver IPC Call:** Gọi trực tiếp IPC tới SettingsProvider, vượt qua tầng cache của ứng dụng:
    ```kotlin
    val bundle = context.contentResolver.call(
        Settings.Secure.CONTENT_URI,
        "GET_secure",
        Settings.Secure.ANDROID_ID,
        null
    )
    val androidId = bundle?.getString("value")
    ```
  - **Dự phòng qua Direct Query / Settings.Secure:**
    ```kotlin
    val androidId = Settings.Secure.getString(
        context.contentResolver,
        Settings.Secure.ANDROID_ID
    )
    ```
- **Xác định Re-install trên Android:**
  - Kết hợp `ANDROID_ID` thu được từ hệ thống với cờ lưu trữ cục bộ (SharedPreferences/Internal storage).
  - Nếu cờ cục bộ chưa có nhưng `ANDROID_ID` đã từng được ghi nhận trong lịch sử cài đặt -> xác định là **Re-install**.

### 3.2. Phía iOS (Native Swift)
- **Cơ chế iOS Keychain (`Security.framework`):**
  - Đặc tính quan trọng của iOS: Dữ liệu được lưu trong **Keychain sẽ KHÔNG bị xóa** khi người dùng gỡ bỏ ứng dụng.
- **Quy trình xử lý:**
  1. Khi ứng dụng khởi chạy, native code kiểm tra key định danh (ví dụ `UFID_DEVICE_KEY`) trong Keychain thông qua `SecItemCopyMatching`.
  2. **Nếu Key CHƯA tồn tại trong Keychain:**
     - Đây là lần cài đặt đầu tiên (**First-time install**).
     - Tạo một UUID mới (ví dụ: `UUID().uuidString`).
     - Lưu UUID này vào Keychain thông qua `SecItemAdd` với quyền truy cập bảo mật `kSecAttrAccessibleAfterFirstUnlock`.
     - Trả về UFID mới và đánh dấu trạng thái `isReinstalled = false`.
  3. **Nếu Key ĐÃ tồn tại trong Keychain:**
     - Đây là lần cài đặt lại (**Re-install**).
     - Đọc giá trị UUID đã lưu sẵn trong Keychain trả về.
     - Đánh dấu trạng thái `isReinstalled = true`.

---

## 4. Đặc tả API Flutter dự kiến (Dart Interface)

Giao diện API tinh gọn, tập trung hoàn toàn vào nhận diện thiết bị và trạng thái cài đặt:

```dart
class UfidResult {
  final String ufid;
  final bool isReinstalled;

  UfidResult({
    required this.ufid,
    required this.isReinstalled,
  });
}

abstract class Ufid {
  /// Lấy mã định danh duy nhất của thiết bị (UFID)
  /// - Android: Dựa trên Android ID lấy từ Settings.Secure qua deep API
  /// - iOS: Dựa trên UUID lưu trữ bền vững trong Keychain
  static Future<String> getUFID();

  /// Kiểm tra xem ứng dụng hiện tại có phải vừa được cài đặt lại hay không
  /// - Trả về `true` nếu thiết bị này đã từng cài app trước đó và vừa cài lại
  /// - Trả về `false` nếu đây là lần cài đặt đầu tiên
  static Future<bool> isReinstalled();

  /// Lấy đồng thời cả UFID và trạng thái Re-install trong một lần gọi
  static Future<UfidResult> getInfo();
}
```

---

## 5. Lộ trình triển khai (Project Roadmap)

- [ ] **Giai đoạn 1: Khởi tạo cấu trúc Flutter Plugin**
  - Tạo template plugin Flutter chuẩn (`ufid`).
  - Thiết lập thư mục `android`, `ios`, `lib`, và `example`.
- [ ] **Giai đoạn 2: Xây dựng Native Android**
  - Viết `MethodChannel` handler trên Android (Kotlin).
  - Triển khai logic gọi API sâu `android.provider.Settings` để lấy `ANDROID_ID`.
  - Triển khai cơ chế phát hiện Re-install trên Android.
- [ ] **Giai đoạn 3: Xây dựng Native iOS**
  - Viết `MethodChannel` handler trên iOS (Swift).
  - Viết module `KeychainHelper` an toàn để đọc, tạo và kiểm tra key trong Keychain.
  - Triển khai logic phát hiện Re-install trên iOS.
- [ ] **Giai đoạn 4: Hoàn thiện Dart API & Example App**
  - Xây dựng Dart wrapper class `Ufid`.
  - Viết ứng dụng mẫu (`example`) hiển thị trực quan: mã UFID, trạng thái First Install / Re-install.
  - Viết Unit Tests & Integration Tests.
- [ ] **Giai đoạn 5: Đóng gói & Tài liệu**
  - Hoàn thiện `README.md` và tài liệu hướng dẫn sử dụng.
  - Đảm bảo tuân thủ đầy đủ chính sách của Google Play & Apple App Store.
