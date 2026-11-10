import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'database_provider.dart';
import '../../features/settings/providers/settings_provider.dart';

class BackupFileInfo {
  final String path;
  final String fileName;
  final DateTime modified;
  final int sizeBytes;

  BackupFileInfo({
    required this.path,
    required this.fileName,
    required this.modified,
    required this.sizeBytes,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupService {
  final SharedPreferences _prefs;
  final AppDatabase _db;

  BackupService(this._prefs, this._db);

  Future<File> getActiveDatabaseFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, 'shubh_traders_v1.sqlite'));
  }

  Future<Directory> getBackupsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, 'ShubhTraders_Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // Auto-backup on new day's first boot
  Future<String?> autoBackupIfNewDay() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastAutoBackup = _prefs.getString('last_auto_backup_date');

    if (lastAutoBackup == todayStr) {
      return null; // Already backed up today
    }

    final dbFile = await getActiveDatabaseFile();
    if (!await dbFile.exists()) return null;

    final backupDir = await getBackupsDirectory();
    final backupFileName = 'auto_backup_$todayStr.sqlite';
    final targetFile = File(p.join(backupDir.path, backupFileName));

    await dbFile.copy(targetFile.path);
    await _prefs.setString('last_auto_backup_date', todayStr);

    return targetFile.path;
  }

  // Create manual backup
  Future<String> createManualBackup({String? customDestinationDir}) async {
    final dbFile = await getActiveDatabaseFile();
    if (!await dbFile.exists()) {
      throw Exception('Active database file not found');
    }

    final timestampStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFileName = 'manual_backup_$timestampStr.sqlite';

    Directory targetDir;
    if (customDestinationDir != null && customDestinationDir.isNotEmpty) {
      targetDir = Directory(customDestinationDir);
      if (!await targetDir.exists()) await targetDir.create(recursive: true);
    } else {
      targetDir = await getBackupsDirectory();
    }

    final targetPath = p.join(targetDir.path, backupFileName);
    await dbFile.copy(targetPath);
    return targetPath;
  }

  // List existing backups
  Future<List<BackupFileInfo>> listBackups() async {
    final backupDir = await getBackupsDirectory();
    if (!await backupDir.exists()) return [];

    final files = backupDir.listSync().whereType<File>().where((f) => f.path.endsWith('.sqlite')).toList();

    final result = <BackupFileInfo>[];
    for (final f in files) {
      final stat = await f.stat();
      result.add(
        BackupFileInfo(
          path: f.path,
          fileName: p.basename(f.path),
          modified: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }

    result.sort((a, b) => b.modified.compareTo(a.modified));
    return result;
  }

  // Safely restore a backup file
  Future<void> restoreBackup({
    required String backupFilePath,
    required int userId,
    required String username,
  }) async {
    final sourceBackup = File(backupFilePath);
    if (!await sourceBackup.exists()) {
      throw Exception('Selected backup file does not exist');
    }

    final dbFile = await getActiveDatabaseFile();
    final backupDir = await getBackupsDirectory();

    // 1. Mandatory emergency safety backup of current state FIRST
    final emergencyTime = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final emergencyFile = File(p.join(backupDir.path, 'emergency_safety_backup_$emergencyTime.sqlite'));
    if (await dbFile.exists()) {
      await dbFile.copy(emergencyFile.path);
    }

    // 2. Overwrite current DB with selected backup
    await sourceBackup.copy(dbFile.path);

    // 3. Log Audit
    await _db.logAudit(
      userId: userId,
      username: username,
      actionType: 'BACKUP_RESTORED',
      entityId: p.basename(backupFilePath),
      details: 'Restored database from "$backupFilePath". Pre-restore safety backup preserved at "${emergencyFile.path}".',
    );
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final db = ref.watch(databaseProvider);
  final service = BackupService(prefs, db);
  // Trigger auto-backup asynchronously
  service.autoBackupIfNewDay();
  return service;
});
