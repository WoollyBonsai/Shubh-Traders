import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String selectedRole = 'Employee';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const DualText(
            en: 'Create User / Staff',
            hi: 'नया कर्मचारी जोड़ें',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username / उपयोगकर्ता नाम',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name / पूरा नाम',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pinCtrl,
                    decoration: const InputDecoration(
                      labelText: 'PIN or Password / पिन या पासवर्ड',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role / भूमिका',
                      prefixIcon: Icon(Icons.security),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Employee', child: Text('Employee / Staff (कर्मचारी)')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin (व्यवस्थापक / मालिक)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel / रद्द करें'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final success = await ref.read(authProvider.notifier).createUser(
                      username: usernameCtrl.text,
                      pin: pinCtrl.text,
                      role: selectedRole,
                      fullName: nameCtrl.text,
                    );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'User created successfully' : 'Username already exists!'),
                      backgroundColor: success ? AppTheme.successColor : AppTheme.dangerColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, WidgetRef ref, User user) {
    final pinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: DualText(
          en: 'Change PIN for ${user.username}',
          hi: '${user.username} का पिन बदलें',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 350,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: pinCtrl,
              decoration: const InputDecoration(
                labelText: 'New PIN / नया पिन',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter new PIN' : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(authProvider.notifier).updatePassword(user.id, pinCtrl.text);
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN updated successfully'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'User & Staff Management',
          hi: 'उपयोगकर्ता एवं कर्मचारी प्रबंधन',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(context, ref),
              icon: const Icon(Icons.person_add),
              label: const DualText.inline(en: 'Add User', hi: 'नया उपयोगकर्ता'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: users.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final isAdmin = user.role.toLowerCase() == 'admin';

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isAdmin
                        ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin ? AppTheme.secondaryColor : AppTheme.primaryColor,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.amber.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAdmin ? Colors.amber.shade900 : Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text('Username: ${user.username} • ID: #${user.id}'),
                  trailing: OutlinedButton.icon(
                    onPressed: () => _showChangePinDialog(context, ref, user),
                    icon: const Icon(Icons.key, size: 16),
                    label: const Text('Change PIN'),
                  ),
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
