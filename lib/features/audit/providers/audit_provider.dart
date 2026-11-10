import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/database/database_provider.dart';

final auditLogsStreamProvider = StreamProvider<List<AuditLog>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.auditLogs)..orderBy([(a) => OrderingTerm.desc(a.timestamp)])).watch();
});
