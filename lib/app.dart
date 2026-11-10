import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/providers/settings_provider.dart';

class ShubhTradersApp extends ConsumerWidget {
  const ShubhTradersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Shubh Traders - POS & Inventory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(settings.fontSizeMultiplier),
      darkTheme: AppTheme.darkTheme(settings.fontSizeMultiplier),
      themeMode: settings.themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontSizeMultiplier),
          ),
          child: child ?? const SizedBox(),
        );
      },
      home: authState.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
