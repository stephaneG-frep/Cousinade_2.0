import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String shortDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static String shortDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String chatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}
