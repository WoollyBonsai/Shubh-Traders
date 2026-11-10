import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shubh_traders/core/localization/app_locale.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _nameCtrl = TextEditingController(text: s.shopName);
    _addressCtrl = TextEditingController(text: s.shopAddress);
    _phoneCtrl = TextEditingController(text: s.shopPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final appLocale = ref.watch(appLocaleProvider);
    final auth = ref.watch(authProvider);
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'App Settings & Preferences',
          hi: 'ऐप सेटिंग्स एवं व्यवस्था',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Language & Display Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.translate, color: AppTheme.primaryNavy),
                            SizedBox(width: 10),
                            DualText(
                              en: 'Universal Language Mode',
                              hi: 'सार्वभौमिक भाषा चयन',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose your preferred primary interface language. Headings and screens adjust accordingly.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        SegmentedButton<AppLanguage>(
                          segments: const [
                            ButtonSegment(
                              value: AppLanguage.hindi,
                              label: Text('हिन्दी (Hindi)'),
                              icon: Icon(Icons.language),
                            ),
                            ButtonSegment(
                              value: AppLanguage.english,
                              label: Text('English'),
                              icon: Icon(Icons.language),
                            ),
                            ButtonSegment(
                              value: AppLanguage.dual,
                              label: Text('Dual (दोनों En / Hi)'),
                              icon: Icon(Icons.compare_arrows),
                            ),
                          ],
                          selected: {appLocale},
                          onSelectionChanged: (val) {
                            ref.read(appLocaleProvider.notifier).setLanguage(val.first);
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const DualText.inline(
                            en: 'Dark Mode Theme',
                            hi: 'डार्क मोड थीम',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          trailing: Switch(
                            value: settings.themeMode == ThemeMode.dark,
                            onChanged: (val) {
                              ref.read(settingsProvider.notifier).setThemeMode(
                                    val ? ThemeMode.dark : ThemeMode.light,
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Accessibility & Font Scaling Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.text_fields, color: AppTheme.primaryNavy),
                            SizedBox(width: 10),
                            DualText(
                              en: 'Font Scaling & Window Layout',
                              hi: 'फॉन्ट का आकार एवं सुगमता',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scale all text cleanly without clipping or breaking the layout.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            const Text('Small (0.8x)', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: settings.fontSizeMultiplier,
                                min: 0.8,
                                max: 1.35,
                                divisions: 5,
                                label: '${(settings.fontSizeMultiplier * 100).toInt()}%',
                                onChanged: (val) {
                                  ref.read(settingsProvider.notifier).setFontSizeMultiplier(val);
                                },
                              ),
                            ),
                            const Text('Large (1.35x)', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${(settings.fontSizeMultiplier * 100).toInt()}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Payment UPI QR Code Setup (Admin Only)
                if (isAdmin) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.qr_code_2, color: AppTheme.primaryNavy),
                              SizedBox(width: 10),
                              DualText(
                                en: 'Shop Payment UPI QR Code',
                                hi: 'दुकान का भुगतान QR कोड (UPI)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload your shop UPI QR code image (PhonePe, Google Pay, Paytm, BHIM). It will be displayed at POS checkout and printed on bills.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (settings.paymentQrPath != null && File(settings.paymentQrPath!).existsSync()) ...[
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(settings.paymentQrPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await FilePicker.pickFiles(
                                          dialogTitle: 'Select Shop UPI QR Code Image',
                                          type: FileType.image,
                                        );
                                        if (result.isNotEmpty && result.first.path != null) {
                                          await ref.read(settingsProvider.notifier).setPaymentQrPath(result.first.path);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Payment QR Code uploaded successfully!'),
                                                backgroundColor: AppTheme.successGreen,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.upload),
                                      label: Text(settings.paymentQrPath != null ? 'Replace QR Code' : 'Upload QR Code Image'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryNavy,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    if (settings.paymentQrPath != null) ...[
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: () => ref.read(settingsProvider.notifier).setPaymentQrPath(null),
                                        icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.dangerRed),
                                        label: const Text('Remove QR Code', style: TextStyle(color: AppTheme.dangerRed)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Shop / Invoice Details Card (Admin Only)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.store, color: AppTheme.primaryNavy),
                              SizedBox(width: 10),
                              DualText(
                                en: 'Shop & Receipt Header Information',
                                hi: 'दुकान एवं बिल विवरण',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Shop Name (Printed on Bills)'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(labelText: 'Shop Address / Market Location'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(labelText: 'Shop Phone / Contact Number'),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await ref.read(settingsProvider.notifier).updateShopDetails(
                                    name: _nameCtrl.text.trim(),
                                    address: _addressCtrl.text.trim(),
                                    phone: _phoneCtrl.text.trim(),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Shop details saved successfully!'),
                                    backgroundColor: AppTheme.successGreen,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save Shop Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNavy,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
