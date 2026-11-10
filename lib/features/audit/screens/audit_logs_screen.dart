import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/audit/providers/audit_provider.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _selectedActionType = 'ALL';
  String _searchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'SALE_CASH':
        return AppTheme.successGreen;
      case 'SALE_ONLINE':
        return AppTheme.infoColor;
      case 'SALE_UDHAAR':
        return AppTheme.dangerRed;
      case 'UDHAAR_PAYMENT':
        return const Color(0xFF0D9488); // Teal
      case 'ITEM_CREATED':
      case 'ITEM_RESTOCKED':
        return AppTheme.warningAmber;
      case 'ITEM_DELETED':
        return AppTheme.dangerRed;
      case 'BACKUP_CREATED':
      case 'BACKUP_RESTORED':
        return const Color(0xFF7C3AED); // Purple
      default:
        return AppTheme.primaryNavy;
    }
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'SALE_CASH':
        return Icons.attach_money;
      case 'SALE_ONLINE':
        return Icons.qr_code;
      case 'SALE_UDHAAR':
        return Icons.account_balance_wallet_outlined;
      case 'UDHAAR_PAYMENT':
        return Icons.payments_rounded;
      case 'ITEM_CREATED':
        return Icons.add_box_outlined;
      case 'ITEM_RESTOCKED':
        return Icons.add_shopping_cart;
      case 'ITEM_DELETED':
        return Icons.delete_outline;
      case 'BACKUP_CREATED':
      case 'BACKUP_RESTORED':
        return Icons.backup_outlined;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auditLogsAsync = ref.watch(auditLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'Audit Trail & User Footprint',
          hi: 'ऑडिट लॉग्स एवं उपयोगकर्ता गतिविधि',
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
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search audit records by user, details, entity ID...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedActionType,
                        decoration: const InputDecoration(labelText: 'Action Type / कार्य का प्रकार'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Actions (सभी कार्य)')),
                          DropdownMenuItem(value: 'SALE_CASH', child: Text('Cash Sales (नकद बिक्री)')),
                          DropdownMenuItem(value: 'SALE_ONLINE', child: Text('Online UPI Sales (ऑनलाइन बिक्री)')),
                          DropdownMenuItem(value: 'SALE_UDHAAR', child: Text('Udhaar Sales (उधार बिक्री)')),
                          DropdownMenuItem(value: 'UDHAAR_PAYMENT', child: Text('Udhaar Payment Received (उधार जमा)')),
                          DropdownMenuItem(value: 'ITEM_RESTOCKED', child: Text('Stock Restocked (स्टॉक जुड़ा)')),
                          DropdownMenuItem(value: 'ITEM_CREATED', child: Text('Item Created (नया उत्पाद)')),
                          DropdownMenuItem(value: 'BACKUP_RESTORED', child: Text('Database Restores (डेटाबेस रिस्टोर)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedActionType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
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
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _filterStartDate != null && _filterEndDate != null
                            ? '${Formatters.date(_filterStartDate!)} - ${Formatters.date(_filterEndDate!)}'
                            : 'Date Range',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    if (_filterStartDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
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

            // Logs List
            Expanded(
              child: auditLogsAsync.when(
                data: (logs) {
                  final filtered = logs.where((l) {
                    final matchType = _selectedActionType == 'ALL' || l.actionType == _selectedActionType;
                    final matchSearch = _searchQuery.isEmpty ||
                        l.username.toLowerCase().contains(_searchQuery) ||
                        l.details.toLowerCase().contains(_searchQuery) ||
                        (l.entityId?.toLowerCase().contains(_searchQuery) ?? false);

                    bool matchDate = true;
                    if (_filterStartDate != null && _filterEndDate != null) {
                      final start = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
                      final end = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day, 23, 59, 59);
                      matchDate = l.timestamp.isAfter(start) && l.timestamp.isBefore(end);
                    }

                    return matchType && matchSearch && matchDate;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No audit log entries found matching criteria.'));
                  }

                  return Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (context, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = filtered[index];
                        final actionColor = _getActionColor(log.actionType);
                        final actionIcon = _getActionIcon(log.actionType);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: actionColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                            ),
                            child: Icon(actionIcon, color: actionColor, size: 22),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: actionColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log.actionType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                log.username,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (log.entityId != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    log.entityId!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              log.details,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.date(log.timestamp),
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                Formatters.time(log.timestamp),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        );
                      },
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
