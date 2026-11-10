import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/core/localization/app_locale.dart';
import 'package:shubh_traders/core/theme/app_theme.dart';
import 'package:shubh_traders/core/widgets/dual_text.dart';
import 'package:shubh_traders/features/audit/screens/audit_logs_screen.dart';
import 'package:shubh_traders/features/auth/providers/auth_provider.dart';
import 'package:shubh_traders/features/auth/screens/users_screen.dart';
import 'package:shubh_traders/features/backup/screens/backup_screen.dart';
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

  void _confirmLogout({bool isSwitching = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: DualText(
          en: isSwitching ? 'Switch User' : 'Sign Out',
          hi: isSwitching ? 'उपयोगकर्ता बदलें' : 'लॉगआउट करें',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(isSwitching
            ? 'Do you want to sign out and log in as another user?'
            : 'Are you sure you want to log out of Shubh Traders?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            child: Text(isSwitching ? 'Switch' : 'Logout'),
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
    final currentLang = ref.watch(appLocaleProvider);

    // List of available pages based on role
    final List<Widget> pages = [
      DashboardScreen(onNavigateTab: _onNavigate),
      const PosScreen(),
      const InventoryScreen(),
      const UdhaarBookScreen(),
      const SalesHistoryScreen(),
      const CategoriesScreen(),
      const ExportScreen(),
      if (isAdmin) const AuditLogsScreen(),
      if (isAdmin) const UsersScreen(),
      if (isAdmin) const BackupScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          // TOP HEADER BAR: Shop Brand on left, Global Language Selector & User Profile on TOP RIGHT
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                // Brand Left
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryNavy, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'SHUBH TRADERS',
                          style: TextStyle(
                            color: AppTheme.primaryNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'शुभ ट्रेडर्स • Hardware & Building Materials',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),

                // Language Quick Selector in Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate, size: 16, color: AppTheme.primaryNavy),
                      const SizedBox(width: 6),
                      DropdownButton<AppLanguage>(
                        value: currentLang,
                        underline: const SizedBox(),
                        isDense: true,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                        items: const [
                          DropdownMenuItem(value: AppLanguage.hindi, child: Text('हिन्दी (Hindi)')),
                          DropdownMenuItem(value: AppLanguage.english, child: Text('English')),
                          DropdownMenuItem(value: AppLanguage.dual, child: Text('Dual (दोनों)')),
                        ],
                        onChanged: (lang) {
                          if (lang != null) ref.read(appLocaleProvider.notifier).setLanguage(lang);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // USER PROFILE ON TOP RIGHT
                PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  tooltip: 'User Profile & Switch Account',
                  onSelected: (val) {
                    if (val == 'switch') {
                      _confirmLogout(isSwitching: true);
                    } else if (val == 'logout') {
                      _confirmLogout(isSwitching: false);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('@${user?.username ?? ""} • ${isAdmin ? "Owner (Admin)" : "Employee"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'switch',
                      child: Row(
                        children: [
                          Icon(Icons.switch_account_outlined, size: 18, color: AppTheme.primaryNavy),
                          SizedBox(width: 10),
                          Text('Switch User / खाता बदलें'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: AppTheme.dangerRed),
                          SizedBox(width: 10),
                          Text('Sign Out / लॉगआउट', style: TextStyle(color: AppTheme.dangerRed)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isAdmin ? AppTheme.warningAmber : AppTheme.primaryNavy,
                          child: Text(
                            user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.fullName ?? 'User',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              isAdmin ? 'Owner (Admin)' : 'Staff Employee',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isAdmin ? AppTheme.warningAmber : AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MAIN BODY: Left Navigation Rail & Content
          Expanded(
            child: Row(
              children: [
                // Desktop Navigation Sidebar
                Container(
                  width: 240,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(right: BorderSide(color: Color(0xFF1E293B))),
                  ),
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
                        badgeColor: AppTheme.dangerRed,
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
                      if (isAdmin) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text(
                            'ADMIN CONSOLE',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        _SidebarItem(
                          icon: Icons.history_edu_outlined,
                          activeIcon: Icons.history_edu,
                          labelEn: 'Audit Trail',
                          labelHi: 'ऑडिट लॉग्स',
                          isSelected: _selectedIndex == 7,
                          onTap: () => _onNavigate(7),
                          badgeText: 'Audit',
                          badgeColor: const Color(0xFF7C3AED),
                        ),
                        _SidebarItem(
                          icon: Icons.manage_accounts_outlined,
                          activeIcon: Icons.manage_accounts,
                          labelEn: 'Users & Staff',
                          labelHi: 'कर्मचारी प्रबंधन',
                          isSelected: _selectedIndex == 8,
                          onTap: () => _onNavigate(8),
                        ),
                        _SidebarItem(
                          icon: Icons.backup_outlined,
                          activeIcon: Icons.backup,
                          labelEn: 'Database Backups',
                          labelHi: 'डेटाबेस बैकअप',
                          isSelected: _selectedIndex == 9,
                          onTap: () => _onNavigate(9),
                        ),
                      ],
                      const Divider(color: Color(0xFF1E293B)),
                      _SidebarItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        labelEn: 'Settings',
                        labelHi: 'सेटिंग्स',
                        isSelected: _selectedIndex == (isAdmin ? 10 : 7),
                        onTap: () => _onNavigate(isAdmin ? 10 : 7),
                      ),
                    ],
                  ),
                ),

                // Main Page Content with Responsive Box Constraints
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return IndexedStack(
                        index: _selectedIndex.clamp(0, pages.length - 1),
                        children: pages,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLocaleProvider);

    String primaryText;
    String? subText;
    if (lang == AppLanguage.english) {
      primaryText = labelEn;
    } else if (lang == AppLanguage.hindi) {
      primaryText = labelHi;
    } else {
      primaryText = labelEn;
      subText = labelHi;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: isSelected ? AppTheme.primaryNavy : Colors.transparent,
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
                        primaryText,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (subText != null)
                        Text(
                          subText,
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
