import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'package:shubh_traders/core/utils/password_hash.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Trigger seeding asynchronously on first access
  db.seedDefaultDataIfNeeded(hashPassword);
  ref.onDispose(() => db.close());
  return db;
});
