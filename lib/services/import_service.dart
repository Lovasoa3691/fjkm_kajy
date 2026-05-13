import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:fjkm_kajy/db/db_helper.dart';

class ImportService {
  static Future<void> importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );

    if (result == null) return;

    final path = result.files.single.path!;
    final file = File(path);

    if (path.endsWith('.xlsx')) {
      await _importExcel(file);
    } else if (path.endsWith('.csv')) {
      await _importCSV(file);
    }
  }

  static Future<void> _importExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables[excel.tables.keys.first]!;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      if (row.isEmpty) continue;

      _processRow([row[0]?.value, row[1]?.value, row[2]?.value, row[3]?.value]);
    }
  }

  static Future<void> _importCSV(File file) async {
    final input = file.readAsStringSync();
    List<List<dynamic>> rows = const CsvToListConverter().convert(input);

    for (int i = 1; i < rows.length; i++) {
      _processRow(rows[i]);
    }
  }

  static Future<void> _processRow(List<dynamic> row) async {
    try {
      String dateRaw = row[0]?.toString() ?? '';
      String description = row[1]?.toString().trim() ?? '';

      double entrant = double.tryParse(row[2]?.toString() ?? '') ?? 0;

      double sortant = double.tryParse(row[3]?.toString() ?? '') ?? 0;

      if (description.isEmpty) return;

      double montant = entrant > 0 ? entrant : sortant;
      String type = entrant > 0 ? 'Entrant' : 'Sortant';

      if (montant == 0) return;

      String date = _parseDate(dateRaw);

      final db = await DatabaseHelper.instance.database;

      final existing = await db.query(
        'operations',
        where: 'date = ? AND description = ? AND montant = ? AND type = ?',
        whereArgs: [date, description, montant, type],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        print("Doublon ignoré : $description");
        return;
      }

      await DatabaseHelper.instance.insertOperation({
        'type': type,
        'date': date,
        'montant': montant,
        'description': description,
      });
    } catch (e) {
      print("Erreur import: $e");
    }
  }

  static String _parseDate(String input) {
    try {
      if (input.contains('/')) {
        final parts = input.split('/');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        ).toIso8601String();
      }
      return DateTime.parse(input).toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }
}
