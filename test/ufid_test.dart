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
        const UfidInfo(ufid: 'test-ufid-12345', isReinstalled: true),
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

    test('getInfo returns complete UfidInfo', () async {
      final info = await Ufid.getInfo();
      expect(info.ufid, 'test-ufid-12345');
      expect(info.isReinstalled, true);
    });

    test('reset returns true', () async {
      expect(await Ufid.reset(), true);
    });
  });
}
