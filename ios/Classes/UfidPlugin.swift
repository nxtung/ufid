import Flutter
import UIKit
import Security

public class UfidPlugin: NSObject, FlutterPlugin {
  public static let keychainService = Bundle.main.bundleIdentifier ?? "com.ufid.plugin"
  public static let keychainAccount = "ufid_persistent_device_identifier"
  private static let userDefaultsLaunchKey = "ufid_has_launched_before"
  private static let userDefaultsReinstalledKey = "ufid_was_reinstalled"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ufid", binaryMessenger: registrar.messenger())
    let instance = UfidPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getUFID":
      let info = getOrCreateUfidInfo()
      result(info.ufid)
    case "isReinstalled":
      let info = getOrCreateUfidInfo()
      result(info.isReinstalled)
    case "getInfo":
      let info = getOrCreateUfidInfo()
      result([
        "ufid": info.ufid,
        "isReinstalled": info.isReinstalled,
        "platform": "ios",
        "keychainUuid": info.ufid,
        "keychainService": UfidPlugin.keychainService,
        "keychainAccount": UfidPlugin.keychainAccount
      ])
    case "reset":
      let success = resetAll()
      result(success)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private struct UfidInternalInfo {
    let ufid: String
    let isReinstalled: Bool
  }

  private func getOrCreateUfidInfo() -> UfidInternalInfo {
    let hasLaunchedBefore = UserDefaults.standard.bool(forKey: UfidPlugin.userDefaultsLaunchKey)
    let existingUfid = readFromKeychain()

    if let ufid = existingUfid, !ufid.isEmpty {
      // Key exists in Keychain
      if !hasLaunchedBefore {
        // App was previously installed on this device, uninstalled, and now re-installed
        UserDefaults.standard.set(true, forKey: UfidPlugin.userDefaultsLaunchKey)
        UserDefaults.standard.set(true, forKey: UfidPlugin.userDefaultsReinstalledKey)
        return UfidInternalInfo(ufid: ufid, isReinstalled: true)
      } else {
        // Subsequent launch in this installation
        let wasReinstalled = UserDefaults.standard.bool(forKey: UfidPlugin.userDefaultsReinstalledKey)
        return UfidInternalInfo(ufid: ufid, isReinstalled: wasReinstalled)
      }
    } else {
      // Key does not exist in Keychain -> Fresh first-time install on this device
      let newUfid = UUID().uuidString.lowercased()
      _ = saveToKeychain(value: newUfid)

      UserDefaults.standard.set(true, forKey: UfidPlugin.userDefaultsLaunchKey)
      UserDefaults.standard.set(false, forKey: UfidPlugin.userDefaultsReinstalledKey)

      return UfidInternalInfo(ufid: newUfid, isReinstalled: false)
    }
  }

  private func readFromKeychain() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: UfidPlugin.keychainService,
      kSecAttrAccount as String: UfidPlugin.keychainAccount,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status == errSecSuccess, let data = dataTypeRef as? Data {
      return String(data: data, encoding: .utf8)
    }
    return nil
  }

  private func saveToKeychain(value: String) -> Bool {
    guard let data = value.data(using: .utf8) else { return false }

    // Delete existing item if any before adding
    _ = deleteFromKeychain()

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: UfidPlugin.keychainService,
      kSecAttrAccount as String: UfidPlugin.keychainAccount,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  private func deleteFromKeychain() -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: UfidPlugin.keychainService,
      kSecAttrAccount as String: UfidPlugin.keychainAccount
    ]

    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }

  private func resetAll() -> Bool {
    let deleted = deleteFromKeychain()
    UserDefaults.standard.removeObject(forKey: UfidPlugin.userDefaultsLaunchKey)
    UserDefaults.standard.removeObject(forKey: UfidPlugin.userDefaultsReinstalledKey)
    return deleted
  }
}
