import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/database/database_provider.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';
import 'package:shubh_traders/features/pos/providers/pos_provider.dart';
import 'package:shubh_traders/features/ledger/providers/ledger_provider.dart';

class UdhaarBookScreen extends ConsumerStatefulWidget {
  const UdhaarBookScreen({super.key});

  @override
  ConsumerState<UdhaarBookScreen> createState() => _UdhaarBookScreenState();
}

class _UdhaarBookScreenState extends ConsumerState<UdhaarBookScreen> {
  String _searchQuery = '';
  bool _onlyWithDue = true;

  void _showReceivePaymentDialog(BuildContext context, Customer customer) {
    final amountCtrl = TextEditingController(text: customer.totalDue > 0 ? customer.totalDue.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController();
    String paymentMethod = 'Cash';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: DualText(
            en: 'Receive Payment: ${customer.name}',
            hi: 'भुगतान प्राप्त करें: ${customer.name}',
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Total Due / कुल बकाया:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.dangerColor)),
                        Text(
                          Formatters.currency(customer.totalDue),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.dangerColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount Received (₹) / प्राप्त राशि',
                      prefixText: '₹ ',
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Mode / माध्यम'),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash (नकद)')),
                      DropdownMenuItem(value: 'Online', child: Text('Online / UPI')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => paymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Remarks (optional)',
                      hintText: 'e.g. Cleared full bill, partial payment',
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
                final amount = double.parse(amountCtrl.text);
                final auth = ref.read(authProvider);
                final user = auth.currentUser;

                await ref.read(ledgerNotifierProvider).receivePayment(
                      customerId: customer.id,
                      amountPaid: amount,
                      paymentMethod: paymentMethod,
                      userId: user?.id ?? 1,
                      username: user?.username ?? 'Staff',
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    );

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment of ₹$amount received from ${customer.name}'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerStatementDialog(BuildContext context, Customer customer) async {
    final db = ref.read(databaseProvider);

    // Fetch customer sales & payments
    final customerSales = await (db.select(db.sales)
          ..where((s) => s.customerId.equals(customer.id))
          ..orderBy([(s) => drift.OrderingTerm.desc(s.timestamp)]))
        .get();

    final customerPayments = await (db.select(db.payments)
          ..where((p) => p.customerId.equals(customer.id))
          ..orderBy([(p) => drift.OrderingTerm.desc(p.timestamp)]))
        .get();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: DualText(
          en: 'Ledger Statement: ${customer.name}',
          hi: 'खाता विवरण: ${customer.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 600,
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Phone: ${customer.phone}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    'Outstanding Due: ${Formatters.currency(customer.totalDue)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: customer.totalDue > 0 ? AppTheme.dangerColor : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              const Text('Recent Udhaar Sales / हालिया उधार बिल:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Expanded(
                flex: 1,
                child: customerSales.isEmpty
                    ? const Center(child: Text('No sales found for this customer', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: customerSales.length,
                        itemBuilder: (_, index) {
                          final s = customerSales[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('Invoice #INV-${s.id.toString().padLeft(5, '0')} (${s.paymentMethod})'),
                            subtitle: Text(Formatters.dateTime(s.timestamp)),
                            trailing: Text(
                              Formatters.currency(s.totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: s.paymentMethod == 'Udhaar' ? AppTheme.dangerColor : Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 20),
              const Text('Payment History / जमा किया गया भुगतान:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Expanded(
                flex: 1,
                child: customerPayments.isEmpty
                    ? const Center(child: Text('No payment entries recorded yet', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: customerPayments.length,
                        itemBuilder: (_, index) {
                          final p = customerPayments[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 20),
                            title: Text('Payment via ${p.paymentMethod} ${p.notes != null ? '(${p.notes})' : ''}'),
                            subtitle: Text(Formatters.dateTime(p.timestamp)),
                            trailing: Text(
                              '+ ${Formatters.currency(p.amountPaid)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dueCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const DualText(
          en: 'Add New Customer',
          hi: 'नया ग्राहक जोड़ें',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Customer Name / ग्राहक का नाम'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number / मोबाइल नंबर'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Opening Balance (₹) / पुराना बकाया (यदि कोई हो)'),
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
              final db = ref.read(databaseProvider);
              final due = double.tryParse(dueCtrl.text) ?? 0.0;
              await db.into(db.customers).insert(
                    CustomersCompanion.insert(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      totalDue: drift.Value(due),
                    ),
                  );
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'Udhaar Book & Customer Ledger',
          hi: 'उधार खाता एवं ग्राहक लेजर',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddCustomerDialog(context),
              icon: const Icon(Icons.person_add),
              label: const DualText.inline(en: 'Add Customer', hi: 'नया ग्राहक'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) {
          final totalPendingUdhaar = customers.fold(0.0, (sum, c) => sum + c.totalDue);
          final debtorCount = customers.where((c) => c.totalDue > 0).length;

          final filtered = customers.where((c) {
            final matchDue = !_onlyWithDue || c.totalDue > 0;
            final matchSearch = _searchQuery.isEmpty ||
                c.name.toLowerCase().contains(_searchQuery) ||
                c.phone.contains(_searchQuery);
            return matchDue && matchSearch;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Top Metrics Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                                child: const Icon(Icons.account_balance_wallet, color: AppTheme.dangerColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const DualText(
                                    en: 'Total Outstanding Udhaar',
                                    hi: 'कुल बकाया उधार',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.currency(totalPendingUdhaar),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                                child: const Icon(Icons.people_outline, color: AppTheme.primaryColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const DualText(
                                    en: 'Customers with Outstanding Balance',
                                    hi: 'उधार वाले ग्राहकों की संख्या',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$debtorCount Customers',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
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
                const SizedBox(height: 16),

                // Search & Filter Toolbar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search customer by name or phone...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilterChip(
                          selected: _onlyWithDue,
                          label: const DualText.inline(en: 'Pending Dues Only', hi: 'केवल बकाया वाले'),
                          avatar: const Icon(Icons.money_off, size: 16, color: AppTheme.dangerColor),
                          onSelected: (val) => setState(() => _onlyWithDue = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Table
                Expanded(
                  child: Card(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(label: Text('Customer Name / नाम', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Contact / फोन', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Outstanding Due / कुल बकाया', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: filtered.map((c) {
                              final hasDue = c.totalDue > 0;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: hasDue ? Colors.red.shade100 : Colors.green.shade100,
                                          child: Text(
                                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: hasDue ? AppTheme.dangerColor : AppTheme.successColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(c.phone.isNotEmpty ? c.phone : '-')),
                                  DataCell(
                                    Text(
                                      Formatters.currency(c.totalDue),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: hasDue ? AppTheme.dangerColor : AppTheme.successColor,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _showReceivePaymentDialog(context, c),
                                          icon: const Icon(Icons.payments_outlined, size: 14),
                                          label: const Text('Receive Payment', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.successColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _showCustomerStatementDialog(context, c),
                                          icon: const Icon(Icons.receipt_long, size: 14),
                                          label: const Text('View Ledger', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
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
    );
  }
}
