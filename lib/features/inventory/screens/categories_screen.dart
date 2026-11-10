import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';
import 'package:shubh_traders/features/inventory/providers/inventory_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _showAddOrEditCategoryDialog(BuildContext context, WidgetRef ref, [Category? existing]) {
    final enCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final hiCtrl = TextEditingController(text: existing?.nameHi ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: DualText(
          en: existing == null ? 'Add Category' : 'Edit Category',
          hi: existing == null ? 'नई श्रेणी जोड़ें' : 'श्रेणी संपादित करें',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: enCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name (English)',
                    hintText: 'e.g. Cement, TMT Steel, Sand',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: hiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name (Hindi / हिन्दी)',
                    hintText: 'उदा. सीमेंट, सरिया, रेत',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
              final inv = ref.read(inventoryNotifierProvider);
              final auth = ref.read(authProvider);
              final user = auth.currentUser;
              if (existing == null) {
                await inv.addCategory(
                  enCtrl.text,
                  hiCtrl.text,
                  userId: user?.id ?? 1,
                  username: user?.username ?? 'Staff',
                );
              } else {
                await inv.updateCategory(existing.id, enCtrl.text, hiCtrl.text);
              }
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: Text(existing == null ? 'Add Category' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const DualText(
          en: 'Delete Category',
          hi: 'श्रेणी हटाएं',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
        ),
        content: Text('Are you sure you want to delete "${category.nameEn} / ${category.nameHi}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(inventoryNotifierProvider).deleteCategory(category.id);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DualText(
          en: 'Product Categories',
          hi: 'उत्पाद श्रेणियां',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddOrEditCategoryDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const DualText.inline(en: 'New Category', hi: 'नई श्रेणी'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet. Click "New Category" to add.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 340,
              mainAxisExtent: 130,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.category, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DualText(
                              en: cat.nameEn,
                              hi: cat.nameHi,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('ID: #${cat.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                        tooltip: 'Edit',
                        onPressed: () => _showAddOrEditCategoryDialog(context, ref, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerColor),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, ref, cat),
                      ),
                    ],
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
