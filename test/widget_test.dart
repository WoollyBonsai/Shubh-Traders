import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/app.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';

void main() {
  testWidgets('App renders login screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ShubhTradersApp(),
      ),
    );

    await tester.pump();
    expect(find.text('Shubh Traders'), findsWidgets);
  });
}
