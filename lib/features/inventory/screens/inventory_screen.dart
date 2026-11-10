import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/brand_logos.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';
import 'package:shubh_traders/features/inventory/providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  int? _selectedCategoryId;
  bool _showOnlyLowStock = false;

  void _showAddOrEditItemDialog(BuildContext context, [ItemWithCategory? existing]) {
    final categories = ref.read(categoriesStreamProvider).value ?? [];
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one category first')),
      );
      return;
    }

    final enCtrl = TextEditingController(text: existing?.item.nameEn ?? '');
    final hiCtrl = TextEditingController(text: existing?.item.nameHi ?? '');
    final purchaseCtrl = TextEditingController(text: existing != null ? existing.item.purchasePrice.toString() : '');
    final sellingCtrl = TextEditingController(text: existing != null ? existing.item.sellingPrice.toString() : '');
    final stockCtrl = TextEditingController(text: existing != null ? existing.item.stockQty.toString() : '0');
    final unitCtrl = TextEditingController(text: existing?.item.unit ?? 'Bags');
    final thresholdCtrl = TextEditingController(text: existing != null ? existing.item.lowStockThreshold.toString() : '10');
    String selectedBrand = existing?.item.brand ?? 'UltraTech';
    String? customImagePath = existing?.item.imagePath;
    int selectedCatId = existing?.item.categoryId ?? categories.first.id;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: DualText(
            en: existing == null ? 'Add New Product' : 'Edit Product',
            hi: existing == null ? 'नया उत्पाद जोड़ें' : 'उत्पाद संपादित करें',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo Selector
                    Row(
                      children: [
                        BrandBadgeWidget(brand: selectedBrand, imagePath: customImagePath, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedBrand,
                            decoration: const InputDecoration(labelText: 'Company / Brand (कंपनी / ब्रांड)'),
                            items: BrandLogos.presetBrands.map((b) {
                              return DropdownMenuItem<String>(
                                value: b.name,
                                child: Row(
                                  children: [
                                    Icon(b.icon, size: 16, color: b.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedBrand = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Upload Custom Item Image',
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          onPressed: () async {
                            final res = await FilePicker.pickFiles(type: FileType.image);
                            if (res.isNotEmpty && res.first.path != null) {
                              setState(() => customImagePath = res.first.path);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Category
                    DropdownButtonFormField<int>(
                      initialValue: selectedCatId,
                      decoration: const InputDecoration(labelText: 'Category / श्रेणी'),
                      items: categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text('${c.nameEn} (${c.nameHi})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCatId = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Name EN & HI
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: enCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Item Name (English)',
                              hintText: 'e.g. UltraTech Cement 50kg',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: hiCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Item Name (Hindi / हिन्दी)',
                              hintText: 'उदा. अल्ट्राटेक सीमेंट',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Prices
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: purchaseCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Purchase Rate / खरीद दर (₹)',
                              prefixText: '₹ ',
                            ),
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid price' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: sellingCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Selling Rate / बिक्री दर (₹)',
                              prefixText: '₹ ',
                            ),
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid price' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stock, Unit & Threshold
                    Row(
                      children: [
                        if (existing == null) ...[
                          Expanded(
                            child: TextFormField(
                              controller: stockCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Initial Stock / स्टॉक'),
                              validator: (v) => double.tryParse(v ?? '') == null ? 'Enter number' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: TextFormField(
                            controller: unitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Unit / इकाई',
                              hintText: 'Bags, Kg, Pcs, Cft, etc.',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: thresholdCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Low Stock Alert Limit'),
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Enter number' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel / रद्द करें'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final inv = ref.read(inventoryNotifierProvider);
                final auth = ref.read(authProvider);
                final user = auth.currentUser;
                final purchase = double.parse(purchaseCtrl.text);
                final selling = double.parse(sellingCtrl.text);
                final unit = unitCtrl.text;
                final threshold = double.parse(thresholdCtrl.text);

                if (existing == null) {
                  final initialStock = double.parse(stockCtrl.text);
                  await inv.addItem(
                    categoryId: selectedCatId,
                    nameEn: enCtrl.text,
                    nameHi: hiCtrl.text,
                    purchasePrice: purchase,
                    sellingPrice: selling,
                    stockQty: initialStock,
                    unit: unit,
                    lowStockThreshold: threshold,
                    brand: selectedBrand,
                    imagePath: customImagePath,
                    userId: user?.id ?? 1,
                    username: user?.username ?? 'Staff',
                  );
                } else {
                  await inv.updateItem(
                    id: existing.item.id,
                    categoryId: selectedCatId,
                    nameEn: enCtrl.text,
                    nameHi: hiCtrl.text,
                    purchasePrice: purchase,
                    sellingPrice: selling,
                    unit: unit,
                    lowStockThreshold: threshold,
                    brand: selectedBrand,
                    imagePath: customImagePath,
                    userId: user?.id ?? 1,
                    username: user?.username ?? 'Staff',
                  );
                }
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
              child: Text(existing == null ? 'Add Product' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestockDialog(BuildContext context, ItemWithCategory itemWithCat) {
    final qtyCtrl = TextEditingController();
    final purchaseCtrl = TextEditingController(text: itemWithCat.item.purchasePrice.toString());
    final sellingCtrl = TextEditingController(text: itemWithCat.item.sellingPrice.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: DualText(
          en: 'Restock: ${itemWithCat.item.nameEn}',
          hi: 'स्टॉक जोड़ें: ${itemWithCat.item.nameHi}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BrandBadgeWidget(brand: itemWithCat.item.brand, imagePath: itemWithCat.item.imagePath, size: 36),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(itemWithCat.item.nameEn, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Current Stock: ${Formatters.qty(itemWithCat.item.stockQty, itemWithCat.item.unit)}',
                            style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Quantity to Add / जोड़ने योग्य मात्रा (${itemWithCat.item.unit})',
                    prefixIcon: const Icon(Icons.add_shopping_cart),
                  ),
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return 'Enter a positive quantity';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: purchaseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Rate / खरीद दर (₹)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sellingCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Selling Rate / बिक्री दर (₹)',
                    prefixText: '₹ ',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final qty = double.parse(qtyCtrl.text);
              final purchase = double.tryParse(purchaseCtrl.text);
              final selling = double.tryParse(sellingCtrl.text);
              final auth = ref.read(authProvider);
              final user = auth.currentUser;

              await ref.read(inventoryNotifierProvider).restock(
                    itemId: itemWithCat.item.id,
                    addedQty: qty,
                    newPurchasePrice: purchase,
                    newSellingPrice: selling,
                    userId: user?.id ?? 1,
                    username: user?.username ?? 'Staff',
                  );

              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully restocked ${itemWithCat.item.nameEn}'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
            child: const Text('Add to Stock'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteItem(BuildContext context, ItemWithCategory itemWithCat) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const DualText(
          en: 'Delete Item',
          hi: 'आइटम हटाएं',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
        ),
        content: Text('Are you sure you want to delete "${itemWithCat.item.nameEn}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = ref.read(authProvider);
              final user = auth.currentUser;
              await ref.read(inventoryNotifierProvider).deleteItem(
                    itemWithCat.item.id,
                    userId: user?.id ?? 1,
                    username: user?.username ?? 'Staff',
                    itemName: itemWithCat.item.nameEn,
                  );
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsWithCategoryStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'Inventory & Stock Management',
          hi: 'इन्वेंटरी एवं स्टॉक प्रबंधन',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddOrEditItemDialog(context),
              icon: const Icon(Icons.add_box),
              label: const DualText.inline(en: 'Add Item', hi: 'नया उत्पाद'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Filter / Search Toolbar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by item name or brand...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: categoriesAsync.when(
                        data: (cats) => DropdownButtonFormField<int?>(
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(labelText: 'Category Filter'),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('All Categories (सभी श्रेणियां)')),
                            ...cats.map((c) => DropdownMenuItem<int?>(
                                  value: c.id,
                                  child: Text('${c.nameEn} (${c.nameHi})'),
                                )),
                          ],
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      selected: _showOnlyLowStock,
                      label: const DualText.inline(en: 'Low Stock Only', hi: 'केवल कम स्टॉक'),
                      avatar: const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.warningAmber),
                      onSelected: (val) => setState(() => _showOnlyLowStock = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products Table with Responsive Horizontal Scroll
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  final filtered = items.where((i) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        i.item.nameEn.toLowerCase().contains(_searchQuery) ||
                        i.item.nameHi.toLowerCase().contains(_searchQuery) ||
                        (i.item.brand?.toLowerCase().contains(_searchQuery) ?? false);
                    final matchesCategory = _selectedCategoryId == null || i.item.categoryId == _selectedCategoryId;
                    final matchesLowStock = !_showOnlyLowStock || i.isLowStock;
                    return matchesSearch && matchesCategory && matchesLowStock;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No products found matching filters.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return Card(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                  columnSpacing: 24,
                                  columns: const [
                                    DataColumn(label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Item / वस्तु', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Category / श्रेणी', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Stock / स्टॉक', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Purchase Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Selling Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: filtered.map((itemWithCat) {
                                    final item = itemWithCat.item;
                                    final isLow = itemWithCat.isLowStock;

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          BrandBadgeWidget(
                                            brand: item.brand,
                                            imagePath: item.imagePath,
                                            size: 32,
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(item.nameEn, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text(item.nameHi, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            itemWithCat.category != null ? itemWithCat.category!.nameEn : 'N/A',
                                            style: const TextStyle(color: Colors.blueGrey),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                Formatters.qty(item.stockQty, item.unit),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isLow ? AppTheme.dangerRed : Colors.black87,
                                                ),
                                              ),
                                              if (isLow) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade100,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'LOW',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(Formatters.currency(item.purchasePrice))),
                                        DataCell(
                                          Text(
                                            Formatters.currency(item.sellingPrice),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => _showRestockDialog(context, itemWithCat),
                                                icon: const Icon(Icons.add, size: 14),
                                                label: const Text('Restock', style: TextStyle(fontSize: 12)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.successGreen,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                                                tooltip: 'Edit Details',
                                                onPressed: () => _showAddOrEditItemDialog(context, itemWithCat),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                                tooltip: 'Delete',
                                                onPressed: () => _confirmDeleteItem(context, itemWithCat),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
