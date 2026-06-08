import 'package:intl/intl.dart';

class CurrencyFormat {
  static String convertToIdr(dynamic number, {int decimalDigit = 0}) {
    NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: decimalDigit,
    );
    return currencyFormatter.format(number);
  }
}

class DateFormatUtil {
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  static String formatDayDate(DateTime date) {
     return DateFormat('EEEE, d MMM', 'id').format(date);
  }
}
