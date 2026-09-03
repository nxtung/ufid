import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ufid/ufid.dart';
import 'package:ufid/ufid_method_channel.dart';
import 'package:ufid/ufid_platform_interface.dart';

class MockUfidPlatform with MockPlatformInterfaceMixin implements UfidPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> getUFID() => Future.value('test-ufid-12345');

  @override
  Future<bool> isReinstalled() => Future.value(true);

  @override
  Future<UfidInfo> getInfo() => Future.value(
        const UfidInfo(
          ufid: 'test-ufid-12345',
          isReinstalled: true,
          platform: 'android',
          android: AndroidUfidInfo(
            androidId: 'test-ufid-12345',
            retrievalMethod: 'ipc_call',
          ),
        ),
      );

  @override
  Future<bool> reset() => Future.value(true);
}

void main() {
  final UfidPlatform initialPlatform = UfidPlatform.instance;

  test('$MethodChannelUfid is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelUfid>());
  });

  group('Ufid public API tests with mock platform', () {
    setUp(() {
      UfidPlatform.instance = MockUfidPlatform();
    });

    test('getPlatformVersion returns mock version', () async {
      expect(await Ufid.getPlatformVersion(), '42');
    });

    test('getUFID returns mock ufid', () async {
      expect(await Ufid.getUFID(), 'test-ufid-12345');
    });

    test('isReinstalled returns mock boolean', () async {
      expect(await Ufid.isReinstalled(), true);
    });

    test('getInfo returns complete UfidInfo with Android details', () async {
      final info = await Ufid.getInfo();
      expect(info.ufid, 'test-ufid-12345');
      expect(info.isReinstalled, true);
      expect(info.isAndroid, true);
      expect(info.isIOS, false);
      expect(info.androidId, 'test-ufid-12345');
      expect(info.android?.retrievalMethod, 'ipc_call');
    });

    test('reset returns true', () async {
      expect(await Ufid.reset(), true);
    });
  });

  group('UfidInfo model parsing tests', () {
    test('UfidInfo deserialization for Android', () {
      final map = {
        'ufid': 'android-device-123',
        'isReinstalled': false,
        'platform': 'android',
        'androidId': 'android-device-123',
        'retrievalMethod': 'cursor_query',
      };
      final info = UfidInfo.fromMap(map);
      expect(info.isAndroid, true);
      expect(info.isIOS, false);
      expect(info.androidId, 'android-device-123');
      expect(info.android?.retrievalMethod, 'cursor_query');
      expect(info.toMap()['platform'], 'android');
    });

    test('UfidInfo deserialization for iOS', () {
      final map = {
        'ufid': 'ios-uuid-456',
        'isReinstalled': true,
        'platform': 'ios',
        'keychainUuid': 'ios-uuid-456',
        'keychainService': 'com.example.ufid',
        'keychainAccount': 'ufid_persistent_device_identifier',
      };
      final info = UfidInfo.fromMap(map);
      expect(info.isIOS, true);
      expect(info.isAndroid, false);
      expect(info.keychainUuid, 'ios-uuid-456');
      expect(info.ios?.service, 'com.example.ufid');
      expect(info.ios?.account, 'ufid_persistent_device_identifier');
      expect(info.toMap()['platform'], 'ios');
    });
  });
}
