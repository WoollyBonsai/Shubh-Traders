import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/database/database_provider.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/billing/services/receipt_pdf_generator.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';
import 'package:shubh_traders/features/ledger/providers/ledger_provider.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _paymentFilter = 'All';
  String _searchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  void _showSaleDetailDialog(BuildContext context, SaleWithCustomerAndUser saleWithDetails) async {
    final db = ref.read(databaseProvider);
    final saleItems = await (db.select(db.saleItems)..where((si) => si.saleId.equals(saleWithDetails.sale.id))).get();

    final List<SaleItemWithDetails> itemsWithDetails = [];
    for (final si in saleItems) {
      final item = await (db.select(db.items)..where((i) => i.id.equals(si.itemId))).getSingle();
      itemsWithDetails.add(SaleItemWithDetails(saleItem: si, item: item));
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DualText(
              en: 'Invoice #INV-${saleWithDetails.sale.id.toString().padLeft(5, '0')}',
              hi: 'बिल संख्या #${saleWithDetails.sale.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: saleWithDetails.sale.paymentMethod == 'Udhaar'
                    ? Colors.red.shade100
                    : (saleWithDetails.sale.paymentMethod == 'Cash' ? Colors.green.shade100 : Colors.blue.shade100),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                saleWithDetails.sale.paymentMethod.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: saleWithDetails.sale.paymentMethod == 'Udhaar'
                      ? Colors.red.shade900
                      : (saleWithDetails.sale.paymentMethod == 'Cash' ? Colors.green.shade900 : Colors.blue.shade900),
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer / ग्राहक:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          saleWithDetails.customer?.name ?? 'Counter Sale (Cash Customer)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (saleWithDetails.customer != null)
                          Text('Phone: ${saleWithDetails.customer!.phone}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Date & Time / दिनांक:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(Formatters.dateTime(saleWithDetails.sale.timestamp), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Billed by: ${saleWithDetails.user.fullName}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Items Table
                const Text('Items Purchased / खरीदी गई सामग्री:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Total', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ...itemsWithDetails.map((it) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: DualText(
                              en: it.item.nameEn,
                              hi: it.item.nameHi,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              subStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${Formatters.qty(it.saleItem.qty)} ${it.item.unit}', style: const TextStyle(fontSize: 12)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(Formatters.currency(it.saleItem.soldPrice), style: const TextStyle(fontSize: 12)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(Formatters.currency(it.saleItem.total), textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Grand Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total / कुल राशि:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      Formatters.currency(saleWithDetails.sale.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
          OutlinedButton.icon(
            onPressed: () async {
              final settings = ref.read(settingsProvider);
              await ReceiptPdfGenerator.printReceipt(
                sale: saleWithDetails.sale,
                items: itemsWithDetails,
                customer: saleWithDetails.customer,
                user: saleWithDetails.user,
                settings: settings,
                isThermal: false,
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Windows Print / PDF'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final settings = ref.read(settingsProvider);
              await ReceiptPdfGenerator.printWithGoogleChrome(
                sale: saleWithDetails.sale,
                items: itemsWithDetails,
                customer: saleWithDetails.customer,
                user: saleWithDetails.user,
                settings: settings,
              );
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print via Chrome (अनुशंसित)'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'Sales History & Transactions',
          hi: 'बिक्री इतिहास एवं लेनदेन',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Filter Toolbar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by Customer Name or Invoice #...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Payment Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentFilter,
                        decoration: const InputDecoration(labelText: 'Payment Method / माध्यम'),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Payment Modes (सभी)')),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash (नकद)')),
                          DropdownMenuItem(value: 'Online', child: Text('Online / UPI')),
                          DropdownMenuItem(value: 'Udhaar', child: Text('Udhaar (उधार)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentFilter = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Date quick filter
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _filterStartDate != null && _filterEndDate != null
                              ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
                              : null,
                        );
                        if (picked != null) {
                          setState(() {
                            _filterStartDate = picked.start;
                            _filterEndDate = picked.end;
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _filterStartDate != null && _filterEndDate != null
                            ? '${Formatters.date(_filterStartDate!)} - ${Formatters.date(_filterEndDate!)}'
                            : 'Select Date Range',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    if (_filterStartDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        tooltip: 'Clear Date Filter',
                        onPressed: () => setState(() {
                          _filterStartDate = null;
                          _filterEndDate = null;
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sales Table
            Expanded(
              child: salesAsync.when(
                data: (sales) {
                  final filtered = sales.where((s) {
                    final matchPayment = _paymentFilter == 'All' || s.sale.paymentMethod == _paymentFilter;
                    final custName = s.customer?.name.toLowerCase() ?? '';
                    final invId = 'inv-${s.sale.id.toString().padLeft(5, '0')}';
                    final matchSearch = _searchQuery.isEmpty ||
                        custName.contains(_searchQuery) ||
                        invId.contains(_searchQuery) ||
                        s.sale.id.toString().contains(_searchQuery);

                    bool matchDate = true;
                    if (_filterStartDate != null && _filterEndDate != null) {
                      final start = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
                      final end = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day, 23, 59, 59);
                      matchDate = s.sale.timestamp.isAfter(start) && s.sale.timestamp.isBefore(end);
                    }

                    return matchPayment && matchSearch && matchDate;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No sales found matching criteria.', style: TextStyle(color: Colors.grey)));
                  }

                  final totalRevenue = filtered.fold(0.0, (sum, s) => sum + s.sale.totalAmount);

                  return Card(
                    child: Column(
                      children: [
                        // Top Summary bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Showing ${filtered.length} transactions', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              Text('Filtered Revenue: ${Formatters.currency(totalRevenue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        Expanded(
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Customer / ग्राहक', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Amount / राशि', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filtered.map((item) {
                                  final s = item.sale;
                                  final isUdhaar = s.paymentMethod == 'Udhaar';

                                  return DataRow(
                                    cells: [
                                      DataCell(Text('INV-${s.id.toString().padLeft(5, '0')}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(Formatters.dateTime(s.timestamp), style: const TextStyle(fontSize: 12))),
                                      DataCell(
                                        Text(
                                          item.customer != null ? item.customer!.name : 'Counter Sale',
                                          style: TextStyle(
                                            fontWeight: item.customer != null ? FontWeight.w600 : FontWeight.normal,
                                            color: item.customer != null ? Colors.black87 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isUdhaar
                                                ? Colors.red.shade100
                                                : (s.paymentMethod == 'Cash' ? Colors.green.shade100 : Colors.blue.shade100),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            s.paymentMethod,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: isUdhaar
                                                  ? Colors.red.shade900
                                                  : (s.paymentMethod == 'Cash' ? Colors.green.shade900 : Colors.blue.shade900),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          Formatters.currency(s.totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataCell(Text(item.user.fullName, style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
                                      DataCell(
                                        OutlinedButton.icon(
                                          onPressed: () => _showSaleDetailDialog(context, item),
                                          icon: const Icon(Icons.visibility, size: 14),
                                          label: const Text('View Bill', style: TextStyle(fontSize: 11)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
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
