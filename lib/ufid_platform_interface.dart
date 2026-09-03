import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ufid.dart';
import 'ufid_method_channel.dart';

abstract class UfidPlatform extends PlatformInterface {
  /// Constructs a UfidPlatform.
  UfidPlatform() : super(token: _token);

  static final Object _token = Object();

  static UfidPlatform _instance = MethodChannelUfid();

  /// The default instance of [UfidPlatform] to use.
  static UfidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [UfidPlatform] when
  /// they register themselves.
  static set instance(UfidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the platform version string (for diagnostics).
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Retrieves the persistent unique follow identifier for the device (UFID).
  Future<String?> getUFID() {
    throw UnimplementedError('getUFID() has not been implemented.');
  }

  /// Checks whether the application was re-installed on the device.
  Future<bool> isReinstalled() {
    throw UnimplementedError('isReinstalled() has not been implemented.');
  }

  /// Retrieves both [ufid] and [isReinstalled] information in a single call.
  Future<UfidInfo> getInfo() {
    throw UnimplementedError('getInfo() has not been implemented.');
  }

  /// Resets the persistent identifier and reinstall flags (for testing/debugging).
  Future<bool> reset() {
    throw UnimplementedError('reset() has not been implemented.');
  }
}
