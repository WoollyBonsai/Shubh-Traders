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
  Future<int> addCategory(String nameEn, String nameHi, {required int userId, required String username}) async {
    final catId = await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        nameEn: nameEn.trim(),
        nameHi: nameHi.trim(),
      ),
    );

    await _db.logAudit(
      userId: userId,
      username: username,
      actionType: 'CATEGORY_CREATED',
      entityId: 'CAT-$catId',
      details: 'User "$username" created new product category: "$nameEn / $nameHi".',
    );

    return catId;
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
    String? brand,
    String? imagePath,
    required int userId,
    required String username,
  }) async {
    final itemId = await _db.into(_db.items).insert(
      ItemsCompanion.insert(
        categoryId: categoryId,
        nameEn: nameEn.trim(),
        nameHi: nameHi.trim(),
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        stockQty: Value(stockQty),
        unit: Value(unit.trim()),
        lowStockThreshold: Value(lowStockThreshold),
        brand: Value(brand?.trim()),
        imagePath: Value(imagePath?.trim()),
      ),
    );

    await _db.logAudit(
      userId: userId,
      username: username,
      actionType: 'ITEM_CREATED',
      entityId: 'ITEM-$itemId',
      details: 'User "$username" created item "$nameEn" (${brand ?? "No Brand"}, $stockQty $unit @ ₹$sellingPrice).',
    );

    return itemId;
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
    String? brand,
    String? imagePath,
    required int userId,
    required String username,
  }) async {
    final updated = await (_db.update(_db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        categoryId: Value(categoryId),
        nameEn: Value(nameEn.trim()),
        nameHi: Value(nameHi.trim()),
        purchasePrice: Value(purchasePrice),
        sellingPrice: Value(sellingPrice),
        unit: Value(unit.trim()),
        lowStockThreshold: Value(lowStockThreshold),
        brand: Value(brand?.trim()),
        imagePath: Value(imagePath?.trim()),
      ),
    ).then((count) => count > 0);

    if (updated) {
      await _db.logAudit(
        userId: userId,
        username: username,
        actionType: 'ITEM_UPDATED',
        entityId: 'ITEM-$id',
        details: 'User "$username" updated details for product "$nameEn" (Brand: ${brand ?? "General"}).',
      );
    }

    return updated;
  }

  Future<void> restock({
    required int itemId,
    required double addedQty,
    double? newPurchasePrice,
    double? newSellingPrice,
    required int userId,
    required String username,
  }) {
    return _db.restockItem(
      itemId: itemId,
      addedQty: addedQty,
      newPurchasePrice: newPurchasePrice,
      newSellingPrice: newSellingPrice,
      userId: userId,
      username: username,
    );
  }

  Future<int> deleteItem(int id, {required int userId, required String username, required String itemName}) async {
    final count = await (_db.delete(_db.items)..where((i) => i.id.equals(id))).go();
    if (count > 0) {
      await _db.logAudit(
        userId: userId,
        username: username,
        actionType: 'ITEM_DELETED',
        entityId: 'ITEM-$id',
        details: 'User "$username" DELETED product "$itemName" (ID: #$id) from inventory.',
      );
    }
    return count;
  }
}

final inventoryNotifierProvider = Provider<InventoryNotifier>((ref) {
  final db = ref.watch(databaseProvider);
  return InventoryNotifier(db);
});
