import 'ufid_platform_interface.dart';

/// Android-specific UFID details.
class AndroidUfidInfo {
  /// The Android ID retrieved from `Settings.Secure.ANDROID_ID`.
  final String androidId;

  /// The deep retrieval method used by the native layer.
  /// Examples: `ipc_call`, `cursor_query`, `settings_secure`.
  final String retrievalMethod;

  const AndroidUfidInfo({
    required this.androidId,
    required this.retrievalMethod,
  });

  factory AndroidUfidInfo.fromMap(Map<dynamic, dynamic> map) {
    return AndroidUfidInfo(
      androidId: map['androidId'] as String? ?? map['ufid'] as String? ?? '',
      retrievalMethod: map['retrievalMethod'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'androidId': androidId,
      'retrievalMethod': retrievalMethod,
    };
  }

  @override
  String toString() =>
      'AndroidUfidInfo(androidId: $androidId, retrievalMethod: $retrievalMethod)';
}

/// iOS-specific UFID details.
class IosUfidInfo {
  /// The persistent UUID stored in Keychain.
  final String keychainUuid;

  /// The Keychain service identifier used.
  final String service;

  /// The Keychain account identifier used.
  final String account;

  const IosUfidInfo({
    required this.keychainUuid,
    required this.service,
    required this.account,
  });

  factory IosUfidInfo.fromMap(Map<dynamic, dynamic> map) {
    return IosUfidInfo(
      keychainUuid: map['keychainUuid'] as String? ?? map['ufid'] as String? ?? '',
      service: map['keychainService'] as String? ?? '',
      account: map['keychainAccount'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'keychainUuid': keychainUuid,
      'service': service,
      'account': account,
    };
  }

  @override
  String toString() =>
      'IosUfidInfo(keychainUuid: $keychainUuid, service: $service, account: $account)';
}

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

  /// The operating system platform: `'android'`, `'ios'`, or `'unknown'`.
  final String platform;

  /// Detailed Android-specific information (populated only on Android).
  final AndroidUfidInfo? android;

  /// Detailed iOS-specific information (populated only on iOS).
  final IosUfidInfo? ios;

  const UfidInfo({
    required this.ufid,
    required this.isReinstalled,
    this.platform = 'unknown',
    this.android,
    this.ios,
  });

  /// True if the current platform is Android.
  bool get isAndroid => platform.toLowerCase() == 'android';

  /// True if the current platform is iOS.
  bool get isIOS => platform.toLowerCase() == 'ios';

  /// Convenience getter for Android ID (available if on Android).
  String? get androidId => android?.androidId ?? (isAndroid ? ufid : null);

  /// Convenience getter for iOS Keychain UUID (available if on iOS).
  String? get keychainUuid => ios?.keychainUuid ?? (isIOS ? ufid : null);

  factory UfidInfo.fromMap(Map<dynamic, dynamic> map) {
    final rawPlatform = (map['platform'] as String? ?? '').toLowerCase();
    final ufidVal = map['ufid'] as String? ?? '';
    final isReinstalledVal = map['isReinstalled'] as bool? ?? false;

    AndroidUfidInfo? androidInfo;
    IosUfidInfo? iosInfo;

    if (rawPlatform == 'android' || map.containsKey('androidId')) {
      androidInfo = AndroidUfidInfo.fromMap(map);
    }

    if (rawPlatform == 'ios' || map.containsKey('keychainUuid') || map.containsKey('keychainService')) {
      iosInfo = IosUfidInfo.fromMap(map);
    }

    return UfidInfo(
      ufid: ufidVal,
      isReinstalled: isReinstalledVal,
      platform: rawPlatform.isNotEmpty ? rawPlatform : 'unknown',
      android: androidInfo,
      ios: iosInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ufid': ufid,
      'isReinstalled': isReinstalled,
      'platform': platform,
      if (android != null) 'android': android!.toMap(),
      if (ios != null) 'ios': ios!.toMap(),
    };
  }

  @override
  String toString() =>
      'UfidInfo(ufid: $ufid, isReinstalled: $isReinstalled, platform: $platform, android: $android, ios: $ios)';
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

  /// Retrieves both [ufid] and [isReinstalled] state along with platform details
  /// for Android and iOS in a single platform call.
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
