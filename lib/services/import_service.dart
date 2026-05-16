import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:fjkm_kajy/db/db_helper.dart';
import 'package:flutter/material.dart';

class ImportService {
  static Future<void> importFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );

    if (result == null) return;

    final path = result.files.single.path!;
    final file = File(path);

    if (path.endsWith('.xlsx')) {
      await _importExcel(file, context);
    } else if (path.endsWith('.csv')) {
      await _importCSV(file, context);
    }
  }

  static Future<void> _importExcel(File file, BuildContext context) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables[excel.tables.keys.first]!;

    int importedCount = 0;
    int duplicateCount = 0;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      if (row.isEmpty) continue;

      final result = await _processRow([
        row[0]?.value,
        row[1]?.value,
        row[2]?.value,
        row[3]?.value,
      ]);

      if (result == "imported") {
        importedCount++;
      }

      if (result == "duplicate") {
        duplicateCount++;
      }
    }

    _showImportResult(context, importedCount, duplicateCount);
  }

  static Future<void> _importCSV(File file, BuildContext context) async {
    final input = file.readAsStringSync();

    List<List<dynamic>> rows = const CsvToListConverter().convert(input);

    int importedCount = 0;
    int duplicateCount = 0;

    for (int i = 1; i < rows.length; i++) {
      final result = await _processRow(rows[i]);

      if (result == "imported") {
        importedCount++;
      }

      if (result == "duplicate") {
        duplicateCount++;
      }
    }

    _showImportResult(context, importedCount, duplicateCount);
  }

  static void _showImportResult(
    BuildContext context,
    int importedCount,
    int duplicateCount,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: duplicateCount > 0 ? Colors.orange : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(
              duplicateCount > 0
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle,
              color: Colors.white,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                duplicateCount > 0
                    ? "$importedCount importée(s), $duplicateCount doublon(s) ignoré(s)"
                    : "$importedCount transaction(s) importée(s) avec succès",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<String> _processRow(List<dynamic> row) async {
    try {
      String dateRaw = row[0]?.toString() ?? '';
      String description = row[1]?.toString().trim() ?? '';

      double entrant = double.tryParse(row[2]?.toString() ?? '') ?? 0;

      double sortant = double.tryParse(row[3]?.toString() ?? '') ?? 0;

      if (description.isEmpty) return "ignored";

      double montant = entrant > 0 ? entrant : sortant;
      String type = entrant > 0 ? 'Entrant' : 'Sortant';

      if (montant == 0) return "ignored";

      String date = _parseDate(dateRaw);

      final db = await DatabaseHelper.instance.database;

      final existing = await db.query(
        'trasanctions',
        where: 'date = ? AND description = ? AND montant = ? AND type = ?',
        whereArgs: [date, description, montant, type],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        print("Doublon ignoré : $description");
        return "duplicate";
      }

      await DatabaseHelper.instance.insertOperation({
        'type': type,
        'date': date,
        'montant': montant,
        'description': description,
      });

      return "imported";
    } catch (e) {
      print("Erreur import: $e");
      return "error";
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
