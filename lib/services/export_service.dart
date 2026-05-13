import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

final formatter = NumberFormat("#,##0", "fr_FR");

pw.Widget _cell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
  );
}

pw.Widget _headerCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    ),
  );
}

List<pw.TableRow> _buildGrandLivreRows(List<Map<String, dynamic>> data) {
  double solde = 0;

  return data.map((e) {
    double montant = (e['montant'] as num).toDouble();

    if (e['type'] == 'Entrant') {
      solde += montant;
    } else {
      solde -= montant;
    }

    return pw.TableRow(
      children: [
        _cell(e['date'].toString().split('T')[0]),
        _cell(e['description'] ?? ''),

        _cell(e['type'] == 'Entrant' ? formatter.format(montant) : ''),

        _cell(e['type'] == 'Sortant' ? formatter.format(montant) : ''),

        _cell(formatter.format(solde)),
      ],
    );
  }).toList();
}

class ExportService {
  static Future<void> exportToPDF(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    double totalEntrant = 0;
    double totalSortant = 0;

    for (var e in data) {
      if (e['type'] == 'Entrant') {
        totalEntrant += e['montant'];
      } else {
        totalSortant += e['montant'];
      }
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text("TATITRA ARA-BOLA", style: pw.TextStyle(fontSize: 20)),

          pw.SizedBox(height: 20),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _headerCell("Daty"),
                  _headerCell("Antony"),
                  _headerCell("Miditra (Ar)"),
                  _headerCell("Mivoaka (Ar)"),
                  _headerCell("Am-pelantanana (Ar)"),
                ],
              ),

              ..._buildGrandLivreRows(data),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Text(
            "Totaly Vola Miditra : ${formatter.format(totalEntrant)} Ariary",
          ),
          pw.Text(
            "Totaly Vola Mivoaka : ${formatter.format(totalSortant)} Ariary",
          ),
          pw.Text(
            "Vola am-pelantanana : ${formatter.format(totalEntrant - totalSortant)} Ariary",
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> exportToExcel(List<Map<String, dynamic>> data) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Feuille1'];

      // if (excel.sheets.containsKey('Sheet1')) {
      //   excel.delete('Sheet1');
      // }

      sheet.appendRow([
        "Daty",
        "Antony",
        "Miditra (Ar)",
        "Mivoaka (Ar)",
        "Am-pelantanana (Ar)",
      ]);

      double totalEntrant = 0;
      double totalSortant = 0;

      for (var e in data) {
        double montant = double.tryParse(e['montant'].toString()) ?? 0;

        if (e['type'] == 'Entrant') {
          totalEntrant += montant;
        } else {
          totalSortant += montant;
        }

        double solde = totalEntrant - totalSortant;

        sheet.appendRow([
          e['date'].toString().split('T')[0],

          e['description'],

          e['type'] == 'Entrant' ? "${formatter.format(montant)} " : "",

          e['type'] == 'Sortant' ? "${formatter.format(montant)} " : "",

          "${formatter.format(solde)} ",
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow(["Total Entrant", "${formatter.format(totalEntrant)} "]);
      sheet.appendRow(["Total Sortant", "${formatter.format(totalSortant)} "]);
      sheet.appendRow([
        "Solde",
        "${formatter.format(totalEntrant - totalSortant)} ",
      ]);

      final directory = await getApplicationDocumentsDirectory();

      final path = "${directory.path}/TATITRA ARA-BOLA.xlsx";

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception("Erreur génération fichier");
      }

      final file = File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

      Fluttertoast.showToast(msg: "Fichier Excel exporté avec succès");

      await OpenFile.open(path);

      print("Excel exporté : $path");
    } catch (e) {
      print("Erreur export Excel : $e");
    }
  }
}
