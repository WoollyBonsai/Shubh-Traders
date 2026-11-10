import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/billing/services/receipt_pdf_generator.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';

class ReceiptPreviewDialog extends ConsumerWidget {
  final Sale sale;
  final List<SaleItemWithDetails> items;
  final Customer? customer;
  final User user;

  const ReceiptPreviewDialog({
    super.key,
    required this.sale,
    required this.items,
    required this.customer,
    required this.user,
  });

  static Future<void> show(
    BuildContext context, {
    required Sale sale,
    required List<SaleItemWithDetails> items,
    required Customer? customer,
    required User user,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ReceiptPreviewDialog(
        sale: sale,
        items: items,
        customer: customer,
        user: user,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DualText(
            en: 'Invoice Preview #INV-${sale.id.toString().padLeft(5, '0')}',
            hi: 'बिल का पूर्वावलोकन #INV-${sale.id}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryNavy),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sale.paymentMethod == 'Udhaar'
                  ? AppTheme.dangerRed.withValues(alpha: 0.12)
                  : (sale.paymentMethod == 'Cash'
                      ? AppTheme.successGreen.withValues(alpha: 0.12)
                      : AppTheme.infoColor.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sale.paymentMethod.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: sale.paymentMethod == 'Udhaar'
                    ? AppTheme.dangerRed
                    : (sale.paymentMethod == 'Cash' ? AppTheme.successGreen : AppTheme.infoColor),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Store Header Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(settings.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy)),
                        Text(settings.shopAddress, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('Phone: ${settings.shopPhone}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Date: ${Formatters.date(sale.timestamp)}', style: const TextStyle(fontSize: 11)),
                        Text('Time: ${Formatters.time(sale.timestamp)}', style: const TextStyle(fontSize: 11)),
                        Text('Staff: ${user.fullName}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Customer row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer: ${customer?.name ?? 'Counter Sale'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (customer != null && customer!.phone.isNotEmpty)
                      Text('Mobile: ${customer!.phone}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Items Table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: AppTheme.primaryNavy),
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('Item / विवरण', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Total', textAlign: TextAlign.end, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  ...items.map((it) {
                    return TableRow(
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.item.nameEn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              Text(it.item.nameHi, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
                            ],
                          ),
                        ),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${Formatters.qty(it.saleItem.qty)} ${it.item.unit}', style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(Formatters.currency(it.saleItem.soldPrice), style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(Formatters.currency(it.saleItem.total), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),

              // Totals
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total / कुल देय:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          Formatters.currency(sale.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryNavy),
                        ),
                      ],
                    ),
                    if (sale.paymentMethod == 'Udhaar' && customer != null) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Customer Total Outstanding Due:', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(
                            Formatters.currency(customer!.totalDue),
                            style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        OutlinedButton.icon(
          onPressed: () async {
            await ReceiptPdfGenerator.printReceipt(
              sale: sale,
              items: items,
              customer: customer,
              user: user,
              settings: settings,
              isThermal: false,
            );
          },
          icon: const Icon(Icons.picture_as_pdf, size: 16),
          label: const Text('Windows Print / PDF'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await ReceiptPdfGenerator.printWithGoogleChrome(
              sale: sale,
              items: items,
              customer: customer,
              user: user,
              settings: settings,
            );
          },
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Print via Google Chrome (अनुशंसित)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
