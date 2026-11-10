import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'App Settings & Accessibility',
          hi: 'ऐप सेटिंग्स एवं सुगमता',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accessibility & Font Scaling Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.accessibility_new, color: AppTheme.primaryColor),
                            SizedBox(width: 10),
                            DualText(
                              en: 'Accessibility & Font Scaling',
                              hi: 'सुगमता एवं फॉन्ट का आकार',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Adjust text size multiplier dynamically across the entire application.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        // Font Slider
                        Row(
                          children: [
                            const Text('Small (0.8x)', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: settings.fontSizeMultiplier,
                                min: 0.8,
                                max: 1.4,
                                divisions: 6,
                                label: '${(settings.fontSizeMultiplier * 100).toInt()}%',
                                onChanged: (val) {
                                  ref.read(settingsProvider.notifier).setFontSizeMultiplier(val);
                                },
                              ),
                            ),
                            const Text('Large (1.4x)', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${(settings.fontSizeMultiplier * 100).toInt()}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Live Preview Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Font Scaling Live Preview / फॉन्ट का पूर्वावलोकन:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              DualText(
                                en: 'UltraTech Cement (50kg) - Rate: Rs. 380.00 / Bag',
                                hi: 'अल्ट्राटेक सीमेंट (50 किग्रा) - दर: रु. 380.00 / बोरी',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Language & Display Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.translate, color: AppTheme.primaryColor),
                            SizedBox(width: 10),
                            DualText(
                              en: 'Language & Theme Mode',
                              hi: 'भाषा एवं थीम',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const DualText.inline(
                            en: 'Dual Language Layout Style',
                            hi: 'द्विभाषी प्रदर्शन शैली',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: const Text('Choose whether Hindi appears stacked below or inline with slash', style: TextStyle(fontSize: 12)),
                          trailing: DropdownButton<DualTextDisplayMode>(
                            value: settings.dualTextMode,
                            items: const [
                              DropdownMenuItem(
                                value: DualTextDisplayMode.stacked,
                                child: Text('Stacked (ऊपर-नीचे)'),
                              ),
                              DropdownMenuItem(
                                value: DualTextDisplayMode.inline,
                                child: Text('Inline Slash (साथ में En / Hi)'),
                              ),
                            ],
                            onChanged: (mode) {
                              if (mode != null) {
                                ref.read(settingsProvider.notifier).setDualTextMode(mode);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Shop / Invoice Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.store, color: AppTheme.primaryColor),
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
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save Shop Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
