import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shubh_traders/core/database/database.dart';
import 'package:shubh_traders/core/database/database_provider.dart';

class CartItem {
  final Item item;
  final double qty;
  final double soldPrice;

  CartItem({
    required this.item,
    required this.qty,
    required this.soldPrice,
  });

  double get total => qty * soldPrice;

  CartItem copyWith({
    double? qty,
    double? soldPrice,
  }) {
    return CartItem(
      item: item,
      qty: qty ?? this.qty,
      soldPrice: soldPrice ?? this.soldPrice,
    );
  }
}

class PosState {
  final List<CartItem> cart;
  final Customer? selectedCustomer;
  final String customerName;
  final String customerPhone;
  final String paymentMethod; // 'Cash', 'Online', 'Udhaar'
  final String notes;
  final bool isProcessing;

  const PosState({
    this.cart = const [],
    this.selectedCustomer,
    this.customerName = '',
    this.customerPhone = '',
    this.paymentMethod = 'Cash',
    this.notes = '',
    this.isProcessing = false,
  });

  double get grandTotal => cart.fold(0.0, (sum, item) => sum + item.total);
  int get itemCount => cart.length;

  PosState copyWith({
    List<CartItem>? cart,
    Customer? selectedCustomer,
    bool clearCustomer = false,
    String? customerName,
    String? customerPhone,
    String? paymentMethod,
    String? notes,
    bool? isProcessing,
  }) {
    return PosState(
      cart: cart ?? this.cart,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class PosNotifier extends Notifier<PosState> {
  @override
  PosState build() {
    return const PosState();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  void addItem(Item item) {
    final existingIndex = state.cart.indexWhere((c) => c.item.id == item.id);
    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state.cart);
      final current = updatedList[existingIndex];
      updatedList[existingIndex] = current.copyWith(qty: current.qty + 1);
      state = state.copyWith(cart: updatedList);
    } else {
      state = state.copyWith(
        cart: [
          ...state.cart,
          CartItem(
            item: item,
            qty: 1,
            soldPrice: item.sellingPrice,
          ),
        ],
      );
    }
  }

  void updateQuantity(int itemId, double qty) {
    if (qty <= 0) {
      removeItem(itemId);
      return;
    }
    final updatedList = state.cart.map((c) {
      if (c.item.id == itemId) {
        return c.copyWith(qty: qty);
      }
      return c;
    }).toList();
    state = state.copyWith(cart: updatedList);
  }

  void updatePrice(int itemId, double newPrice) {
    final updatedList = state.cart.map((c) {
      if (c.item.id == itemId) {
        return c.copyWith(soldPrice: newPrice);
      }
      return c;
    }).toList();
    state = state.copyWith(cart: updatedList);
  }

  void removeItem(int itemId) {
    state = state.copyWith(
      cart: state.cart.where((c) => c.item.id != itemId).toList(),
    );
  }

  void selectCustomer(Customer? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true, customerName: '', customerPhone: '');
    } else {
      state = state.copyWith(
        selectedCustomer: customer,
        customerName: customer.name,
        customerPhone: customer.phone,
      );
    }
  }

  void setCustomerDetails(String name, String phone) {
    state = state.copyWith(
      customerName: name,
      customerPhone: phone,
      clearCustomer: state.selectedCustomer?.name != name,
    );
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void clear() {
    state = const PosState();
  }

  Future<int?> checkout({required int userId, required String username}) async {
    if (state.cart.isEmpty) return null;
    state = state.copyWith(isProcessing: true);

    try {
      int? effectiveCustomerId = state.selectedCustomer?.id;

      // If customer info is provided but not linked to existing customer, create new customer
      if (effectiveCustomerId == null && (state.customerName.trim().isNotEmpty || state.customerPhone.trim().isNotEmpty)) {
        final existingCust = await (_db.select(_db.customers)
              ..where((c) => c.phone.equals(state.customerPhone.trim()) & c.phone.isNotNull()))
            .getSingleOrNull();

        if (existingCust != null) {
          effectiveCustomerId = existingCust.id;
        } else if (state.customerName.trim().isNotEmpty) {
          effectiveCustomerId = await _db.into(_db.customers).insert(
            CustomersCompanion.insert(
              name: state.customerName.trim(),
              phone: state.customerPhone.trim(),
              totalDue: const Value(0.0),
            ),
          );
        }
      }

      // If Udhaar payment mode is selected, customer MUST be present
      if (state.paymentMethod == 'Udhaar' && effectiveCustomerId == null) {
        throw Exception('Customer Name & Phone are required for Udhaar sales / उधार के लिए ग्राहक का नाम आवश्यक है');
      }

      final payloads = state.cart.map((c) {
        return CartItemPayload(
          itemId: c.item.id,
          qty: c.qty,
          soldPrice: c.soldPrice,
          total: c.total,
        );
      }).toList();

      final saleId = await _db.executeSaleTransaction(
        userId: userId,
        username: username,
        customerId: effectiveCustomerId,
        totalAmount: state.grandTotal,
        paymentMethod: state.paymentMethod,
        cartItems: payloads,
        notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
      );

      // Reset cart
      state = const PosState();
      return saleId;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }
}

final posProvider = NotifierProvider<PosNotifier, PosState>(PosNotifier.new);

final allCustomersStreamProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
});
