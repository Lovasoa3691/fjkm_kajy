import 'package:fjkm_kajy/db/db_helper.dart';

class TransactionService {
  static Future<List<Map<String, dynamic>>> getFilteredData({
    DateTime? startDate,
    DateTime? endDate,
    String type = 'Tous',
  }) async {
    final allData = await DatabaseHelper.instance.getAllTrasanctions();

    return allData.where((item) {
      final DateTime itemDate = DateTime.parse(item['date']);

      final bool matchType = type == 'Tous' || item['type'] == type;

      final bool matchStart =
          startDate == null ||
          !itemDate.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day),
          );

      final bool matchEnd =
          endDate == null ||
          !itemDate.isAfter(
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          );

      return matchType && matchStart && matchEnd;
    }).toList()..sort((a, b) {
      return DateTime.parse(a['date']).compareTo(DateTime.parse(b['date']));
    });
  }
}
