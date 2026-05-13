import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final formatter = NumberFormat("#,###.00", "fr_FR");
  return "${formatter.format(amount)} Ar";
}