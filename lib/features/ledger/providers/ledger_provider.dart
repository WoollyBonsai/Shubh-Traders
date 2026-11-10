import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/database/database_provider.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';

class SaleWithCustomerAndUser {
  final Sale sale;
  final Customer? customer;
  final User user;

  SaleWithCustomerAndUser({
    required this.sale,
    this.customer,
    required this.user,
  });
}

final salesStreamProvider = StreamProvider<List<SaleWithCustomerAndUser>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = (db.select(db.sales)
        ..orderBy([(s) => OrderingTerm.desc(s.timestamp)]))
      .join([
    innerJoin(db.users, db.users.id.equalsExp(db.sales.userId)),
    leftOuterJoin(db.customers, db.customers.id.equalsExp(db.sales.customerId)),
  ]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return SaleWithCustomerAndUser(
        sale: row.readTable(db.sales),
        user: row.readTable(db.users),
        customer: row.readTableOrNull(db.customers),
      );
    }).toList();
  });
});

final udhaarCustomersStreamProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)
        ..where((c) => c.totalDue.isBiggerThanValue(0.0))
        ..orderBy([(c) => OrderingTerm.desc(c.totalDue)]))
      .watch();
});

class CustomerPaymentWithDetails {
  final Payment payment;
  final Customer customer;

  CustomerPaymentWithDetails({required this.payment, required this.customer});
}

final paymentsStreamProvider = StreamProvider<List<CustomerPaymentWithDetails>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = (db.select(db.payments)
        ..orderBy([(p) => OrderingTerm.desc(p.timestamp)]))
      .join([
    innerJoin(db.customers, db.customers.id.equalsExp(db.payments.customerId)),
  ]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return CustomerPaymentWithDetails(
        payment: row.readTable(db.payments),
        customer: row.readTable(db.customers),
      );
    }).toList();
  });
});

class LedgerNotifier {
  final AppDatabase _db;
  LedgerNotifier(this._db);

  Future<int> receivePayment({
    required int customerId,
    required double amountPaid,
    required String paymentMethod,
    String? notes,
  }) {
    return _db.recordPaymentTransaction(
      customerId: customerId,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }

  // Export to Excel file using excel package and file_picker
  Future<String?> exportToExcel({
    required DateTime startDate,
    required DateTime endDate,
    bool includeSales = true,
    bool includeUdhaar = true,
    bool includeInventory = true,
  }) async {
    final excel = Excel.createExcel();

    // End date should include the full end of that day (23:59:59)
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final startDateTime = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);

    // 1. Sales Sheet
    if (includeSales) {
      final salesSheet = excel['Sales Report'];
      excel.setDefaultSheet('Sales Report');

      // Title & Date Header
      salesSheet.appendRow([
        TextCellValue('SHUBH TRADERS - SALES REPORT'),
      ]);
      salesSheet.appendRow([
        TextCellValue('Period: ${Formatters.date(startDateTime)} to ${Formatters.date(endDateTime)}'),
      ]);
      salesSheet.appendRow([TextCellValue('')]); // empty line

      // Table Header
      salesSheet.appendRow([
        TextCellValue('Invoice #'),
        TextCellValue('Date & Time'),
        TextCellValue('Customer Name'),
        TextCellValue('Customer Phone'),
        TextCellValue('Payment Method'),
        TextCellValue('Total Amount (Rs)'),
        TextCellValue('Billed By Staff'),
        TextCellValue('Notes'),
      ]);

      final salesQuery = (await (_db.select(_db.sales)
            ..where((s) => s.timestamp.isBetweenValues(startDateTime, endDateTime))
            ..orderBy([(s) => OrderingTerm.desc(s.timestamp)]))
          .join([
        innerJoin(_db.users, _db.users.id.equalsExp(_db.sales.userId)),
        leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.sales.customerId)),
      ]).get());

      double totalRevenue = 0.0;
      for (final row in salesQuery) {
        final s = row.readTable(_db.sales);
        final u = row.readTable(_db.users);
        final c = row.readTableOrNull(_db.customers);
        totalRevenue += s.totalAmount;

        salesSheet.appendRow([
          TextCellValue('INV-${s.id.toString().padLeft(5, '0')}'),
          TextCellValue(Formatters.dateTime(s.timestamp)),
          TextCellValue(c?.name ?? 'Counter Sale'),
          TextCellValue(c?.phone ?? '-'),
          TextCellValue(s.paymentMethod),
          DoubleCellValue(s.totalAmount),
          TextCellValue('${u.fullName} (${u.username})'),
          TextCellValue(s.notes ?? '-'),
        ]);
      }

      salesSheet.appendRow([TextCellValue('')]);
      salesSheet.appendRow([
        TextCellValue('TOTAL REVENUE:'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(totalRevenue),
      ]);
    }

    // 2. Udhaar Book Sheet
    if (includeUdhaar) {
      final udhaarSheet = excel['Udhaar Book'];
      udhaarSheet.appendRow([TextCellValue('SHUBH TRADERS - UDHAAR LEDGER (OUTSTANDING BALANCES)')]);
      udhaarSheet.appendRow([TextCellValue('Generated on: ${Formatters.dateTime(DateTime.now())}')]);
      udhaarSheet.appendRow([TextCellValue('')]);

      udhaarSheet.appendRow([
        TextCellValue('Customer ID'),
        TextCellValue('Customer Name'),
        TextCellValue('Contact Number'),
        TextCellValue('Outstanding Due (Rs)'),
        TextCellValue('Customer Since'),
      ]);

      final customers = await (_db.select(_db.customers)
            ..where((c) => c.totalDue.isBiggerThanValue(0.0))
            ..orderBy([(c) => OrderingTerm.desc(c.totalDue)]))
          .get();

      double totalUdhaar = 0.0;
      for (final c in customers) {
        totalUdhaar += c.totalDue;
        udhaarSheet.appendRow([
          IntCellValue(c.id),
          TextCellValue(c.name),
          TextCellValue(c.phone),
          DoubleCellValue(c.totalDue),
          TextCellValue(Formatters.date(c.createdAt)),
        ]);
      }

      udhaarSheet.appendRow([TextCellValue('')]);
      udhaarSheet.appendRow([
        TextCellValue('TOTAL PENDING UDHAAR:'),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(totalUdhaar),
      ]);
    }

    // 3. Inventory Sheet
    if (includeInventory) {
      final invSheet = excel['Inventory Status'];
      invSheet.appendRow([TextCellValue('SHUBH TRADERS - CURRENT STOCK SUMMARY')]);
      invSheet.appendRow([TextCellValue('As of: ${Formatters.dateTime(DateTime.now())}')]);
      invSheet.appendRow([TextCellValue('')]);

      invSheet.appendRow([
        TextCellValue('Item ID'),
        TextCellValue('Item Name (EN)'),
        TextCellValue('Item Name (HI)'),
        TextCellValue('Category'),
        TextCellValue('Current Stock'),
        TextCellValue('Unit'),
        TextCellValue('Purchase Price (Rs)'),
        TextCellValue('Selling Price (Rs)'),
        TextCellValue('Stock Valuation (Rs)'),
        TextCellValue('Low Stock Alert Status'),
      ]);

      final itemsQuery = await _db.select(_db.items).join([
        leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.items.categoryId)),
      ]).get();

      double totalValuation = 0.0;
      for (final row in itemsQuery) {
        final it = row.readTable(_db.items);
        final cat = row.readTableOrNull(_db.categories);
        final valuation = it.stockQty * it.purchasePrice;
        totalValuation += valuation;

        invSheet.appendRow([
          IntCellValue(it.id),
          TextCellValue(it.nameEn),
          TextCellValue(it.nameHi),
          TextCellValue(cat?.nameEn ?? '-'),
          DoubleCellValue(it.stockQty),
          TextCellValue(it.unit),
          DoubleCellValue(it.purchasePrice),
          DoubleCellValue(it.sellingPrice),
          DoubleCellValue(valuation),
          TextCellValue(it.stockQty <= it.lowStockThreshold ? 'LOW STOCK ALERT' : 'Normal'),
        ]);
      }

      invSheet.appendRow([TextCellValue('')]);
      invSheet.appendRow([
        TextCellValue('TOTAL INVENTORY VALUATION:'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(totalValuation),
      ]);
    }

    // Remove default Sheet1 if exists and unused
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    // Use FilePicker to prompt user for save destination on Windows
    final defaultFileName = 'Shubh_Traders_Report_${Formatters.dateIso(DateTime.now())}.xlsx';
    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Save Excel Report / एक्सेल रिपोर्ट सुरक्षित करें',
      fileName: defaultFileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    if (savedUri != null) {
      return savedUri.toFilePath();
    }

    return null;
  }
}

final ledgerNotifierProvider = Provider<LedgerNotifier>((ref) {
  final db = ref.watch(databaseProvider);
  return LedgerNotifier(db);
});
