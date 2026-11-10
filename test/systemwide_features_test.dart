import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:shubh_traders/app.dart';
import 'package:shubh_traders/core/database/database_provider.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';
import 'package:shubh_traders/features/auth/screens/login_screen.dart';
import 'package:shubh_traders/features/auth/screens/users_screen.dart';
import 'package:shubh_traders/features/audit/screens/audit_logs_screen.dart';
import 'package:shubh_traders/features/backup/screens/backup_screen.dart';
import 'package:shubh_traders/features/billing/services/receipt_pdf_generator.dart';
import 'package:shubh_traders/features/billing/widgets/receipt_preview_dialog.dart';
import 'package:shubh_traders/features/home/home_screen.dart';
import 'package:shubh_traders/features/inventory/screens/categories_screen.dart';
import 'package:shubh_traders/features/inventory/screens/inventory_screen.dart';
import 'package:shubh_traders/features/ledger/screens/sales_history_screen.dart';
import 'package:shubh_traders/features/ledger/screens/udhaar_book_screen.dart';
import 'package:shubh_traders/features/pos/providers/pos_provider.dart';
import 'package:shubh_traders/features/pos/screens/pos_screen.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';
import 'package:shubh_traders/features/settings/screens/settings_screen.dart';
import 'systemwide_test_helper.dart';

void main() {
  const desktopSize = Size(1366, 768);

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('System-Wide Testing & Screenshots Suite', () {
    // 01. Login Screen - Employee Default Dropdown
    testWidgets('01 - Login Screen with Employee Dropdown', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Shubh Traders'), findsWidgets);
      expect(find.text('Kanha'), findsNothing); // Hidden Admin

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/01_login_screen_employee.png'));
    });

    // 02. Login Screen - Owner / Admin Login Mode
    testWidgets('02 - Login Screen Owner/Admin Login Mode', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await tester.pumpAndSettle();

      final ownerToggle = find.text('Owner Login');
      expect(ownerToggle, findsOneWidget);
      await tester.tap(ownerToggle);
      await tester.pumpAndSettle();

      expect(find.text('Owner / Admin Login'), findsWidgets);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/02_login_screen_owner_admin.png'));
    });

    // 03. Login Screen - Register Employee Modal
    testWidgets('03 - Register Employee Modal Dialog', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final registerBtn = find.textContaining('Register New Employee');
      expect(registerBtn, findsOneWidget);
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Employee Registration'), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/03_login_screen_register_modal.png'));
    });

    // 04. Business Dashboard - Admin View
    testWidgets('04 - Business Dashboard Admin View', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );

      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Business Dashboard & Overview'), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/04_dashboard_admin.png'));
    });

    // 05. Point of Sale (POS) - Product Catalog
    testWidgets('05 - POS Product Catalog with Brand Badges', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      final posNav = find.text('Point of Sale (POS)');
      await tester.tap(posNav);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PosScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/05_point_of_sale_catalog.png'));
    });

    // 06. POS - Cart with Customer, Items & Price Override
    testWidgets('06 - POS Cart with Customer and Price Override', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Point of Sale (POS)'));
      await tester.pump(const Duration(milliseconds: 500));

      final cementCard = find.textContaining('UltraTech Cement');
      if (cementCard.evaluate().isNotEmpty) {
        await tester.tap(cementCard.first);
        await tester.pump(const Duration(milliseconds: 300));
      }

      final steelCard = find.textContaining('Tata Tiscon');
      if (steelCard.evaluate().isNotEmpty) {
        await tester.tap(steelCard.first);
        await tester.pump(const Duration(milliseconds: 300));
      }

      final allCustomers = await ctx.db.select(ctx.db.customers).get();
      final ramesh = allCustomers.firstWhere((c) => c.name.contains('Ramesh'));
      container.read(posProvider.notifier).selectCustomer(ramesh);
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/06_point_of_sale_cart_with_customer.png'));
    });

    // 07. POS - Online / UPI Payment with Shop QR Code
    testWidgets('07 - POS Online UPI Mode with Shop QR Code', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Point of Sale (POS)'));
      await tester.pump(const Duration(milliseconds: 500));

      final items = await ctx.db.select(ctx.db.items).get();
      container.read(posProvider.notifier).addItem(items.first);
      container.read(posProvider.notifier).setPaymentMethod('Online');
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/07_point_of_sale_online_upi_qr.png'));
    });

    // 08. Bill Receipt Preview Modal
    testWidgets('08 - Bill Receipt Preview Modal with Print Buttons', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      final sales = await ctx.db.select(ctx.db.sales).get();
      final sale = sales.last;
      final saleItems = await (ctx.db.select(ctx.db.saleItems)..where((si) => si.saleId.equals(sale.id))).get();
      final customer = sale.customerId != null
          ? await (ctx.db.select(ctx.db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingleOrNull()
          : null;
      final user = await (ctx.db.select(ctx.db.users)..where((u) => u.id.equals(sale.userId))).getSingle();

      final List<SaleItemWithDetails> itemsWithDetails = [];
      for (final si in saleItems) {
        final item = await (ctx.db.select(ctx.db.items)..where((i) => i.id.equals(si.itemId))).getSingle();
        itemsWithDetails.add(SaleItemWithDetails(saleItem: si, item: item));
      }

      final BuildContext currentContext = tester.element(find.byType(HomeScreen));
      ReceiptPreviewDialog.show(
        currentContext,
        sale: sale,
        items: itemsWithDetails,
        customer: customer,
        user: user,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReceiptPreviewDialog), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/08_bill_receipt_preview.png'));
    });

    // 09. Inventory & Stock Management
    testWidgets('09 - Inventory Stock Management Screen', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Inventory & Stock'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(InventoryScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/09_inventory_management.png'));
    });

    // 10. Inventory - Restock Modal
    testWidgets('10 - Inventory Restock Modal Dialog', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Inventory & Stock'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final restockBtn = find.text('Restock');
      expect(restockBtn, findsWidgets);
      await tester.ensureVisible(restockBtn.first);
      await tester.tap(restockBtn.first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/10_inventory_restock_modal.png'));
    });

    // 11. Category Management
    testWidgets('11 - Category Management Screen', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Categories'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CategoriesScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/11_category_management.png'));
    });

    // 12. Udhaar Book (Customer Debt Ledger)
    testWidgets('12 - Udhaar Book Customer Debt Ledger', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Udhaar Book'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(UdhaarBookScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/12_udhaar_book_ledger.png'));
    });

    // 13. Udhaar - Receive Payment Modal
    testWidgets('13 - Udhaar Receive Payment Modal', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Udhaar Book'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final payBtn = find.text('Receive Payment');
      expect(payBtn, findsWidgets);
      await tester.ensureVisible(payBtn.first);
      await tester.tap(payBtn.first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/13_udhaar_receive_payment_modal.png'));
    });

    // 14. Sales History & Invoices
    testWidgets('14 - Sales History and Invoices Table', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Sales History'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SalesHistoryScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/14_sales_history_screen.png'));
    });

    // 15. Admin Audit Trail (User Footprints)
    testWidgets('15 - Admin Audit Trail User Footprints', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      final auditNav = find.text('Audit Trail');
      await tester.ensureVisible(auditNav);
      await tester.tap(auditNav);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuditLogsScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/15_audit_logs_screen.png'));
    });

    // 16. User & Staff Management (Admin Console)
    testWidgets('16 - User and Staff Management Admin Console', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      final usersNav = find.text('Users & Staff');
      await tester.ensureVisible(usersNav);
      await tester.tap(usersNav);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(UsersScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/16_user_management_screen.png'));
    });

    // 17. Database Backups Manager
    testWidgets('17 - Database Backups and Restore Manager', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      final backupNav = find.text('Database Backups');
      await tester.ensureVisible(backupNav);
      await tester.tap(backupNav);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BackupScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/17_database_backups_screen.png'));
    });

    // 18. Settings Screen
    testWidgets('18 - System Settings and Universal Language', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));

      final settingsNav = find.text('Settings');
      await tester.ensureVisible(settingsNav);
      await tester.tap(settingsNav);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SettingsScreen), findsOneWidget);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/18_settings_screen.png'));
    });

    // 19. Universal Hindi Language Mode (हिंदी)
    testWidgets('19 - Universal Hindi Language Dashboard', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'hindi');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('Kanha', 'Kanha@3629');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('डैशबोर्ड'), findsWidgets);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/19_universal_language_hindi.png'));
    });

    // 20. Role-Based Access - Restricted Employee View
    testWidgets('20 - Role-Based Access Restricted Employee View', (WidgetTester tester) async {
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctx = await createTestContext(language: 'english');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(ctx.prefs),
          databaseProvider.overrideWithValue(ctx.db),
        ],
      );
      addTearDown(() {
        container.dispose();
        ctx.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ShubhTradersApp()),
      );
      await container.read(authProvider.notifier).login('staff', '1111');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeScreen), findsOneWidget);
      // Admin menus are strictly HIDDEN
      expect(find.text('Audit Trail'), findsNothing);
      expect(find.text('Users & Staff'), findsNothing);
      expect(find.text('Database Backups'), findsNothing);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../testing/20_employee_view_restricted.png'));
    });
  });
}
