// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_finances/main.dart';
import 'package:aurora_finances/data/settings_store.dart';

void main() {
  testWidgets('App shows auth screen when logged out', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    final settingsStore = AppSettingsStore();
    await settingsStore.loadForUser(null);

    await tester.pumpWidget(FinanceApp(settingsStore: settingsStore));

    expect(find.text('Aurora Finances'), findsOneWidget);
  });
}
