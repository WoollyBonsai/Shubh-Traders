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
    required int userId,
    required String username,
    String? notes,
  }) {
    return _db.recordPaymentTransaction(
      customerId: customerId,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      userId: userId,
      username: username,
      notes: notes,
    );
  }

  // Export to Excel file using excel package and file_picker with professional formatting
  Future<String?> exportToExcel({
    required DateTime startDate,
    required DateTime endDate,
    bool includeSales = true,
    bool includeUdhaar = true,
    bool includeInventory = true,
  }) async {
    final excel = Excel.createExcel();

    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final startDateTime = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final numberStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
    );

    final totalStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
    );

    // 1. Sales Sheet
    if (includeSales) {
      final salesSheet = excel['Sales Report'];
      excel.setDefaultSheet('Sales Report');

      // Set spacious column widths
      salesSheet.setColumnWidth(0, 18.0);
      salesSheet.setColumnWidth(1, 24.0);
      salesSheet.setColumnWidth(2, 28.0);
      salesSheet.setColumnWidth(3, 18.0);
      salesSheet.setColumnWidth(4, 18.0);
      salesSheet.setColumnWidth(5, 20.0);
      salesSheet.setColumnWidth(6, 26.0);
      salesSheet.setColumnWidth(7, 24.0);

      salesSheet.appendRow([
        TextCellValue('SHUBH TRADERS - SALES TRANSACTION REPORT'),
      ]);
      salesSheet.appendRow([
        TextCellValue('Period: ${Formatters.date(startDateTime)} to ${Formatters.date(endDateTime)}'),
      ]);
      salesSheet.appendRow([TextCellValue('')]);

      salesSheet.appendRow([
        TextCellValue('Invoice #'),
        TextCellValue('Date & Time'),
        TextCellValue('Customer Name'),
        TextCellValue('Contact Number'),
        TextCellValue('Payment Method'),
        TextCellValue('Total Amount (Rs)'),
        TextCellValue('Billed By Staff'),
        TextCellValue('Notes / Remarks'),
      ]);

      // Apply header styling to row 3 (0-indexed)
      for (int c = 0; c < 8; c++) {
        final cell = salesSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
        cell.cellStyle = headerStyle;
      }

      final salesQuery = (await (_db.select(_db.sales)
            ..where((s) => s.timestamp.isBetweenValues(startDateTime, endDateTime))
            ..orderBy([(s) => OrderingTerm.desc(s.timestamp)]))
          .join([
        innerJoin(_db.users, _db.users.id.equalsExp(_db.sales.userId)),
        leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.sales.customerId)),
      ]).get());

      double totalRevenue = 0.0;
      int currentRow = 4;
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

        final numCell = salesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
        numCell.cellStyle = numberStyle;
        currentRow++;
      }

      salesSheet.appendRow([TextCellValue('')]);
      salesSheet.appendRow([
        TextCellValue('GRAND TOTAL REVENUE:'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(totalRevenue),
      ]);
      final totalCell = salesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow + 1));
      totalCell.cellStyle = totalStyle;
    }

    // 2. Udhaar Book Sheet
    if (includeUdhaar) {
      final udhaarSheet = excel['Udhaar Book'];
      udhaarSheet.setColumnWidth(0, 16.0);
      udhaarSheet.setColumnWidth(1, 30.0);
      udhaarSheet.setColumnWidth(2, 20.0);
      udhaarSheet.setColumnWidth(3, 24.0);
      udhaarSheet.setColumnWidth(4, 20.0);

      udhaarSheet.appendRow([TextCellValue('SHUBH TRADERS - OUTSTANDING UDHAAR LEDGER')]);
      udhaarSheet.appendRow([TextCellValue('Generated on: ${Formatters.dateTime(DateTime.now())}')]);
      udhaarSheet.appendRow([TextCellValue('')]);

      udhaarSheet.appendRow([
        TextCellValue('Customer ID'),
        TextCellValue('Customer Name'),
        TextCellValue('Contact Number'),
        TextCellValue('Outstanding Due (Rs)'),
        TextCellValue('Customer Since'),
      ]);

      for (int c = 0; c < 5; c++) {
        final cell = udhaarSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
        cell.cellStyle = headerStyle;
      }

      final customers = await (_db.select(_db.customers)
            ..where((c) => c.totalDue.isBiggerThanValue(0.0))
            ..orderBy([(c) => OrderingTerm.desc(c.totalDue)]))
          .get();

      double totalUdhaar = 0.0;
      int uRow = 4;
      for (final c in customers) {
        totalUdhaar += c.totalDue;
        udhaarSheet.appendRow([
          IntCellValue(c.id),
          TextCellValue(c.name),
          TextCellValue(c.phone),
          DoubleCellValue(c.totalDue),
          TextCellValue(Formatters.date(c.createdAt)),
        ]);
        final amtCell = udhaarSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: uRow));
        amtCell.cellStyle = numberStyle;
        uRow++;
      }

      udhaarSheet.appendRow([TextCellValue('')]);
      udhaarSheet.appendRow([
        TextCellValue('TOTAL PENDING UDHAAR:'),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(totalUdhaar),
      ]);
      final sumCell = udhaarSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: uRow + 1));
      sumCell.cellStyle = totalStyle;
    }

    // 3. Inventory Sheet
    if (includeInventory) {
      final invSheet = excel['Inventory Status'];
      invSheet.setColumnWidth(0, 14.0);
      invSheet.setColumnWidth(1, 24.0);
      invSheet.setColumnWidth(2, 28.0);
      invSheet.setColumnWidth(3, 22.0);
      invSheet.setColumnWidth(4, 18.0);
      invSheet.setColumnWidth(5, 16.0);
      invSheet.setColumnWidth(6, 14.0);
      invSheet.setColumnWidth(7, 20.0);
      invSheet.setColumnWidth(8, 20.0);
      invSheet.setColumnWidth(9, 22.0);
      invSheet.setColumnWidth(10, 20.0);

      invSheet.appendRow([TextCellValue('SHUBH TRADERS - CURRENT STOCK SUMMARY')]);
      invSheet.appendRow([TextCellValue('As of: ${Formatters.dateTime(DateTime.now())}')]);
      invSheet.appendRow([TextCellValue('')]);

      invSheet.appendRow([
        TextCellValue('Item ID'),
        TextCellValue('Brand'),
        TextCellValue('Item Name (EN)'),
        TextCellValue('Item Name (HI)'),
        TextCellValue('Category'),
        TextCellValue('Current Stock'),
        TextCellValue('Unit'),
        TextCellValue('Purchase Rate (Rs)'),
        TextCellValue('Selling Rate (Rs)'),
        TextCellValue('Stock Valuation (Rs)'),
        TextCellValue('Stock Status'),
      ]);

      for (int c = 0; c < 11; c++) {
        final cell = invSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
        cell.cellStyle = headerStyle;
      }

      final itemsQuery = await _db.select(_db.items).join([
        leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.items.categoryId)),
      ]).get();

      double totalValuation = 0.0;
      int iRow = 4;
      for (final row in itemsQuery) {
        final it = row.readTable(_db.items);
        final cat = row.readTableOrNull(_db.categories);
        final valuation = it.stockQty * it.purchasePrice;
        totalValuation += valuation;

        invSheet.appendRow([
          IntCellValue(it.id),
          TextCellValue(it.brand ?? '-'),
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

        final valCell = invSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: iRow));
        valCell.cellStyle = numberStyle;
        iRow++;
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
        TextCellValue(''),
        DoubleCellValue(totalValuation),
      ]);
      final totalValCell = invSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: iRow + 1));
      totalValCell.cellStyle = totalStyle;
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

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
