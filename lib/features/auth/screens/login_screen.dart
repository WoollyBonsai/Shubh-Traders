import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isOwnerMode = false;
  String? _selectedEmployeeUsername;
  final _adminUsernameCtrl = TextEditingController(text: 'Kanha');
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;

  @override
  void dispose() {
    _adminUsernameCtrl.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _isOwnerMode ? _adminUsernameCtrl.text.trim() : (_selectedEmployeeUsername ?? '');
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an account')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          username,
          _pinController.text,
        );

    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _showEmployeeRegisterDialog() {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final regFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const DualText(
          en: 'Employee Registration',
          hi: 'नया कर्मचारी पंजीकरण',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: regFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Default permissions: Store Employee (can use POS, Inventory, Udhaar Book, and Sales)',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username / यूजरनेम'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name / पूरा नाम'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pinCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password or PIN / पासवर्ड या पिन'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!regFormKey.currentState!.validate()) return;
              final success = await ref.read(authProvider.notifier).createUser(
                    username: usernameCtrl.text.trim(),
                    pin: pinCtrl.text.trim(),
                    role: 'Employee',
                    fullName: nameCtrl.text.trim(),
                  );
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Registration successful! You can now log in.' : 'Username already exists!'),
                    backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 480,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 36,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DualText(
                              en: 'Shubh Traders',
                              hi: 'शुभ ट्रेडर्स',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Text(
                              'Building Materials & Hardware POS',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Mode Switcher (Employee Dropdown vs Owner Admin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DualText(
                          en: _isOwnerMode ? 'Owner / Admin Login' : 'Staff / Employee Login',
                          hi: _isOwnerMode ? 'मालिक / एडमिन लॉगिन' : 'स्टाफ / कर्मचारी लॉगिन',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isOwnerMode = !_isOwnerMode;
                            _pinController.clear();
                          });
                        },
                        icon: Icon(_isOwnerMode ? Icons.badge : Icons.admin_panel_settings, size: 16),
                        label: Text(_isOwnerMode ? 'Staff Login' : 'Owner Login', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // IF EMPLOYEE MODE: Dropdown with registered users (EXCLUDING hidden "Kanha")
                  if (!_isOwnerMode) ...[
                    const DualText(
                      en: 'Select Account',
                      hi: 'खाता चुनें',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    usersAsync.when(
                      data: (users) {
                        // Filter out hidden Super Admin "Kanha"
                        final visibleUsers = users.where((u) => u.username != 'Kanha').toList();

                        if (visibleUsers.isEmpty) {
                          return const Text('No employee accounts found. Please register below.');
                        }

                        // Auto-select first if none selected
                        _selectedEmployeeUsername ??= visibleUsers.first.username;

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedEmployeeUsername,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: visibleUsers.map((u) {
                            return DropdownMenuItem<String>(
                              value: u.username,
                              child: Row(
                                children: [
                                  Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Text('(@${u.username})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedEmployeeUsername = val);
                          },
                        );
                      },
                      loading: () => const Center(child: LinearProgressIndicator()),
                      error: (err, _) => Text('Error loading users: $err'),
                    ),
                  ] else ...[
                    // OWNER MODE: Direct Username field for "Kanha"
                    const DualText(
                      en: 'Owner Username',
                      hi: 'मालिक यूजरनेम',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _adminUsernameCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.security),
                        hintText: 'Enter Admin username',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // PIN / Password Field
                  const DualText(
                    en: 'Password / PIN',
                    hi: 'पासवर्ड / पिन',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: 'Enter password or PIN',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter password' : null,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isOwnerMode ? AppTheme.warningAmber : AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isOwnerMode ? Icons.admin_panel_settings : Icons.login_rounded, size: 20),
                              const SizedBox(width: 8),
                              DualText.inline(
                                en: _isOwnerMode ? 'Access Admin Console' : 'Sign In as Employee',
                                hi: _isOwnerMode ? 'एडमिन प्रवेश' : 'कर्मचारी लॉगिन',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Register New Employee Option
                  if (!_isOwnerMode) ...[
                    Center(
                      child: TextButton.icon(
                        onPressed: _showEmployeeRegisterDialog,
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('Register New Employee / नया कर्मचारी जोड़ें'),
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
