import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/utils/password_hash.dart';

bool _fontsLoaded = false;

Future<void> loadSystemFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;

  // 1. Segoe UI
  final segoeFile = File('C:\\Windows\\Fonts\\segoeui.ttf');
  if (segoeFile.existsSync()) {
    final fontData = segoeFile.readAsBytesSync().buffer.asByteData();
    final fontLoader = FontLoader('Segoe UI')..addFont(Future.value(fontData));
    await fontLoader.load();
  }
  final segoeBold = File('C:\\Windows\\Fonts\\segoeuib.ttf');
  if (segoeBold.existsSync()) {
    final fontData = segoeBold.readAsBytesSync().buffer.asByteData();
    final fontLoader = FontLoader('Segoe UI')..addFont(Future.value(fontData));
    await fontLoader.load();
  }

  // 2. Arial & Roboto fallbacks
  final arialFile = File('C:\\Windows\\Fonts\\arial.ttf');
  if (arialFile.existsSync()) {
    final fontData = arialFile.readAsBytesSync().buffer.asByteData();
    final fontLoader = FontLoader('Roboto')..addFont(Future.value(fontData));
    await fontLoader.load();
  }

  // 3. Devanagari Hindi font
  final hindiReg = File('assets/fonts/NotoSansDevanagari-Regular.ttf');
  if (hindiReg.existsSync()) {
    final fontData = hindiReg.readAsBytesSync().buffer.asByteData();
    final fontLoader = FontLoader('NotoSansDevanagari')
      ..addFont(Future.value(fontData));
    await fontLoader.load();
  }

  final hindiBold = File('assets/fonts/NotoSansDevanagari-Bold.ttf');
  if (hindiBold.existsSync()) {
    final fontData = hindiBold.readAsBytesSync().buffer.asByteData();
    final fontLoader = FontLoader('NotoSansDevanagari')
      ..addFont(Future.value(fontData));
    await fontLoader.load();
  }

  // 4. Material Icons
  final iconFile = File('D:\\Work\\flutter\\bin\\cache\\artifacts\\material_fonts\\MaterialIcons-Regular.otf');
  if (iconFile.existsSync()) {
    final fontData = iconFile.readAsBytesSync().buffer.asByteData();
    final fontLoader = FontLoader('MaterialIcons')..addFont(Future.value(fontData));
    await fontLoader.load();
  }
}

Future<void> setupMockPathProvider() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      final mockDir = Directory('testing/mock_docs');
      if (!mockDir.existsSync()) {
        mockDir.createSync(recursive: true);
      }
      return mockDir.absolute.path;
    },
  );
}

Future<void> seedRichActivity(AppDatabase db) async {
  final admin = await (db.select(db.users)..where((u) => u.username.equals('Kanha'))).getSingle();
  final staff = await (db.select(db.users)..where((u) => u.username.equals('staff'))).getSingle();
  final allCustomers = await db.select(db.customers).get();
  final ramesh = allCustomers.firstWhere((c) => c.name.contains('Ramesh'));
  final items = await db.select(db.items).get();
  final cement = items.firstWhere((i) => i.nameEn.contains('UltraTech'));
  final steel = items.firstWhere((i) => i.nameEn.contains('Tata Tiscon'));

  // Deterministic timestamp for golden pixel consistency
  final fixedTimestamp = DateTime(2026, 11, 10, 10, 30);

  // 1. Cash Sale
  await db.executeSaleTransaction(
    userId: staff.id,
    username: staff.username,
    customerId: null,
    totalAmount: 1900.0,
    paymentMethod: 'Cash',
    cartItems: [
      CartItemPayload(itemId: cement.id, qty: 5, soldPrice: 380.0, total: 1900.0),
    ],
    notes: 'Walk-in cash counter sale',
    customTimestamp: fixedTimestamp,
  );

  // 2. Udhaar Sale to Ramesh
  await db.executeSaleTransaction(
    userId: staff.id,
    username: staff.username,
    customerId: ramesh.id,
    totalAmount: 7000.0,
    paymentMethod: 'Udhaar',
    cartItems: [
      CartItemPayload(itemId: steel.id, qty: 100, soldPrice: 70.0, total: 7000.0),
    ],
    notes: 'Site delivery credit bill',
    customTimestamp: fixedTimestamp,
  );

  // 3. Restock audit log
  await db.logAudit(
    userId: admin.id,
    username: admin.username,
    actionType: 'ITEM_RESTOCKED',
    entityId: cement.id.toString(),
    details: 'Restocked 100 bags of UltraTech Cement at rate ₹340.00',
    customTimestamp: fixedTimestamp,
  );

  // 4. Udhaar payment audit log
  await db.logAudit(
    userId: staff.id,
    username: staff.username,
    actionType: 'UDHAAR_PAYMENT',
    entityId: ramesh.id.toString(),
    details: 'Received ₹5,000 cash payment against pending debt from Ramesh Patel',
    customTimestamp: fixedTimestamp,
  );
}

class TestContext {
  final AppDatabase db;
  final SharedPreferences prefs;

  TestContext({required this.db, required this.prefs});

  Future<void> dispose() async {
    await db.close();
  }
}

Future<TestContext> createTestContext({String language = 'english', bool seedActivity = true}) async {
  await loadSystemFonts();
  await setupMockPathProvider();
  SharedPreferences.setMockInitialValues({'app_language': language});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  await db.seedDefaultDataIfNeeded(hashPassword);
  if (seedActivity) {
    await seedRichActivity(db);
  }
  return TestContext(db: db, prefs: prefs);
}
