import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _currencyCompact = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateIsoFormat = DateFormat('yyyy-MM-dd');

  static String currency(double amount, {bool compact = false}) {
    if (compact && amount.abs() >= 1000) {
      return _currencyCompact.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String date(DateTime dt) => _dateFormat.format(dt);
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt);
  static String time(DateTime dt) => _timeFormat.format(dt);
  static String dateIso(DateTime dt) => _dateIsoFormat.format(dt);

  static String qty(double quantity, [String? unit]) {
    final formatted = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(2);
    return unit != null && unit.isNotEmpty ? '$formatted $unit' : formatted;
  }
}
