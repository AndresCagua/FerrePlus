import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String forDisplay(double value) => NumberFormat.currency(locale: 'es', symbol: r'$').format(value);
}
