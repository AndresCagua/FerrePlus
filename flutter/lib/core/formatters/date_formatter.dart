import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String forDisplay(DateTime value) =>
      DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  static String forApi(DateTime value) => value.toIso8601String();
}
