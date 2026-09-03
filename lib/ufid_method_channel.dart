import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ufid.dart';
import 'ufid_platform_interface.dart';

/// An implementation of [UfidPlatform] that uses method channels.
class MethodChannelUfid extends UfidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ufid');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> getUFID() async {
    final ufid = await methodChannel.invokeMethod<String>('getUFID');
    return ufid;
  }

  @override
  Future<bool> isReinstalled() async {
    final reinstalled = await methodChannel.invokeMethod<bool>('isReinstalled');
    return reinstalled ?? false;
  }

  @override
  Future<UfidInfo> getInfo() async {
    final result = await methodChannel.invokeMapMethod<dynamic, dynamic>('getInfo');
    if (result == null) {
      return const UfidInfo(ufid: '', isReinstalled: false);
    }
    return UfidInfo.fromMap(result);
  }

  @override
  Future<bool> reset() async {
    final success = await methodChannel.invokeMethod<bool>('reset');
    return success ?? false;
  }
}
