import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/ledger/providers/ledger_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _includeSales = true;
  bool _includeUdhaar = true;
  bool _includeInventory = true;
  bool _isExporting = false;
  String? _exportedFilePath;

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _exportedFilePath = null;
    });

    try {
      final path = await ref.read(ledgerNotifierProvider).exportToExcel(
            startDate: _startDate,
            endDate: _endDate,
            includeSales: _includeSales,
            includeUdhaar: _includeUdhaar,
            includeInventory: _includeInventory,
          );

      if (mounted) {
        setState(() {
          _exportedFilePath = path;
        });

        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel file saved successfully: $path'),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'Export Reports to Excel',
          hi: 'एक्सेल में रिपोर्ट निर्यात करें',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Center(
        child: Container(
          width: 650,
          margin: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.table_view_rounded, size: 36, color: Colors.green.shade800),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DualText(
                              en: 'Excel Spreadsheet Export (.xlsx)',
                              hi: 'एक्सेल स्प्रेडशीट निर्यात',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Generate structured reports directly to your Windows computer.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Date Range Picker
                  const DualText(
                    en: 'Report Date Range',
                    hi: 'रिपोर्ट की समय सीमा',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                              const SizedBox(width: 10),
                              Text(
                                '${Formatters.date(_startDate)}  →  ${Formatters.date(_endDate)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sheets selection
                  const DualText(
                    en: 'Include Worksheets in Workbook',
                    hi: 'वर्कशीट शामिल करें',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _includeSales,
                    onChanged: (v) => setState(() => _includeSales = v ?? true),
                    title: const DualText.inline(
                      en: 'Sales History',
                      hi: 'बिक्री का पूरा विवरण',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: const Text('All customer invoices, payment methods, staff details', style: TextStyle(fontSize: 12)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _includeUdhaar,
                    onChanged: (v) => setState(() => _includeUdhaar = v ?? true),
                    title: const DualText.inline(
                      en: 'Udhaar Ledger Book',
                      hi: 'उधार खाता बही',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: const Text('Customer balances, debt records, contact numbers', style: TextStyle(fontSize: 12)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _includeInventory,
                    onChanged: (v) => setState(() => _includeInventory = v ?? true),
                    title: const DualText.inline(
                      en: 'Inventory Stock Valuation',
                      hi: 'स्टॉक एवं मूल्यांकन',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: const Text('Current stock levels, purchase prices, valuations, low stock alerts', style: TextStyle(fontSize: 12)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Export Action Button
                  ElevatedButton.icon(
                    onPressed: (_isExporting || (!_includeSales && !_includeUdhaar && !_includeInventory))
                        ? null
                        : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.file_download_outlined),
                    label: DualText.inline(
                      en: _isExporting ? 'Generating Excel...' : 'Export to Excel (.xlsx)',
                      hi: 'एक्सेल में सुरक्षित करें',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  if (_exportedFilePath != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Saved to:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                Text(
                                  _exportedFilePath!,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
