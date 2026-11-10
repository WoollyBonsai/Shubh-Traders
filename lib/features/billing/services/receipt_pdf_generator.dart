import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';

class ReceiptPdfGenerator {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  static Future<void> _loadFontsIfNeeded() async {
    if (_regularFont == null || _boldFont == null) {
      try {
        final regData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
        final boldData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
        _regularFont = pw.Font.ttf(regData);
        _boldFont = pw.Font.ttf(boldData);
      } catch (_) {
        // Fallback to standard Helvetica if font loading fails
        _regularFont = pw.Font.helvetica();
        _boldFont = pw.Font.helveticaBold();
      }
    }
  }

  static Future<Uint8List> generateReceiptPdf({
    required Sale sale,
    required List<SaleItemWithDetails> items,
    required Customer? customer,
    required User user,
    required AppSettings settings,
    bool isThermal = false,
  }) async {
    await _loadFontsIfNeeded();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _regularFont,
        bold: _boldFont,
      ),
    );

    // If QR image exists, load it
    pw.MemoryImage? qrImage;
    if (settings.paymentQrPath != null && File(settings.paymentQrPath!).existsSync()) {
      final bytes = await File(settings.paymentQrPath!).readAsBytes();
      qrImage = pw.MemoryImage(bytes);
    }

    final pageFormat = isThermal
        ? const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm)
        : PdfPageFormat.a4;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          if (isThermal) {
            return _buildThermalLayout(sale, items, customer, user, settings, qrImage);
          } else {
            return _buildA4Layout(sale, items, customer, user, settings, qrImage);
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
    pw.MemoryImage? qrImage,
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
                    settings.shopName.toUpperCase(),
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.Text('शुभ ट्रेडर्स - भवन निर्माण सामग्री एवं हार्डवेयर', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(settings.shopAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text('Phone: ${settings.shopPhone}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
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
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Invoice #: INV-${sale.id.toString().padLeft(5, '0')}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('Date: ${Formatters.date(sale.timestamp)}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Time: ${Formatters.time(sale.timestamp)}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Staff: ${user.fullName}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColors.blue900),
          pw.SizedBox(height: 8),

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
                      pw.Text('Mobile: ${customer.phone}', style: const pw.TextStyle(fontSize: 10)),
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
          pw.SizedBox(height: 14),

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
                '${it.item.nameEn} (${it.item.nameHi})',
                '${Formatters.qty(it.saleItem.qty)} ${it.item.unit}',
                it.saleItem.soldPrice.toStringAsFixed(2),
                it.saleItem.total.toStringAsFixed(2),
              ];
            }),
          ),
          pw.SizedBox(height: 12),

          // Totals and QR Code Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (qrImage != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Column(
                    children: [
                      pw.Image(qrImage, width: 75, height: 75),
                      pw.SizedBox(height: 2),
                      pw.Text('Scan to Pay via UPI', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                )
              else
                pw.SizedBox(),
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
              pw.Text('Thank you! Visit again / आपके सहयोग के लिए धन्यवाद!', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
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
    pw.MemoryImage? qrImage,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(settings.shopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.Text('शुभ ट्रेडर्स', style: const pw.TextStyle(fontSize: 10)),
        pw.Text(settings.shopPhone, style: const pw.TextStyle(fontSize: 9)),
        pw.Divider(thickness: 0.8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Inv: #INV-${sale.id}', style: const pw.TextStyle(fontSize: 8)),
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
        if (qrImage != null) ...[
          pw.SizedBox(height: 6),
          pw.Image(qrImage, width: 60, height: 60),
          pw.Text('Scan to Pay UPI', style: const pw.TextStyle(fontSize: 7)),
        ],
        pw.SizedBox(height: 6),
        pw.Text('Thank you! Visit again.', style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  // Open with Google Chrome's native print engine
  static Future<void> printWithGoogleChrome({
    required Sale sale,
    required List<SaleItemWithDetails> items,
    required Customer? customer,
    required User user,
    required AppSettings settings,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final htmlFile = File(p.join(tempDir.path, 'receipt_${sale.id}.html'));

    final rowsHtml = items.map((it) {
      return '''
        <tr>
          <td>${it.item.nameEn} <br><small style="color: #64748B;">${it.item.nameHi}</small></td>
          <td style="text-align: right;">${Formatters.qty(it.saleItem.qty)} ${it.item.unit}</td>
          <td style="text-align: right;">₹${it.saleItem.soldPrice.toStringAsFixed(2)}</td>
          <td style="text-align: right; font-weight: bold;">₹${it.saleItem.total.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }).join('\n');

    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="hi">
    <head>
      <meta charset="UTF-8">
      <title>Invoice #${sale.id} - Shubh Traders</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Arial, sans-serif; margin: 0; padding: 20px; color: #1E293B; }
        .receipt-container { max-width: 700px; margin: auto; border: 1px solid #CBD5E1; border-radius: 8px; padding: 30px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
        .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #0F2744; padding-bottom: 15px; }
        .title { color: #0F2744; font-size: 26px; font-weight: 800; margin: 0; }
        .subtitle { color: #64748B; font-size: 13px; margin: 4px 0; }
        .invoice-badge { background: #0F2744; color: white; padding: 4px 12px; border-radius: 4px; font-weight: bold; font-size: 13px; }
        .customer-card { background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 6px; padding: 12px; margin: 18px 0; display: flex; justify-content: space-between; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th { background: #0F2744; color: white; padding: 10px; text-align: left; font-size: 13px; }
        td { padding: 10px; border-bottom: 1px solid #E2E8F0; font-size: 13px; }
        .totals { margin-top: 20px; display: flex; justify-content: flex-end; }
        .totals-box { width: 280px; }
        .total-row { display: flex; justify-content: space-between; padding: 6px 0; font-size: 14px; }
        .grand-total { font-size: 18px; font-weight: 800; color: #0F2744; border-top: 2px solid #0F2744; padding-top: 8px; }
        .udhaar-due { color: #B91C1C; font-weight: bold; }
        @media print {
          body { padding: 0; }
          .receipt-container { border: none; box-shadow: none; width: 100%; max-width: 100%; }
          .no-print { display: none; }
        }
      </style>
      <script>
        window.onload = function() {
          setTimeout(function() { window.print(); }, 400);
        };
      </script>
    </head>
    <body>
      <div class="receipt-container">
        <div class="header">
          <div>
            <h1 class="title">${settings.shopName}</h1>
            <p class="subtitle">शुभ ट्रेडर्स • भवन निर्माण सामग्री एवं हार्डवेयर</p>
            <p class="subtitle">${settings.shopAddress}</p>
            <p class="subtitle">Contact: ${settings.shopPhone}</p>
          </div>
          <div style="text-align: right;">
            <span class="invoice-badge">TAX INVOICE / बिल</span>
            <p style="margin: 6px 0 2px; font-weight: bold;">INV-${sale.id.toString().padLeft(5, '0')}</p>
            <p class="subtitle">${Formatters.dateTime(sale.timestamp)}</p>
            <p class="subtitle">Staff: ${user.fullName}</p>
          </div>
        </div>

        <div class="customer-card">
          <div>
            <div style="font-size: 11px; color: #64748B; font-weight: bold;">BILLED TO / ग्राहक:</div>
            <div style="font-size: 14px; font-weight: bold; margin-top: 2px;">${customer?.name ?? 'Counter Sale'}</div>
            <div style="font-size: 12px; color: #64748B;">${customer?.phone ?? ''}</div>
          </div>
          <div style="text-align: right;">
            <div style="font-size: 11px; color: #64748B; font-weight: bold;">PAYMENT MODE:</div>
            <div style="font-size: 14px; font-weight: bold; color: ${sale.paymentMethod == 'Udhaar' ? '#B91C1C' : '#15803D'}; margin-top: 2px;">
              ${sale.paymentMethod.toUpperCase()}
            </div>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Item / विवरण</th>
              <th style="text-align: right;">Qty</th>
              <th style="text-align: right;">Rate</th>
              <th style="text-align: right;">Total</th>
            </tr>
          </thead>
          <tbody>
            $rowsHtml
          </tbody>
        </table>

        <div class="totals">
          <div class="totals-box">
            <div class="total-row grand-total">
              <span>Grand Total:</span>
              <span>₹${sale.totalAmount.toStringAsFixed(2)}</span>
            </div>
            ${sale.paymentMethod == 'Udhaar' && customer != null ? '''
              <div class="total-row udhaar-due">
                <span>Customer Total Due:</span>
                <span>₹${customer.totalDue.toStringAsFixed(2)}</span>
              </div>
            ''' : ''}
          </div>
        </div>

        <div style="margin-top: 35px; border-top: 1px solid #E2E8F0; padding-top: 15px; display: flex; justify-content: space-between; font-size: 12px; color: #64748B;">
          <span>Thank you for your business! / आपके सहयोग के लिए धन्यवाद!</span>
          <span>Authorized Signature</span>
        </div>
      </div>
    </body>
    </html>
    ''';

    await htmlFile.writeAsString(htmlContent);

    // Launch in Chrome directly
    try {
      await Process.start('cmd', ['/c', 'start', 'chrome', htmlFile.path]);
    } catch (_) {
      // Fallback: default browser
      await Process.start('cmd', ['/c', 'start', htmlFile.path]);
    }
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
