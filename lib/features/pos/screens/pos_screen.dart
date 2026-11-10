import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/database/database_provider.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/brand_logos.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';
import 'package:shubh_traders/features/billing/services/receipt_pdf_generator.dart';
import 'package:shubh_traders/features/billing/widgets/receipt_preview_dialog.dart';
import 'package:shubh_traders/features/inventory/providers/inventory_provider.dart';
import 'package:shubh_traders/features/pos/providers/pos_provider.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchQuery = '';
  int? _selectedCategory;
  final TextEditingController _custNameCtrl = TextEditingController();
  final TextEditingController _custPhoneCtrl = TextEditingController();

  @override
  void dispose() {
    _custNameCtrl.dispose();
    _custPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout({bool viewReceiptFirst = false, bool printChrome = false, bool printWindows = false}) async {
    final pos = ref.read(posProvider);
    final auth = ref.read(authProvider);
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first to process sales')),
      );
      return;
    }

    if (pos.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Add products first.')),
      );
      return;
    }

    if (pos.paymentMethod == 'Udhaar') {
      if (pos.selectedCustomer == null &&
          (_custNameCtrl.text.trim().isEmpty || _custPhoneCtrl.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer Name & Phone are strictly required for Udhaar sales!'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }
    }

    ref.read(posProvider.notifier).setCustomerDetails(_custNameCtrl.text, _custPhoneCtrl.text);

    try {
      final saleId = await ref.read(posProvider.notifier).checkout(
            userId: user.id,
            username: user.username,
          );

      if (saleId != null && mounted) {
        _custNameCtrl.clear();
        _custPhoneCtrl.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale #$saleId completed successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        if (viewReceiptFirst) {
          _previewReceipt(saleId);
        } else if (printChrome) {
          _printBillChrome(saleId);
        } else if (printWindows) {
          _printBillWindows(saleId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout Error: $e'), backgroundColor: AppTheme.dangerRed),
        );
      }
    }
  }

  Future<void> _previewReceipt(int saleId) async {
    final db = ref.read(databaseProvider);
    final auth = ref.read(authProvider);

    final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();
    final saleItems = await (db.select(db.saleItems)..where((si) => si.saleId.equals(saleId))).get();

    Customer? customer;
    if (sale.customerId != null) {
      customer = await (db.select(db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingleOrNull();
    }

    final List<SaleItemWithDetails> itemsWithDetails = [];
    for (final si in saleItems) {
      final item = await (db.select(db.items)..where((i) => i.id.equals(si.itemId))).getSingle();
      itemsWithDetails.add(SaleItemWithDetails(saleItem: si, item: item));
    }

    if (mounted) {
      ReceiptPreviewDialog.show(
        context,
        sale: sale,
        items: itemsWithDetails,
        customer: customer,
        user: auth.currentUser!,
      );
    }
  }

  Future<void> _printBillChrome(int saleId) async {
    final db = ref.read(databaseProvider);
    final settings = ref.read(settingsProvider);
    final auth = ref.read(authProvider);

    final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();
    final saleItems = await (db.select(db.saleItems)..where((si) => si.saleId.equals(saleId))).get();

    Customer? customer;
    if (sale.customerId != null) {
      customer = await (db.select(db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingleOrNull();
    }

    final List<SaleItemWithDetails> itemsWithDetails = [];
    for (final si in saleItems) {
      final item = await (db.select(db.items)..where((i) => i.id.equals(si.itemId))).getSingle();
      itemsWithDetails.add(SaleItemWithDetails(saleItem: si, item: item));
    }

    await ReceiptPdfGenerator.printWithGoogleChrome(
      sale: sale,
      items: itemsWithDetails,
      customer: customer,
      user: auth.currentUser!,
      settings: settings,
    );
  }

  Future<void> _printBillWindows(int saleId) async {
    final db = ref.read(databaseProvider);
    final settings = ref.read(settingsProvider);
    final auth = ref.read(authProvider);

    final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();
    final saleItems = await (db.select(db.saleItems)..where((si) => si.saleId.equals(saleId))).get();

    Customer? customer;
    if (sale.customerId != null) {
      customer = await (db.select(db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingleOrNull();
    }

    final List<SaleItemWithDetails> itemsWithDetails = [];
    for (final si in saleItems) {
      final item = await (db.select(db.items)..where((i) => i.id.equals(si.itemId))).getSingle();
      itemsWithDetails.add(SaleItemWithDetails(saleItem: si, item: item));
    }

    await ReceiptPdfGenerator.printReceipt(
      sale: sale,
      items: itemsWithDetails,
      customer: customer,
      user: auth.currentUser!,
      settings: settings,
      isThermal: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);
    final itemsAsync = ref.watch(itemsWithCategoryStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final customersAsync = ref.watch(allCustomersStreamProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 950;

          return Flex(
            direction: isCompact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LEFT PANEL: Product Catalog
              Expanded(
                flex: isCompact ? 1 : 6,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search & Filter Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search materials by English or Hindi name...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category Filter Chips
                      categoriesAsync.when(
                        data: (categories) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: const Text('All / सभी'),
                                    selected: _selectedCategory == null,
                                    onSelected: (sel) {
                                      if (sel) setState(() => _selectedCategory = null);
                                    },
                                  ),
                                ),
                                ...categories.map((cat) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text('${cat.nameEn} (${cat.nameHi})'),
                                      selected: _selectedCategory == cat.id,
                                      onSelected: (sel) {
                                        setState(() => _selectedCategory = sel ? cat.id : null);
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(height: 36),
                        error: (_, _) => const SizedBox(),
                      ),
                      const SizedBox(height: 14),

                      // Products Grid with Brand Badges
                      Expanded(
                        child: itemsAsync.when(
                          data: (items) {
                            final filtered = items.where((it) {
                              final matchCategory = _selectedCategory == null || it.item.categoryId == _selectedCategory;
                              final matchQuery = _searchQuery.isEmpty ||
                                  it.item.nameEn.toLowerCase().contains(_searchQuery) ||
                                  it.item.nameHi.toLowerCase().contains(_searchQuery) ||
                                  (it.item.brand?.toLowerCase().contains(_searchQuery) ?? false);
                              return matchCategory && matchQuery;
                            }).toList();

                            if (filtered.isEmpty) {
                              return const Center(child: Text('No products match your search.'));
                            }

                            return GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 280,
                                mainAxisExtent: 155,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final itemWithCat = filtered[index];
                                final item = itemWithCat.item;
                                final isLow = itemWithCat.isLowStock;
                                final isOutOfStock = item.stockQty <= 0;

                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isOutOfStock
                                          ? AppTheme.dangerRed.withValues(alpha: 0.3)
                                          : (isLow ? AppTheme.warningAmber.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
                                      width: isLow ? 1.5 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: isOutOfStock
                                        ? () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${item.nameEn} is Out of Stock!')),
                                            );
                                          }
                                        : () {
                                            ref.read(posProvider.notifier).addItem(item);
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Brand Badge
                                              BrandBadgeWidget(
                                                brand: item.brand,
                                                imagePath: item.imagePath,
                                                size: 36,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.nameEn,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      item.nameHi,
                                                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (item.brand != null && item.brand!.isNotEmpty)
                                                      Text(
                                                        item.brand!,
                                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                Formatters.currency(item.sellingPrice),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppTheme.primaryNavy,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isOutOfStock
                                                      ? Colors.red.shade100
                                                      : (isLow ? Colors.amber.shade100 : Colors.green.shade50),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  Formatters.qty(item.stockQty, item.unit),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isOutOfStock
                                                        ? AppTheme.dangerRed
                                                        : (isLow ? AppTheme.accentGold : AppTheme.successGreen),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(child: Text('Error: $err')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // RIGHT PANEL: Cart, Customer & Checkout
              Expanded(
                flex: isCompact ? 1 : 4,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer Header Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const DualText(
                              en: 'Customer Information',
                              hi: 'ग्राहक की जानकारी',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 8),

                            // Customer dropdown
                            customersAsync.when(
                              data: (customers) {
                                return DropdownButtonFormField<Customer?>(
                                  initialValue: posState.selectedCustomer,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Customer',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: [
                                    const DropdownMenuItem<Customer?>(
                                      value: null,
                                      child: Text('➕ Walk-in Customer (नया ग्राहक)'),
                                    ),
                                    ...customers.map((c) {
                                      return DropdownMenuItem<Customer?>(
                                        value: c,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${c.name} (${c.phone})', overflow: TextOverflow.ellipsis),
                                            if (c.totalDue > 0)
                                              Text(
                                                'Due: ₹${c.totalDue.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: AppTheme.dangerRed,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (cust) {
                                    ref.read(posProvider.notifier).selectCustomer(cust);
                                    if (cust != null) {
                                      _custNameCtrl.text = cust.name;
                                      _custPhoneCtrl.text = cust.phone;
                                    } else {
                                      _custNameCtrl.clear();
                                      _custPhoneCtrl.clear();
                                    }
                                  },
                                );
                              },
                              loading: () => const SizedBox(),
                              error: (_, _) => const SizedBox(),
                            ),

                            // Walk-in fields
                            if (posState.selectedCustomer == null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _custNameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Customer Name / नाम',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (v) => ref.read(posProvider.notifier).setCustomerDetails(v, _custPhoneCtrl.text),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _custPhoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone / मोबाइल',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (v) => ref.read(posProvider.notifier).setCustomerDetails(_custNameCtrl.text, v),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Outstanding Due Alert
                            if (posState.selectedCustomer != null && posState.selectedCustomer!.totalDue > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Existing Outstanding Udhaar:', style: TextStyle(fontSize: 12, color: AppTheme.dangerRed, fontWeight: FontWeight.w600)),
                                    Text(
                                      Formatters.currency(posState.selectedCustomer!.totalDue),
                                      style: const TextStyle(fontSize: 14, color: AppTheme.dangerRed, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cart Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DualText.inline(
                            en: 'Cart Items (${posState.itemCount})',
                            hi: 'चयनित सामग्री',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (posState.cart.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => ref.read(posProvider.notifier).clear(),
                              icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                              label: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                        ],
                      ),
                      const Divider(height: 10),

                      // Cart Items List
                      Expanded(
                        child: posState.cart.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Cart is empty. Click items on the left to add.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: posState.cart.length,
                                separatorBuilder: (context, _) => const Divider(height: 8),
                                itemBuilder: (context, index) {
                                  final item = posState.cart[index];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        // Item details
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.item.nameEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text(item.item.nameHi, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                            ],
                                          ),
                                        ),

                                        // Qty Stepper
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                                              onPressed: () => ref.read(posProvider.notifier).updateQuantity(item.item.id, item.qty - 1),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                              child: Text(
                                                Formatters.qty(item.qty),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline, size: 20),
                                              onPressed: () => ref.read(posProvider.notifier).updateQuantity(item.item.id, item.qty + 1),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),

                                        // Editable Selling Price
                                        SizedBox(
                                          width: 80,
                                          child: TextFormField(
                                            initialValue: item.soldPrice.toStringAsFixed(0),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(
                                              prefixText: '₹',
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                            ),
                                            style: const TextStyle(fontSize: 12),
                                            onChanged: (val) {
                                              final p = double.tryParse(val);
                                              if (p != null && p >= 0) {
                                                ref.read(posProvider.notifier).updatePrice(item.item.id, p);
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Line total
                                        SizedBox(
                                          width: 75,
                                          child: Text(
                                            Formatters.currency(item.total),
                                            textAlign: TextAlign.end,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),

                                        // Remove
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                          onPressed: () => ref.read(posProvider.notifier).removeItem(item.item.id),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // If ONLINE Payment selected: Show UPI QR Code
                      if (posState.paymentMethod == 'Online') ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              if (settings.paymentQrPath != null && File(settings.paymentQrPath!).existsSync())
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(settings.paymentQrPath!),
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.qr_code_2, size: 36, color: Colors.blue),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Scan & Pay via any UPI App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryNavy)),
                                    const SizedBox(height: 2),
                                    Text(
                                      settings.paymentQrPath != null
                                          ? 'Shop QR Code active'
                                          : 'Upload your shop UPI QR in Settings',
                                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Bottom Checkout Controls
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Grand Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const DualText(
                                  en: 'Total Payable',
                                  hi: 'कुल देय राशि',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  Formatters.currency(posState.grandTotal),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Payment Mode Switcher
                            Row(
                              children: [
                                Expanded(
                                  child: _PaymentModeButton(
                                    label: 'Cash (नकद)',
                                    icon: Icons.attach_money,
                                    isSelected: posState.paymentMethod == 'Cash',
                                    selectedColor: AppTheme.successGreen,
                                    onTap: () => ref.read(posProvider.notifier).setPaymentMethod('Cash'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _PaymentModeButton(
                                    label: 'Online / UPI',
                                    icon: Icons.qr_code_scanner,
                                    isSelected: posState.paymentMethod == 'Online',
                                    selectedColor: AppTheme.infoColor,
                                    onTap: () => ref.read(posProvider.notifier).setPaymentMethod('Online'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _PaymentModeButton(
                                    label: 'Udhaar (उधार)',
                                    icon: Icons.account_balance_wallet_outlined,
                                    isSelected: posState.paymentMethod == 'Udhaar',
                                    selectedColor: AppTheme.dangerRed,
                                    onTap: () => ref.read(posProvider.notifier).setPaymentMethod('Udhaar'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Action Buttons: View Receipt First & Quick Prints
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: posState.isProcessing ? null : () => _handleCheckout(viewReceiptFirst: true),
                                    icon: const Icon(Icons.receipt_long, size: 16),
                                    label: const Text('View Bill First', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: posState.isProcessing ? null : () => _handleCheckout(printChrome: true),
                                    icon: const Icon(Icons.print, size: 16),
                                    label: const Text('Print via Chrome', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _PaymentModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? selectedColor : const Color(0xFFCBD5E1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
