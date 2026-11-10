import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Tables Blueprint
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()(); // 'Admin' or 'Staff'
  TextColumn get fullName => text().withDefault(const Constant('User'))();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  RealColumn get totalDue => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nameEn => text()();
  TextColumn get nameHi => text()();
}

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get nameEn => text()();
  TextColumn get nameHi => text()();
  RealColumn get purchasePrice => real()();
  RealColumn get sellingPrice => real()();
  RealColumn get stockQty => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().withDefault(const Constant('Bags'))();
  RealColumn get lowStockThreshold => real().withDefault(const Constant(10.0))();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  RealColumn get totalAmount => real()();
  TextColumn get paymentMethod => text()(); // 'Cash', 'Online', 'Udhaar'
  TextColumn get notes => text().nullable()();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  RealColumn get qty => real()();
  RealColumn get soldPrice => real()();
  RealColumn get total => real()();
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  RealColumn get amountPaid => real()();
  TextColumn get paymentMethod => text()(); // 'Cash', 'Online'
  TextColumn get notes => text().nullable()();
}

class CartItemPayload {
  final int itemId;
  final double qty;
  final double soldPrice;
  final double total;

  CartItemPayload({
    required this.itemId,
    required this.qty,
    required this.soldPrice,
    required this.total,
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'shubh_traders_v1.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [Users, Customers, Categories, Items, Sales, SaleItems, Payments])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // Initialize and seed default data if empty
  Future<void> seedDefaultDataIfNeeded(String Function(String) hashFunc) async {
    final userCount = await (select(users)..limit(1)).get();
    if (userCount.isEmpty) {
      // Seed Admin & Staff
      await into(users).insert(
        UsersCompanion.insert(
          username: 'admin',
          passwordHash: hashFunc('1234'),
          role: 'Admin',
          fullName: const Value('Admin (व्यवस्थापक)'),
        ),
      );
      await into(users).insert(
        UsersCompanion.insert(
          username: 'staff',
          passwordHash: hashFunc('1111'),
          role: 'Staff',
          fullName: const Value('Sales Staff (कर्मचारी)'),
        ),
      );

      // Seed Categories
      final catCementId = await into(categories).insert(
        CategoriesCompanion.insert(
          nameEn: 'Cement',
          nameHi: 'सीमेंट',
        ),
      );
      final catSteelId = await into(categories).insert(
        CategoriesCompanion.insert(
          nameEn: 'TMT Steel Bars',
          nameHi: 'सरिया (TMT)',
        ),
      );
      final catSandId = await into(categories).insert(
        CategoriesCompanion.insert(
          nameEn: 'Sand & Aggregate',
          nameHi: 'रेत एवं गिट्टी',
        ),
      );
      final catBricksId = await into(categories).insert(
        CategoriesCompanion.insert(
          nameEn: 'Bricks & Blocks',
          nameHi: 'ईंट एवं ब्लॉक',
        ),
      );
      final catPaintsId = await into(categories).insert(
        CategoriesCompanion.insert(
          nameEn: 'Paints & Chemicals',
          nameHi: 'पेंट एवं रसायन',
        ),
      );

      // Seed Items
      await into(items).insert(
        ItemsCompanion.insert(
          categoryId: catCementId,
          nameEn: 'UltraTech Cement (50kg)',
          nameHi: 'अल्ट्राटेक सीमेंट (50 किग्रा)',
          purchasePrice: 340.0,
          sellingPrice: 380.0,
          stockQty: const Value(250.0),
          unit: const Value('Bags'),
          lowStockThreshold: const Value(20.0),
        ),
      );
      await into(items).insert(
        ItemsCompanion.insert(
          categoryId: catCementId,
          nameEn: 'Ambuja Cement (50kg)',
          nameHi: 'अंबुजा सीमेंट (50 किग्रा)',
          purchasePrice: 335.0,
          sellingPrice: 375.0,
          stockQty: const Value(180.0),
          unit: const Value('Bags'),
          lowStockThreshold: const Value(20.0),
        ),
      );
      await into(items).insert(
        ItemsCompanion.insert(
          categoryId: catSteelId,
          nameEn: 'Tata Tiscon 12mm TMT Bar',
          nameHi: 'टाटा टिस्कॉन 12mm सरिया',
          purchasePrice: 62.0,
          sellingPrice: 70.0,
          stockQty: const Value(1500.0),
          unit: const Value('Kg'),
          lowStockThreshold: const Value(100.0),
        ),
      );
      await into(items).insert(
        ItemsCompanion.insert(
          categoryId: catSteelId,
          nameEn: 'Jindal Panther 10mm TMT Bar',
          nameHi: 'जिंदल पैंथर्स 10mm सरिया',
          purchasePrice: 59.0,
          sellingPrice: 66.0,
          stockQty: const Value(1200.0),
          unit: const Value('Kg'),
          lowStockThreshold: const Value(100.0),
        ),
      );
      await into(items).insert(
        ItemsCompanion.insert(
          categoryId: catSandId,
          nameEn: 'River Sand (Trolley)',
          nameHi: 'नदी की रेत (ट्रॉली)',
          purchasePrice: 2800.0,
          sellingPrice: 3400.0,
          stockQty: const Value(8.0),
          unit: const Value('Trolley'),
          lowStockThreshold: const Value(3.0),
        ),
      );
      await into(items).insert(
        ItemsCompanion.insert(
          categoryId: catSandId,
          nameEn: 'Coarse Aggregate (10mm/20mm)',
          nameHi: 'गिट्टी (कंक्रीट)',
          purchasePrice: 35.0,
          sellingPrice: 42.0,
          stockQty: const Value(450.0),
          unit: const Value('Cft'),
          lowStockThreshold: const Value(50.0),
        ),
      );
      await into(items).insert(
        ItemsCompanion.insert(
          categoryId: catBricksId,
          nameEn: 'Red Clay Bricks (Class 1)',
          nameHi: 'लाल ईंट (क्लास 1)',
          purchasePrice: 7.5,
          sellingPrice: 9.5,
          stockQty: const Value(5000.0),
          unit: const Value('Pcs'),
          lowStockThreshold: const Value(1000.0),
        ),
      );
      await into(items).insert(
        ItemsCompanion.insert(
          categoryId: catPaintsId,
          nameEn: 'Asian Paints Primer (20L)',
          nameHi: 'एशियन पेंट्स प्राइमर (20 ली.)',
          purchasePrice: 1900.0,
          sellingPrice: 2250.0,
          stockQty: const Value(15.0),
          unit: const Value('Buckets'),
          lowStockThreshold: const Value(5.0),
        ),
      );

      // Seed Sample Customers
      await into(customers).insert(
        CustomersCompanion.insert(
          name: 'Ramesh Patel (ठेकेदार)',
          phone: '9876543210',
          totalDue: const Value(15500.0),
        ),
      );
      await into(customers).insert(
        CustomersCompanion.insert(
          name: 'Vikram Singh (बिल्डर)',
          phone: '9823456781',
          totalDue: const Value(42000.0),
        ),
      );
      await into(customers).insert(
        CustomersCompanion.insert(
          name: 'Suresh Kumar (ग्राहक)',
          phone: '9123456789',
          totalDue: const Value(0.0),
        ),
      );
    }
  }

  // Atomic POS checkout transaction
  Future<int> executeSaleTransaction({
    required int userId,
    int? customerId,
    required double totalAmount,
    required String paymentMethod,
    required List<CartItemPayload> cartItems,
    String? notes,
  }) {
    return transaction(() async {
      // 1. Insert into Sales
      final saleId = await into(sales).insert(
        SalesCompanion.insert(
          userId: userId,
          customerId: Value(customerId),
          totalAmount: totalAmount,
          paymentMethod: paymentMethod,
          notes: Value(notes),
          timestamp: Value(DateTime.now()),
        ),
      );

      // 2. Insert items and deduct stock atomically
      for (final item in cartItems) {
        await into(saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: saleId,
            itemId: item.itemId,
            qty: item.qty,
            soldPrice: item.soldPrice,
            total: item.total,
          ),
        );

        // Fetch current stock and deduct
        final current = await (select(items)..where((t) => t.id.equals(item.itemId))).getSingle();
        final newStock = current.stockQty - item.qty;
        await (update(items)..where((t) => t.id.equals(item.itemId))).write(
          ItemsCompanion(stockQty: Value(newStock)),
        );
      }

      // 3. Handle Udhaar
      if (paymentMethod == 'Udhaar' && customerId != null) {
        final cust = await (select(customers)..where((t) => t.id.equals(customerId))).getSingle();
        final newDue = cust.totalDue + totalAmount;
        await (update(customers)..where((t) => t.id.equals(customerId))).write(
          CustomersCompanion(totalDue: Value(newDue)),
        );
      }

      return saleId;
    });
  }

  // Atomic Udhaar payment receipt transaction
  Future<int> recordPaymentTransaction({
    required int customerId,
    required double amountPaid,
    required String paymentMethod,
    String? notes,
  }) {
    return transaction(() async {
      final paymentId = await into(payments).insert(
        PaymentsCompanion.insert(
          customerId: customerId,
          amountPaid: amountPaid,
          paymentMethod: paymentMethod,
          notes: Value(notes),
          timestamp: Value(DateTime.now()),
        ),
      );

      // Deduct from customer total_due
      final cust = await (select(customers)..where((t) => t.id.equals(customerId))).getSingle();
      final newDue = (cust.totalDue - amountPaid).clamp(0.0, double.infinity);
      await (update(customers)..where((t) => t.id.equals(customerId))).write(
        CustomersCompanion(totalDue: Value(newDue)),
      );

      return paymentId;
    });
  }

  // Stock Adjustment / Restock
  Future<void> restockItem({
    required int itemId,
    required double addedQty,
    double? newPurchasePrice,
    double? newSellingPrice,
  }) {
    return transaction(() async {
      final current = await (select(items)..where((t) => t.id.equals(itemId))).getSingle();
      await (update(items)..where((t) => t.id.equals(itemId))).write(
        ItemsCompanion(
          stockQty: Value(current.stockQty + addedQty),
          purchasePrice: newPurchasePrice != null ? Value(newPurchasePrice) : const Value.absent(),
          sellingPrice: newSellingPrice != null ? Value(newSellingPrice) : const Value.absent(),
        ),
      );
    });
  }
}
