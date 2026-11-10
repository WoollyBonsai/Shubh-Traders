import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';
import 'package:shubh_traders/features/auth/screens/users_screen.dart';
import 'package:shubh_traders/features/dashboard/screens/dashboard_screen.dart';
import 'package:shubh_traders/features/inventory/screens/categories_screen.dart';
import 'package:shubh_traders/features/inventory/screens/inventory_screen.dart';
import 'package:shubh_traders/features/ledger/screens/export_screen.dart';
import 'package:shubh_traders/features/ledger/screens/sales_history_screen.dart';
import 'package:shubh_traders/features/ledger/screens/udhaar_book_screen.dart';
import 'package:shubh_traders/features/pos/screens/pos_screen.dart';
import 'package:shubh_traders/features/settings/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onNavigate(int index) {
    setState(() => _selectedIndex = index);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const DualText(
          en: 'Sign Out',
          hi: 'लॉगआउट करें',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out of Shubh Traders?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final isAdmin = authState.isAdmin;

    final List<Widget> pages = [
      DashboardScreen(onNavigateTab: _onNavigate),
      const PosScreen(),
      const InventoryScreen(),
      const UdhaarBookScreen(),
      const SalesHistoryScreen(),
      const CategoriesScreen(),
      const ExportScreen(),
      const UsersScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Desktop Navigation Sidebar
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(right: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Column(
              children: [
                // App Logo & Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppTheme.secondaryColor, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SHUBH TRADERS',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                            ),
                            Text(
                              'शुभ ट्रेडर्स POS',
                              style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1E293B), height: 1),

                // Nav Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    children: [
                      _SidebarItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        labelEn: 'Dashboard',
                        labelHi: 'डैशबोर्ड',
                        isSelected: _selectedIndex == 0,
                        onTap: () => _onNavigate(0),
                      ),
                      _SidebarItem(
                        icon: Icons.point_of_sale_outlined,
                        activeIcon: Icons.point_of_sale,
                        labelEn: 'Point of Sale (POS)',
                        labelHi: 'बिलिंग काउंटर',
                        isSelected: _selectedIndex == 1,
                        onTap: () => _onNavigate(1),
                      ),
                      _SidebarItem(
                        icon: Icons.inventory_2_outlined,
                        activeIcon: Icons.inventory_2,
                        labelEn: 'Inventory & Stock',
                        labelHi: 'स्टॉक इन्वेंटरी',
                        isSelected: _selectedIndex == 2,
                        onTap: () => _onNavigate(2),
                      ),
                      _SidebarItem(
                        icon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet,
                        labelEn: 'Udhaar Book',
                        labelHi: 'उधार खाता बही',
                        isSelected: _selectedIndex == 3,
                        onTap: () => _onNavigate(3),
                        badgeText: 'Udhaar',
                        badgeColor: Colors.red.shade400,
                      ),
                      _SidebarItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long,
                        labelEn: 'Sales History',
                        labelHi: 'बिक्री का इतिहास',
                        isSelected: _selectedIndex == 4,
                        onTap: () => _onNavigate(4),
                      ),
                      _SidebarItem(
                        icon: Icons.category_outlined,
                        activeIcon: Icons.category,
                        labelEn: 'Categories',
                        labelHi: 'उत्पाद श्रेणियां',
                        isSelected: _selectedIndex == 5,
                        onTap: () => _onNavigate(5),
                      ),
                      _SidebarItem(
                        icon: Icons.file_download_outlined,
                        activeIcon: Icons.file_download,
                        labelEn: 'Excel Export',
                        labelHi: 'एक्सेल एक्सपोर्ट',
                        isSelected: _selectedIndex == 6,
                        onTap: () => _onNavigate(6),
                      ),
                      if (isAdmin)
                        _SidebarItem(
                          icon: Icons.manage_accounts_outlined,
                          activeIcon: Icons.manage_accounts,
                          labelEn: 'Users & Staff',
                          labelHi: 'कर्मचारी प्रबंधन',
                          isSelected: _selectedIndex == 7,
                          onTap: () => _onNavigate(7),
                        ),
                      _SidebarItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        labelEn: 'Settings',
                        labelHi: 'सेटिंग्स',
                        isSelected: _selectedIndex == 8,
                        onTap: () => _onNavigate(8),
                      ),
                    ],
                  ),
                ),

                // Bottom User Profile & Sign Out
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF090D16),
                    border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isAdmin ? Colors.amber.shade700 : AppTheme.primaryColor,
                        child: Text(
                          user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'User',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${user?.role ?? ""} (${user?.username ?? ""})',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                        tooltip: 'Sign Out / लॉगआउट',
                        onPressed: _confirmLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Page Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String labelEn;
  final String labelHi;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.labelEn,
    required this.labelHi,
    required this.isSelected,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labelEn,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        labelHi,
                        style: TextStyle(
                          color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
