# Tài Liệu Hướng Dẫn & Đặc Tả API Thư Viện `ufid`

Thư viện **UFID (User Follow ID)** cung cấp giải pháp định danh thiết bị bền vững và phát hiện trạng thái cài đặt lại (Re-install Detection) cho các ứng dụng Flutter trên cả hai nền tảng Android và iOS.

---

## 1. Cài đặt & Tích hợp (Installation)

### 1.1. Khai báo dependency trong `pubspec.yaml`
Thêm thư viện vào dự án Flutter của bạn:

```yaml
dependencies:
  flutter:
    sdk: flutter
  ufid:
    # Nếu dùng từ local path hoặc git repo:
    path: ../ufid
    # hoặc:
    # git:
    #   url: https://github.com/your-org/ufid.git
    #   ref: main
```

Sau đó chạy lệnh:
```bash
flutter pub get
```

### 1.2. Cấu hình nền tảng (Platform Configuration)

- **Android:**
  - **Không yêu cầu bất kỳ quyền đặc biệt nào** trong `AndroidManifest.xml` (không cần `READ_PHONE_STATE`, không cần `QUERY_ALL_PACKAGES`).
  - **Không cần khai báo thẻ `<queries>`** do thư viện sử dụng API cấp sâu của `android.provider.Settings` thông qua `ContentResolver` IPC Call, hoàn toàn không phụ thuộc vào `PackageManager`.
- **iOS:**
  - Tự động tích hợp `Security.framework` cho Keychain.
  - Không yêu cầu quyền theo dõi người dùng (ATT - App Tracking Transparency) vì mã định danh được lưu trữ cục bộ trong Keychain nội bộ của ứng dụng nhằm mục đích nhận diện thiết bị và chống gian lận kỹ thuật.

---

## 2. Các Lớp & Đối Tượng Dữ Liệu (Classes & Models)

### `class UfidInfo`
Đối tượng chứa thông tin tổng hợp về định danh thiết bị và trạng thái cài đặt.

#### Các thuộc tính (Properties):
| Thuộc tính | Kiểu dữ liệu | Mô tả |
| :--- | :--- | :--- |
| `ufid` | `String` | Mã định danh duy nhất của thiết bị. Trên Android là `ANDROID_ID`, trên iOS là UUID lưu trong Keychain. |
| `isReinstalled` | `bool` | `true` nếu ứng dụng đã từng được cài đặt trên thiết bị này trước đó và vừa được cài đặt lại; `false` nếu là lần cài đặt đầu tiên. |

#### Các phương thức (Methods):
- `Map<String, dynamic> toMap()`: Chuyển đổi đối tượng sang `Map`.
- `factory UfidInfo.fromMap(Map<dynamic, dynamic> map)`: Khởi tạo đối tượng từ `Map`.
- `String toString()`: Chuỗi biểu diễn thông tin đối tượng.

---

## 3. Đặc Tả Chi Tiết Các API (`class Ufid`)

Tất cả các API được cung cấp dưới dạng các hàm tĩnh (**static methods**) trên lớp `Ufid`, rất thuận tiện để gọi từ bất kỳ đâu trong ứng dụng.

```dart
import 'package:ufid/ufid.dart';
```

---

### 3.1. `Ufid.getUFID()`

Lấy mã định danh duy nhất của thiết bị (UFID).

```dart
static Future<String?> getUFID()
```

#### Cơ chế hoạt động Native:
- **Android:** Gọi trực tiếp IPC tới hệ thống Android SettingsProvider thông qua `ContentResolver.call(Settings.Secure.CONTENT_URI, "GET_secure", Settings.Secure.ANDROID_ID, null)`. Giá trị trả về là chuỗi Hex 64-bit đại diện cho `ANDROID_ID`.
- **iOS:** Truy vấn trong iOS Keychain mục lưu trữ `kSecClassGenericPassword`. Nếu chưa có (lần đầu cài đặt), tự động sinh chuỗi UUID v4 mới và lưu trữ an toàn vào Keychain. Giá trị này không bị xóa khi người dùng gỡ bỏ app.

#### Giá trị trả về:
- `Future<String?>`: Chuỗi mã định danh duy nhất (ví dụ: `9774d56d682e549c` trên Android hoặc `e4eaaaf2-d142-11e1-b3e4-080027620cdd` trên iOS). Trả về `null` nếu xảy ra lỗi phần cứng/hệ điều hành hiếm gặp.

#### Ví dụ sử dụng:
```dart
final String? ufid = await Ufid.getUFID();
print('Device UFID: $ufid');
```

---

### 3.2. `Ufid.isReinstalled()`

Kiểm tra xem phiên bản ứng dụng hiện tại có phải được cài đặt lại sau khi đã gỡ bỏ hay không.

```dart
static Future<bool> isReinstalled()
```

#### Cơ chế hoạt động Native:
- **Android:** Đối chiếu giữa cờ lưu trữ phiên cài đặt cục bộ và cờ lưu trữ đồng bộ trạng thái cài đặt trước đó.
- **iOS:** Đối chiếu trạng thái lưu trữ giữa **iOS Keychain** và **UserDefaults**:
  - Khi gỡ app: `UserDefaults` bị xóa hoàn toàn, nhưng `Keychain` thì còn nguyên.
  - Khi mở app lại: Thấy `Keychain` đã có key từ trước nhưng `UserDefaults` chưa có dấu hiệu khởi chạy $\rightarrow$ Xác định chính xác là **Re-installed** (`true`).
  - Lần đầu tiên mở app: Cả 2 đều chưa có $\rightarrow$ Xác định là **First-time install** (`false`).

#### Giá trị trả về:
- `Future<bool>`:
  - `true`: Ứng dụng đã từng tồn tại trên thiết bị này và vừa được cài đặt lại.
  - `false`: Đây là lần đầu tiên ứng dụng được cài đặt trên thiết bị này.

#### Ví dụ sử dụng:
```dart
final bool isReinstalled = await Ufid.isReinstalled();
if (isReinstalled) {
  print('Chào mừng người dùng quay lại (Re-installed)!');
} else {
  print('Chào mừng người dùng mới (First-time install)!');
}
```

---

### 3.3. `Ufid.getInfo()`

Lấy đồng thời cả mã `ufid` và trạng thái `isReinstalled` chỉ trong **một lần gọi Platform Channel duy nhất**, giúp tối ưu hiệu năng và tránh gọi native nhiều lần.

```dart
static Future<UfidInfo> getInfo()
```

#### Giá trị trả về:
- `Future<UfidInfo>`: Đối tượng chứa cả 2 thuộc tính `ufid` và `isReinstalled`.

#### Ví dụ sử dụng:
```dart
final UfidInfo info = await Ufid.getInfo();

print('UFID: ${info.ufid}');
print('Is Reinstalled: ${info.isReinstalled}');
```

---

### 3.4. `Ufid.reset()`

Xóa trạng thái UFID đã lưu trữ trong Keychain (iOS) hoặc trạng thái phiên cài đặt (Android).

```dart
static Future<bool> reset()
```

> [!WARNING]
> Phương thức này chủ yếu phục vụ mục đích **Testing / Debug / QA** để kiểm tra lại luồng cài đặt mới từ đầu (First install) mà không cần phải đổi thiết bị hoặc format máy.

#### Giá trị trả về:
- `Future<bool>`: `true` nếu xóa thành công, `false` nếu thất bại.

#### Ví dụ sử dụng:
```dart
if (kDebugMode) {
  final success = await Ufid.reset();
  print('Reset trạng thái UFID: $success');
}
```

---

### 3.5. `Ufid.getPlatformVersion()`

Lấy thông tin phiên bản hệ điều hành hiện tại (phục vụ mục đích ghi log và chẩn đoán lỗi).

```dart
static Future<String?> getPlatformVersion()
```

#### Giá trị trả về:
- `Future<String?>`: Ví dụ: `"iOS 18.2"` hoặc `"Android 14"`.

---

## 4. Các Kịch Bản Ứng Dụng Thực Tế (Use Cases)

### Kịch bản 1: Chống gian lận nhận quà người dùng mới (Fraud Prevention)
Nhiều người dùng gỡ app rồi cài lại để liên tục nhận ưu đãi "người dùng mới" (Welcome bonus, dùng thử Free Trial).

```dart
Future<void> handleAppLaunchPromotion() async {
  final info = await Ufid.getInfo();

  if (info.isReinstalled) {
    // Đây là máy đã cài lại app -> Không tặng quà người dùng mới nữa
    showReturningUserGreeting();
  } else {
    // Máy lần đầu tiên cài app -> Áp dụng chính sách New User
    applyNewUserBonus();
  }
}
```

---

### Kịch bản 2: Định danh thiết bị bền vững gửi lên Server Backend
Dùng để ghi log hành vi thiết bị hoặc phân tích tỉ lệ người dùng gỡ bỏ rồi quay lại mà không cần người dùng phải đăng nhập tài khoản:

```dart
Future<void> syncDeviceSessionWithBackend() async {
  try {
    final info = await Ufid.getInfo();

    await myApiClient.post('/api/v1/devices/session', body: {
      'device_id': info.ufid,
      'is_reinstalled': info.isReinstalled,
      'installed_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print('Lỗi đồng bộ session thiết bị: $e');
  }
}
```

---

### Kịch bản 3: Tích hợp vào Splash Screen
Tải trước thông tin định danh ngay trong giai đoạn khởi động ứng dụng:

```dart
class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Lấy thông tin thiết bị song song với các tác vụ khởi động khác
    final results = await Future.wait([
      Ufid.getInfo(),
      loadUserPreferences(),
      checkAppUpdates(),
    ]);

    final ufidInfo = results[0] as UfidInfo;
    GlobalAppState.ufid = ufidInfo.ufid;
    GlobalAppState.isReinstalled = ufidInfo.isReinstalled;

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

---

## 5. Xử Lý Ngoại Lệ (Error Handling)

Khi gọi API, bạn nên bọc trong khối `try-catch` để bắt `PlatformException` trong các trường hợp hiếm gặp (ví dụ lỗi phần cứng, dịch vụ bảo mật hệ thống bị khóa):

```dart
import 'package:flutter/services.dart';
import 'package:ufid/ufid.dart';

Future<void> safeGetUfid() async {
  try {
    final info = await Ufid.getInfo();
    print('UFID: ${info.ufid}');
  } on PlatformException catch (e) {
    print('Lỗi từ native platform: ${e.code} - ${e.message}');
  } catch (e) {
    print('Lỗi không xác định: $e');
  }
}
```

---

## 6. Bảng Tóm Tắt Kỹ Thuật (Technical Summary)

| Thuộc tính | Phía Android | Phía iOS |
| :--- | :--- | :--- |
| **Cơ chế định danh** | `Settings.Secure.ANDROID_ID` | UUID lưu trong Keychain (`Security.framework`) |
| **Tầng API sử dụng** | `ContentResolver.call` (`GET_secure`) & Cursor Query | `SecItemCopyMatching` / `SecItemAdd` |
| **Sử dụng PackageManager** | **Không** (Tránh Package Visibility & thẻ `<queries>`) | Không áp dụng |
| **Độ bền khi xóa app** | Giữ nguyên theo thiết bị và signing key của app | **Giữ nguyên 100%** trong Keychain |
| **Quyền cần khai báo** | **Không cần quyền nào** | **Không cần quyền nào** |
