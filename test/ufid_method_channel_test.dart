import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ufid/ufid_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelUfid platform = MethodChannelUfid();
  const MethodChannel channel = MethodChannel('ufid');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return 'Android 14';
          case 'getUFID':
            return 'mock-android-id-999';
          case 'isReinstalled':
            return true;
          case 'getInfo':
            return {
              'ufid': 'mock-android-id-999',
              'isReinstalled': true,
              'platform': 'android',
              'androidId': 'mock-android-id-999',
              'retrievalMethod': 'ipc_call',
            };
          case 'reset':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion calls channel', () async {
    expect(await platform.getPlatformVersion(), 'Android 14');
  });

  test('getUFID calls channel', () async {
    expect(await platform.getUFID(), 'mock-android-id-999');
  });

  test('isReinstalled calls channel', () async {
    expect(await platform.isReinstalled(), true);
  });

  test('getInfo calls channel and parses UfidInfo with Android details', () async {
    final info = await platform.getInfo();
    expect(info.ufid, 'mock-android-id-999');
    expect(info.isReinstalled, true);
    expect(info.isAndroid, true);
    expect(info.androidId, 'mock-android-id-999');
    expect(info.android?.retrievalMethod, 'ipc_call');
  });

  test('reset calls channel', () async {
    expect(await platform.reset(), true);
  });
}
