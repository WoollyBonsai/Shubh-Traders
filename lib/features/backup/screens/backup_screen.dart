import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shubh_traders/core/database/backup_service.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/utils/currency_format.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  List<BackupFileInfo> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final list = await ref.read(backupServiceProvider).listBackups();
      if (mounted) setState(() => _backups = list);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isLoading = true);
    try {
      final path = await ref.read(backupServiceProvider).createManualBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created successfully: $path'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImportBackup() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Select SQLite Database Backup to Restore',
      type: FileType.custom,
      allowedExtensions: ['sqlite', 'db'],
    );

    if (result.isEmpty || result.first.path == null) return;
    final selectedPath = result.first.path!;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const DualText(
          en: 'Confirm Database Restore',
          hi: 'डेटाबेस रीस्टोर की पुष्टि करें',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SAFETY ASSURANCE: Before restoring, an emergency backup of your current active data will be created automatically so no records can ever be lost.',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text('Are you sure you want to restore from:\n$selectedPath?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isLoading = true);
              try {
                final auth = ref.read(authProvider);
                await ref.read(backupServiceProvider).restoreBackup(
                      backupFilePath: selectedPath,
                      userId: auth.currentUser?.id ?? 1,
                      username: auth.currentUser?.username ?? 'Admin',
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database restored successfully! Please restart the app if needed.'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                  _loadBackups();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore error: $e'), backgroundColor: AppTheme.dangerRed),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            child: const Text('Yes, Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'Database Backup & Restore Management',
          hi: 'डेटाबेस बैकअप एवं रीस्टोर प्रबंधन',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleImportBackup,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import / Restore Backup'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleCreateBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text('Create Backup Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.primaryNavy, size: 30),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Automated Daily Backups & Integrity Protection',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryNavy),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Shubh Traders automatically creates a fresh backup snapshot on the first launch of every new day. Manual backups can also be created at any moment with 1-click.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Backups List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Available Backups on This Machine:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBackups,
                  tooltip: 'Refresh list',
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _backups.isEmpty
                      ? const Center(child: Text('No backups found. Click "Create Backup Now" to make one.'))
                      : Card(
                          child: ListView.separated(
                            itemCount: _backups.length,
                            separatorBuilder: (context, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final b = _backups[index];
                              final isAuto = b.fileName.startsWith('auto_');

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isAuto ? Colors.green.shade50 : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isAuto ? Colors.green.shade200 : Colors.blue.shade200),
                                  ),
                                  child: Icon(
                                    isAuto ? Icons.auto_mode : Icons.backup,
                                    color: isAuto ? AppTheme.successGreen : AppTheme.primaryColor,
                                  ),
                                ),
                                title: Text(b.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('Created: ${Formatters.dateTime(b.modified)} • Size: ${b.sizeFormatted}'),
                                trailing: ElevatedButton.icon(
                                  onPressed: () {
                                    // Trigger restore confirmation
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Restore this Backup?'),
                                        content: Text('Are you sure you want to restore:\n${b.fileName}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              final auth = ref.read(authProvider);
                                              await ref.read(backupServiceProvider).restoreBackup(
                                                    backupFilePath: b.path,
                                                    userId: auth.currentUser?.id ?? 1,
                                                    username: auth.currentUser?.username ?? 'Admin',
                                                  );
                                              _loadBackups();
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                                            child: const Text('Restore'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.restore, size: 16),
                                  label: const Text('Restore', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryNavy,
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
