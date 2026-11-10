import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/inventory/providers/inventory_provider.dart';
import 'package:shubh_traders/features/ledger/providers/ledger_provider.dart';
import 'package:shubh_traders/features/pos/providers/pos_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _chartDays = 7;

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesStreamProvider);
    final customersAsync = ref.watch(allCustomersStreamProvider);
    final itemsAsync = ref.watch(itemsWithCategoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'Business Dashboard & Overview',
          hi: 'व्यापार डैशबोर्ड एवं समीक्षा',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryNavy),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => widget.onNavigateTab?.call(1), // Go to POS
              icon: const Icon(Icons.point_of_sale),
              label: const DualText.inline(en: 'Open Billing Counter', hi: 'बिल बनाएं'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
      body: salesAsync.when(
        data: (sales) {
          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);

          final todaySales = sales.where((s) => s.sale.timestamp.isAfter(startOfToday)).toList();
          final todayGrossRevenue = todaySales.fold(0.0, (sum, s) => sum + s.sale.totalAmount);
          final todayCashRevenue = todaySales.where((s) => s.sale.paymentMethod == 'Cash').fold(0.0, (sum, s) => sum + s.sale.totalAmount);
          final todayOnlineRevenue = todaySales.where((s) => s.sale.paymentMethod == 'Online').fold(0.0, (sum, s) => sum + s.sale.totalAmount);
          final todayUdhaarRevenue = todaySales.where((s) => s.sale.paymentMethod == 'Udhaar').fold(0.0, (sum, s) => sum + s.sale.totalAmount);

          final customers = customersAsync.value ?? [];
          final totalPendingUdhaar = customers.fold(0.0, (sum, c) => sum + c.totalDue);

          final items = itemsAsync.value ?? [];
          final lowStockList = items.where((i) => i.isLowStock).toList();

          final List<double> dailyTotals = List.filled(_chartDays, 0.0);
          final List<DateTime> chartDates = [];

          for (int i = _chartDays - 1; i >= 0; i--) {
            final targetDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
            chartDates.add(targetDate);
            final daySales = sales.where((s) {
              final sDate = s.sale.timestamp;
              return sDate.year == targetDate.year && sDate.month == targetDate.month && sDate.day == targetDate.day;
            });
            dailyTotals[_chartDays - 1 - i] = daySales.fold(0.0, (sum, s) => sum + s.sale.totalAmount);
          }

          final maxDaily = dailyTotals.fold(0.0, (m, v) => v > m ? v : m);
          final maxY = maxDaily > 0 ? (maxDaily * 1.25) : 10000.0;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1000;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP METRICS: Responsive Flex Grid (2x2 on narrow, 4x1 on wide)
                    if (isNarrow) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              titleEn: "Today's Gross Sales",
                              titleHi: 'आज की कुल बिक्री',
                              value: Formatters.currency(todayGrossRevenue),
                              subtitle: '${todaySales.length} orders today',
                              icon: Icons.trending_up,
                              accentColor: AppTheme.primaryNavy,
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _MetricCard(
                              titleEn: 'Total Pending Udhaar',
                              titleHi: 'कुल बकाया उधार',
                              value: Formatters.currency(totalPendingUdhaar),
                              subtitle: 'Across all customers',
                              icon: Icons.account_balance_wallet,
                              accentColor: AppTheme.dangerRed,
                              bgColor: const Color(0xFFFEF2F2),
                              onTap: () => widget.onNavigateTab?.call(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              titleEn: 'Low Stock Alerts',
                              titleHi: 'कम स्टॉक वाले उत्पाद',
                              value: '${lowStockList.length} Items',
                              subtitle: 'Requires restock',
                              icon: Icons.warning_amber_rounded,
                              accentColor: AppTheme.warningAmber,
                              bgColor: const Color(0xFFFFFBEB),
                              onTap: () => widget.onNavigateTab?.call(2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _MetricCard(
                              titleEn: 'Inventory Catalog',
                              titleHi: 'कुल उत्पाद सामग्री',
                              value: '${items.length} Products',
                              subtitle: 'Active inventory',
                              icon: Icons.inventory_2_outlined,
                              accentColor: AppTheme.successGreen,
                              bgColor: const Color(0xFFF0FDF4),
                              onTap: () => widget.onNavigateTab?.call(2),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              titleEn: "Today's Gross Sales",
                              titleHi: 'आज की कुल बिक्री',
                              value: Formatters.currency(todayGrossRevenue),
                              subtitle: '${todaySales.length} orders today',
                              icon: Icons.trending_up,
                              accentColor: AppTheme.primaryNavy,
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _MetricCard(
                              titleEn: 'Total Pending Udhaar',
                              titleHi: 'कुल बकाया उधार',
                              value: Formatters.currency(totalPendingUdhaar),
                              subtitle: 'Across all customers',
                              icon: Icons.account_balance_wallet,
                              accentColor: AppTheme.dangerRed,
                              bgColor: const Color(0xFFFEF2F2),
                              onTap: () => widget.onNavigateTab?.call(3),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _MetricCard(
                              titleEn: 'Low Stock Alerts',
                              titleHi: 'कम स्टॉक वाले उत्पाद',
                              value: '${lowStockList.length} Items',
                              subtitle: 'Requires restock',
                              icon: Icons.warning_amber_rounded,
                              accentColor: AppTheme.warningAmber,
                              bgColor: const Color(0xFFFFFBEB),
                              onTap: () => widget.onNavigateTab?.call(2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _MetricCard(
                              titleEn: 'Inventory Catalog',
                              titleHi: 'कुल उत्पाद सामग्री',
                              value: '${items.length} Products',
                              subtitle: 'Active inventory',
                              icon: Icons.inventory_2_outlined,
                              accentColor: AppTheme.successGreen,
                              bgColor: const Color(0xFFF0FDF4),
                              onTap: () => widget.onNavigateTab?.call(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // CHART & BREAKDOWN: Responsive Row vs Column
                    Flex(
                      direction: isNarrow ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Revenue Chart
                        Expanded(
                          flex: isNarrow ? 0 : 3,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const DualText(
                                            en: 'Daily Revenue Analytics',
                                            hi: 'दैनिक बिक्री ग्राफ',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Text('Aggregated sales over past $_chartDays days', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                      SegmentedButton<int>(
                                        segments: const [
                                          ButtonSegment(value: 7, label: Text('7 Days')),
                                          ButtonSegment(value: 14, label: Text('14 Days')),
                                        ],
                                        selected: {_chartDays},
                                        onSelectionChanged: (val) {
                                          setState(() => _chartDays = val.first);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 250,
                                    child: BarChart(
                                      BarChartData(
                                        maxY: maxY,
                                        barTouchData: BarTouchData(
                                          touchTooltipData: BarTouchTooltipData(
                                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                              final dt = chartDates[groupIndex];
                                              return BarTooltipItem(
                                                '${Formatters.date(dt)}\n',
                                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                                children: [
                                                  TextSpan(
                                                    text: Formatters.currency(rod.toY),
                                                    style: const TextStyle(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 60,
                                              getTitlesWidget: (val, meta) {
                                                return Text(
                                                  Formatters.currency(val, compact: true),
                                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                );
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (val, meta) {
                                                final idx = val.toInt();
                                                if (idx < 0 || idx >= chartDates.length) return const SizedBox();
                                                final d = chartDates[idx];
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 6.0),
                                                  child: Text(
                                                    '${d.day}/${d.month}',
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        barGroups: List.generate(_chartDays, (index) {
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: dailyTotals[index],
                                                color: AppTheme.primaryNavy,
                                                width: _chartDays == 7 ? 24 : 12,
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  topRight: Radius.circular(4),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isNarrow) const SizedBox(width: 14) else const SizedBox(height: 14),

                        // Payment Modes Breakdown
                        Expanded(
                          flex: isNarrow ? 0 : 2,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const DualText(
                                    en: "Today's Collection by Mode",
                                    hi: 'आज का भुगतान विभाजन',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Real-time payment split', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 20),

                                  _PaymentBreakdownRow(
                                    title: 'Cash (नकद)',
                                    amount: todayCashRevenue,
                                    total: todayGrossRevenue,
                                    color: AppTheme.successGreen,
                                    icon: Icons.attach_money,
                                  ),
                                  const SizedBox(height: 14),

                                  _PaymentBreakdownRow(
                                    title: 'Online / UPI (ऑनलाइन)',
                                    amount: todayOnlineRevenue,
                                    total: todayGrossRevenue,
                                    color: AppTheme.infoColor,
                                    icon: Icons.qr_code,
                                  ),
                                  const SizedBox(height: 14),

                                  _PaymentBreakdownRow(
                                    title: 'Udhaar Credit (उधार)',
                                    amount: todayUdhaarRevenue,
                                    total: todayGrossRevenue,
                                    color: AppTheme.dangerRed,
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Today / आज कुल:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                        Formatters.currency(todayGrossRevenue),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryNavy),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Critical Low Stock Alerts
                    if (lowStockList.isNotEmpty) ...[
                      Card(
                        color: const Color(0xFFFFFBEB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.amber.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warningAmber, size: 24),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: DualText(
                                      en: 'Critical Stock Alerts — Items Below Minimum Level',
                                      hi: 'गंभीर स्टॉक चेतावनी — न्यूनतम स्तर से कम उत्पाद',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => widget.onNavigateTab?.call(2),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber, foregroundColor: Colors.white),
                                    child: const Text('Manage Stock'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: lowStockList.take(6).map((itemWithCat) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(itemWithCat.item.nameEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Stock: ${Formatters.qty(itemWithCat.item.stockQty, itemWithCat.item.unit)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Recent Sales Table
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const DualText(
                                  en: 'Recent Sales Transactions',
                                  hi: 'हालिया बिक्री लेनदेन',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                TextButton.icon(
                                  onPressed: () => widget.onNavigateTab?.call(4),
                                  icon: const Icon(Icons.arrow_forward, size: 16),
                                  label: const Text('View All Transactions'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            sales.isEmpty
                                ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No transactions yet')))
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: constraints.maxWidth - 40),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                        columns: const [
                                          DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                        rows: sales.take(5).map((s) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text('INV-${s.sale.id.toString().padLeft(5, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                              DataCell(Text(Formatters.dateTime(s.sale.timestamp), style: const TextStyle(fontSize: 12))),
                                              DataCell(Text(s.customer?.name ?? 'Counter Sale', style: const TextStyle(fontSize: 12))),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: s.sale.paymentMethod == 'Udhaar'
                                                        ? Colors.red.shade100
                                                        : (s.sale.paymentMethod == 'Cash' ? Colors.green.shade100 : Colors.blue.shade100),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    s.sale.paymentMethod,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                      color: s.sale.paymentMethod == 'Udhaar'
                                                          ? AppTheme.dangerRed
                                                          : (s.sale.paymentMethod == 'Cash' ? AppTheme.successGreen : AppTheme.infoColor),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  Formatters.currency(s.sale.totalAmount),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String titleEn;
  final String titleHi;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.titleEn,
    required this.titleHi,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 14),
              DualText(
                en: titleEn,
                hi: titleHi,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentBreakdownRow extends StatelessWidget {
  final String title;
  final double amount;
  final double total;
  final Color color;
  final IconData icon;

  const _PaymentBreakdownRow({
    required this.title,
    required this.amount,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            Text(Formatters.currency(amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}
