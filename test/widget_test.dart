import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/app.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/database/database_provider.dart';
import 'package:shubh_traders/features/auth/screens/login_screen.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';

void main() {
  testWidgets('App renders login screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'english'});
    final prefs = await SharedPreferences.getInstance();
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const ShubhTradersApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Shubh Traders'), findsWidgets);

    await testDb.close();
  });
}
