import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/database/database_provider.dart';

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.categories).watch();
});

class ItemWithCategory {
  final Item item;
  final Category? category;

  ItemWithCategory({required this.item, this.category});

  bool get isLowStock => item.stockQty <= item.lowStockThreshold;
}

final itemsWithCategoryStreamProvider = StreamProvider<List<ItemWithCategory>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.items).join([
    leftOuterJoin(db.categories, db.categories.id.equalsExp(db.items.categoryId)),
  ]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return ItemWithCategory(
        item: row.readTable(db.items),
        category: row.readTableOrNull(db.categories),
      );
    }).toList();
  });
});

final lowStockItemsStreamProvider = StreamProvider<List<ItemWithCategory>>((ref) {
  final allItems = ref.watch(itemsWithCategoryStreamProvider);
  return allItems.when(
    data: (items) => Stream.value(items.where((i) => i.isLowStock).toList()),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

class InventoryNotifier {
  final AppDatabase _db;
  InventoryNotifier(this._db);

  // Categories
  Future<int> addCategory(String nameEn, String nameHi) {
    return _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        nameEn: nameEn.trim(),
        nameHi: nameHi.trim(),
      ),
    );
  }

  Future<bool> updateCategory(int id, String nameEn, String nameHi) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        nameEn: Value(nameEn.trim()),
        nameHi: Value(nameHi.trim()),
      ),
    ).then((count) => count > 0);
  }

  Future<int> deleteCategory(int id) {
    return (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  // Items
  Future<int> addItem({
    required int categoryId,
    required String nameEn,
    required String nameHi,
    required double purchasePrice,
    required double sellingPrice,
    required double stockQty,
    required String unit,
    double lowStockThreshold = 10.0,
  }) {
    return _db.into(_db.items).insert(
      ItemsCompanion.insert(
        categoryId: categoryId,
        nameEn: nameEn.trim(),
        nameHi: nameHi.trim(),
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        stockQty: Value(stockQty),
        unit: Value(unit.trim()),
        lowStockThreshold: Value(lowStockThreshold),
      ),
    );
  }

  Future<bool> updateItem({
    required int id,
    required int categoryId,
    required String nameEn,
    required String nameHi,
    required double purchasePrice,
    required double sellingPrice,
    required String unit,
    required double lowStockThreshold,
  }) {
    return (_db.update(_db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        categoryId: Value(categoryId),
        nameEn: Value(nameEn.trim()),
        nameHi: Value(nameHi.trim()),
        purchasePrice: Value(purchasePrice),
        sellingPrice: Value(sellingPrice),
        unit: Value(unit.trim()),
        lowStockThreshold: Value(lowStockThreshold),
      ),
    ).then((count) => count > 0);
  }

  Future<void> restock({
    required int itemId,
    required double addedQty,
    double? newPurchasePrice,
    double? newSellingPrice,
  }) {
    return _db.restockItem(
      itemId: itemId,
      addedQty: addedQty,
      newPurchasePrice: newPurchasePrice,
      newSellingPrice: newSellingPrice,
    );
  }

  Future<int> deleteItem(int id) {
    return (_db.delete(_db.items)..where((i) => i.id.equals(id))).go();
  }
}

final inventoryNotifierProvider = Provider<InventoryNotifier>((ref) {
  final db = ref.watch(databaseProvider);
  return InventoryNotifier(db);
});
