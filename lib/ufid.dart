import 'ufid_platform_interface.dart';

/// Information regarding the device identifier and installation status.
class UfidInfo {
  /// The persistent unique identifier of the device.
  /// - On Android: Android ID retrieved via deep `android.provider.Settings` APIs.
  /// - On iOS: UUID stored persistently in the iOS Keychain.
  final String ufid;

  /// Whether the current application launch is from a re-installation.
  /// - `true`: The app was previously installed on this device, uninstalled, and now re-installed.
  /// - `false`: This is the first time the app is installed on this device.
  final bool isReinstalled;

  const UfidInfo({
    required this.ufid,
    required this.isReinstalled,
  });

  factory UfidInfo.fromMap(Map<dynamic, dynamic> map) {
    return UfidInfo(
      ufid: map['ufid'] as String? ?? '',
      isReinstalled: map['isReinstalled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ufid': ufid,
      'isReinstalled': isReinstalled,
    };
  }

  @override
  String toString() => 'UfidInfo(ufid: $ufid, isReinstalled: $isReinstalled)';
}

/// The main entry point for the UFID (User Follow ID) plugin.
class Ufid {
  static UfidPlatform get _platform => UfidPlatform.instance;

  /// Retrieves the platform version string for diagnostic purposes.
  static Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }

  /// Retrieves the persistent unique follow identifier for the device (UFID).
  ///
  /// - On **Android**: Retrieved via deep `android.provider.Settings` ContentResolver IPC call (`GET_secure` ANDROID_ID), without using `PackageManager`.
  /// - On **iOS**: Generated and stored persistently in the iOS **Keychain**, surviving app uninstallation.
  static Future<String?> getUFID() {
    return _platform.getUFID();
  }

  /// Checks whether the application was re-installed on the current device.
  ///
  /// - Returns `true` if the application was previously installed and uninstalled on this device.
  /// - Returns `false` if this is a fresh first-time installation.
  static Future<bool> isReinstalled() {
    return _platform.isReinstalled();
  }

  /// Retrieves both [ufid] and [isReinstalled] state in a single platform call.
  static Future<UfidInfo> getInfo() {
    return _platform.getInfo();
  }

  /// Resets the stored UFID and reinstall flags.
  ///
  /// Useful for testing, QA, and debugging workflows.
  static Future<bool> reset() {
    return _platform.reset();
  }
}
