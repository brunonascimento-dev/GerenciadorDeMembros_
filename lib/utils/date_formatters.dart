import 'package:intl/intl.dart';

class DateFormatters {
  // Formato curto: 18/01/2026
  static String simple(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  // Formato longo para a carta: 18 de Janeiro de 2026
  static String fullDate(DateTime date) {
    return DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(date);
  }
}