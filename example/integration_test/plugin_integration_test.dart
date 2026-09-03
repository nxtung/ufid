import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ufid/ufid.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion and UFID test', (WidgetTester tester) async {
    final String? version = await Ufid.getPlatformVersion();
    expect(version?.isNotEmpty, true);

    final String? ufid = await Ufid.getUFID();
    expect(ufid != null, true);

    final UfidInfo info = await Ufid.getInfo();
    expect(info.ufid.isNotEmpty, true);
  });
}
