import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ufid_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('ufid');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return 'TestOS 1.0';
          case 'getUFID':
            return 'mock-device-id-123';
          case 'isReinstalled':
            return false;
          case 'getInfo':
            return {
              'ufid': 'mock-device-id-123',
              'isReinstalled': false,
              'platform': 'android',
              'androidId': 'mock-device-id-123',
              'retrievalMethod': 'ipc_call',
            };
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

  testWidgets('Verify UfidHomeScreen renders and loads data',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('UFID Demo App'), findsOneWidget);
    expect(find.text('FIRST-TIME INSTALL'), findsOneWidget);
    // Displayed in both UFID card and Android Native Details card
    expect(find.text('mock-device-id-123'), findsNWidgets(2));
    expect(find.text('Android Native Details'), findsOneWidget);
  });
}
