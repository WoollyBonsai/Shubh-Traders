import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';

class ReceiptPdfGenerator {
  static Future<Uint8List> generateReceiptPdf({
    required Sale sale,
    required List<SaleItemWithDetails> items,
    required Customer? customer,
    required User user,
    required AppSettings settings,
    bool isThermal = false,
  }) async {
    final doc = pw.Document();

    final pageFormat = isThermal
        ? const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm)
        : PdfPageFormat.a4;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          if (isThermal) {
            return _buildThermalLayout(sale, items, customer, user, settings);
          } else {
            return _buildA4Layout(sale, items, customer, user, settings);
          }
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildA4Layout(
    Sale sale,
    List<SaleItemWithDetails> items,
    Customer? customer,
    User user,
    AppSettings settings,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SHUBH TRADERS',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.Text('शुभ ट्रेडर्स - Building Materials & Hardware', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(settings.shopAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text('Contact: ${settings.shopPhone}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'TAX INVOICE / बिल',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Invoice #: INV-${sale.id.toString().padLeft(5, '0')}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('Date: ${Formatters.date(sale.timestamp)}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Time: ${Formatters.time(sale.timestamp)}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Billed by: ${user.fullName} (${user.username})', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColors.blue900),
          pw.SizedBox(height: 10),

          // Customer Details Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Billed To / ग्राहक विवरण:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text(customer != null ? customer.name : 'Counter Sale (Cash Customer)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    if (customer != null && customer.phone.isNotEmpty)
                      pw.Text('Contact: ${customer.phone}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Payment Mode:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: sale.paymentMethod == 'Udhaar'
                            ? PdfColors.red100
                            : (sale.paymentMethod == 'Cash' ? PdfColors.green100 : PdfColors.blue100),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        sale.paymentMethod.toUpperCase(),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: sale.paymentMethod == 'Udhaar'
                              ? PdfColors.red900
                              : (sale.paymentMethod == 'Cash' ? PdfColors.green900 : PdfColors.blue900),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Itemized Table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            headers: ['#', 'Item Description / विवरण', 'Qty', 'Rate (Rs)', 'Total (Rs)'],
            data: List.generate(items.length, (index) {
              final it = items[index];
              return [
                (index + 1).toString(),
                '${it.item.nameEn} / ${it.item.nameHi}',
                '${Formatters.qty(it.saleItem.qty)} ${it.item.unit}',
                it.saleItem.soldPrice.toStringAsFixed(2),
                it.saleItem.total.toStringAsFixed(2),
              ];
            }),
          ),
          pw.SizedBox(height: 12),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 250,
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Grand Total / कुल राशि:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text('Rs. ${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue900)),
                      ],
                    ),
                    if (sale.paymentMethod == 'Udhaar' && customer != null) ...[
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Customer Total Due / कुल बकाया:', style: pw.TextStyle(color: PdfColors.red900, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.Text('Rs. ${customer.totalDue.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.red900, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          pw.Spacer(),
          pw.Divider(color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Thank you for your business! / आपके सहयोग के लिए धन्यवाद!', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text('Authorized Signature: ___________________', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalLayout(
    Sale sale,
    List<SaleItemWithDetails> items,
    Customer? customer,
    User user,
    AppSettings settings,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('SHUBH TRADERS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.Text('शुभ ट्रेडर्स', style: const pw.TextStyle(fontSize: 10)),
        pw.Text(settings.shopPhone, style: const pw.TextStyle(fontSize: 9)),
        pw.Divider(thickness: 0.8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Inv: #${sale.id}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text(Formatters.dateTime(sale.timestamp), style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        if (customer != null)
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text('Cust: ${customer.name}', style: const pw.TextStyle(fontSize: 8)),
          ),
        pw.Divider(thickness: 0.5),
        ...items.map((it) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text('${it.item.nameEn} (${Formatters.qty(it.saleItem.qty)} ${it.item.unit})', style: const pw.TextStyle(fontSize: 8)),
                ),
                pw.Text('Rs. ${it.saleItem.total.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          );
        }),
        pw.Divider(thickness: 0.8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.Text('Rs. ${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('MODE:', style: const pw.TextStyle(fontSize: 8)),
            pw.Text(sale.paymentMethod.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          ],
        ),
        if (sale.paymentMethod == 'Udhaar' && customer != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Due:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red900)),
              pw.Text('Rs. ${customer.totalDue.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red900)),
            ],
          ),
        pw.SizedBox(height: 6),
        pw.Text('Thank you! Visit again.', style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static Future<void> printReceipt({
    required Sale sale,
    required List<SaleItemWithDetails> items,
    required Customer? customer,
    required User user,
    required AppSettings settings,
    bool isThermal = false,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      sale: sale,
      items: items,
      customer: customer,
      user: user,
      settings: settings,
      isThermal: isThermal,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${sale.id}.pdf',
    );
  }
}

class SaleItemWithDetails {
  final SaleItem saleItem;
  final Item item;

  SaleItemWithDetails({required this.saleItem, required this.item});
}
