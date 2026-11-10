import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubh_traders/features/settings/providers/settings_provider.dart';

enum AppLanguage {
  english,
  hindi,
  dual,
}

class AppLocaleNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString('app_language') ?? 'hindi';
    switch (saved) {
      case 'english':
        return AppLanguage.english;
      case 'dual':
        return AppLanguage.dual;
      default:
        return AppLanguage.hindi;
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = ref.read(sharedPreferencesProvider);
    String val = 'hindi';
    if (lang == AppLanguage.english) val = 'english';
    if (lang == AppLanguage.dual) val = 'dual';
    await prefs.setString('app_language', val);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, AppLanguage>(AppLocaleNotifier.new);

class L10n {
  static const Map<String, Map<String, String>> _strings = {
    // Navigation
    'dashboard': {'en': 'Dashboard', 'hi': 'डैशबोर्ड'},
    'pos': {'en': 'Point of Sale (POS)', 'hi': 'बिलिंग काउंटर (POS)'},
    'inventory': {'en': 'Inventory & Stock', 'hi': 'इन्वेंटरी एवं स्टॉक'},
    'udhaar_book': {'en': 'Udhaar Book', 'hi': 'उधार खाता बही'},
    'sales_history': {'en': 'Sales History', 'hi': 'बिक्री का इतिहास'},
    'categories': {'en': 'Categories', 'hi': 'उत्पाद श्रेणियां'},
    'excel_export': {'en': 'Excel Export', 'hi': 'एक्सेल रिपोर्ट निर्यात'},
    'audit_logs': {'en': 'Audit Logs', 'hi': 'ऑडिट लॉग्स (कार्य विवरण)'},
    'users_staff': {'en': 'Users & Staff', 'hi': 'उपयोगकर्ता एवं स्टाफ'},
    'database_backup': {'en': 'Database Backups', 'hi': 'डेटाबेस बैकअप प्रबंधन'},
    'settings': {'en': 'Settings', 'hi': 'सेटिंग्स एवं व्यवस्था'},
    
    // Auth & Users
    'sign_in': {'en': 'Sign In', 'hi': 'लॉगिन करें'},
    'logout': {'en': 'Sign Out', 'hi': 'लॉगआउट'},
    'switch_user': {'en': 'Switch User', 'hi': 'उपयोगकर्ता बदलें'},
    'select_user': {'en': 'Select Account', 'hi': 'खाता चुनें'},
    'enter_pin': {'en': 'Enter PIN / Password', 'hi': 'पिन या पासवर्ड दर्ज करें'},
    'admin_login': {'en': 'Owner / Admin Login', 'hi': 'मालिक / एडमिन लॉगिन'},
    'staff_login': {'en': 'Employee Login', 'hi': 'कर्मचारी लॉगिन'},
    'role_admin': {'en': 'Owner (Admin)', 'hi': 'मालिक (एडमिन)'},
    'role_employee': {'en': 'Employee', 'hi': 'कर्मचारी (स्टाफ)'},
    
    // POS & Cart
    'customer_info': {'en': 'Customer Information', 'hi': 'ग्राहक की जानकारी'},
    'walk_in_customer': {'en': 'New / Walk-in Customer', 'hi': 'नया / काउंटर ग्राहक'},
    'customer_name': {'en': 'Customer Name', 'hi': 'ग्राहक का नाम'},
    'customer_phone': {'en': 'Phone Number', 'hi': 'मोबाइल नंबर'},
    'cart_items': {'en': 'Cart Items', 'hi': 'बिल में चयनित सामग्री'},
    'empty_cart': {'en': 'Cart is empty. Select items to add.', 'hi': 'कार्ट खाली है। उत्पाद जोड़ें।'},
    'total_payable': {'en': 'Total Payable', 'hi': 'कुल देय राशि'},
    'payment_mode': {'en': 'Payment Mode', 'hi': 'भुगतान का माध्यम'},
    'cash': {'en': 'Cash', 'hi': 'नकद (Cash)'},
    'online_upi': {'en': 'Online / UPI', 'hi': 'ऑनलाइन / UPI'},
    'udhaar': {'en': 'Udhaar Credit', 'hi': 'उधार (Udhaar)'},
    'view_receipt': {'en': 'View Receipt First', 'hi': 'पहले बिल देखें'},
    'print_receipt': {'en': 'Print Bill', 'hi': 'बिल प्रिंट करें'},
    'checkout_complete': {'en': 'Complete Checkout', 'hi': 'बिक्री पूरी करें'},
    'scan_to_pay': {'en': 'Scan QR Code to Pay via UPI', 'hi': 'UPI से भुगतान के लिए QR कोड स्कैन करें'},

    // Inventory
    'add_product': {'en': 'Add New Product', 'hi': 'नया उत्पाद जोड़ें'},
    'item_name': {'en': 'Item Name', 'hi': 'उत्पाद का नाम'},
    'purchase_price': {'en': 'Purchase Rate', 'hi': 'खरीद दर (₹)'},
    'selling_price': {'en': 'Selling Rate', 'hi': 'बिक्री दर (₹)'},
    'stock_qty': {'en': 'Current Stock', 'hi': 'मौजूदा स्टॉक'},
    'unit': {'en': 'Unit', 'hi': 'इकाई'},
    'brand_logo': {'en': 'Brand / Company', 'hi': 'ब्रांड / कंपनी'},
    'low_stock_threshold': {'en': 'Low Stock Alert Limit', 'hi': 'न्यूनतम स्टॉक चेतावनी सीमा'},
    'restock': {'en': 'Add Stock', 'hi': 'स्टॉक जोड़ें'},
    'low_stock': {'en': 'LOW STOCK', 'hi': 'कम स्टॉक'},

    // Udhaar
    'total_pending_udhaar': {'en': 'Total Pending Udhaar', 'hi': 'कुल बकाया उधार'},
    'receive_payment': {'en': 'Receive Payment', 'hi': 'भुगतान प्राप्त करें'},
    'view_statement': {'en': 'Account Statement', 'hi': 'खाता विवरण'},
    'amount_received': {'en': 'Amount Received (₹)', 'hi': 'प्राप्त राशि (₹)'},

    // Common
    'save': {'en': 'Save', 'hi': 'सुरक्षित करें'},
    'cancel': {'en': 'Cancel', 'hi': 'रद्द करें'},
    'delete': {'en': 'Delete', 'hi': 'हटाएं'},
    'search': {'en': 'Search...', 'hi': 'खोजें...'},
    'filter': {'en': 'Filter', 'hi': 'फ़िल्टर'},
    'all': {'en': 'All', 'hi': 'सभी'},
    'actions': {'en': 'Actions', 'hi': 'कार्य'},
  };

  static String tr(String key, AppLanguage lang) {
    final entry = _strings[key];
    if (entry == null) return key;

    switch (lang) {
      case AppLanguage.english:
        return entry['en'] ?? key;
      case AppLanguage.hindi:
        return entry['hi'] ?? entry['en'] ?? key;
      case AppLanguage.dual:
        final en = entry['en'] ?? key;
        final hi = entry['hi'];
        return hi != null && hi != en ? '$en / $hi' : en;
    }
  }
}
