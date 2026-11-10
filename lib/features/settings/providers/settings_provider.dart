import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden at app startup');
});

class AppSettings {
  final double fontSizeMultiplier;
  final ThemeMode themeMode;
  final DualTextDisplayMode dualTextMode;
  final String shopName;
  final String shopAddress;
  final String shopPhone;

  const AppSettings({
    this.fontSizeMultiplier = 1.0,
    this.themeMode = ThemeMode.light,
    this.dualTextMode = DualTextDisplayMode.stacked,
    this.shopName = 'Shubh Traders (शुभ ट्रेडर्स)',
    this.shopAddress = 'Station Road, Building Material Market, India',
    this.shopPhone = '+91 98765 43210',
  });

  AppSettings copyWith({
    double? fontSizeMultiplier,
    ThemeMode? themeMode,
    DualTextDisplayMode? dualTextMode,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
  }) {
    return AppSettings(
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      themeMode: themeMode ?? this.themeMode,
      dualTextMode: dualTextMode ?? this.dualTextMode,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final fontMultiplier = prefs.getDouble('font_size_multiplier') ?? 1.0;
    final themeStr = prefs.getString('theme_mode') ?? 'light';
    final dualStr = prefs.getString('dual_text_mode') ?? 'stacked';
    final shopName = prefs.getString('shop_name') ?? 'Shubh Traders (शुभ ट्रेडर्स)';
    final shopAddress = prefs.getString('shop_address') ?? 'Station Road, Building Material Market, India';
    final shopPhone = prefs.getString('shop_phone') ?? '+91 98765 43210';

    return AppSettings(
      fontSizeMultiplier: fontMultiplier,
      themeMode: themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light,
      dualTextMode: dualStr == 'inline' ? DualTextDisplayMode.inline : DualTextDisplayMode.stacked,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
    );
  }

  Future<void> setFontSizeMultiplier(double multiplier) async {
    state = state.copyWith(fontSizeMultiplier: multiplier);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('font_size_multiplier', multiplier);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setDualTextMode(DualTextDisplayMode mode) async {
    state = state.copyWith(dualTextMode: mode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('dual_text_mode', mode == DualTextDisplayMode.inline ? 'inline' : 'stacked');
  }

  Future<void> updateShopDetails({
    required String name,
    required String address,
    required String phone,
  }) async {
    state = state.copyWith(shopName: name, shopAddress: address, shopPhone: phone);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('shop_name', name);
    await prefs.setString('shop_address', address);
    await prefs.setString('shop_phone', phone);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
