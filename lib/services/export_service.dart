import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';

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


        _cell(e['type'] == 'Entrant' ? montant.toStringAsFixed(0) : ''),


        _cell(e['type'] == 'Sortant' ? montant.toStringAsFixed(0) : ''),


        _cell(solde.toStringAsFixed(0)),
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
                  _headerCell("Date"),
                  _headerCell("Antony"),
                  _headerCell("Miditra"),
                  _headerCell("Mivoaka"),
                  _headerCell("Am-pelantanana"),
                ],
              ),

              ..._buildGrandLivreRows(data),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Text("Totaly Vola Miditra : $totalEntrant"),
          pw.Text("Totaly Vola Mivoaka : $totalSortant"),
          pw.Text("Vola am-pelantanana : ${totalEntrant - totalSortant}"),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> exportToExcel(List<Map<String, dynamic>> data) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Feuille1'];

      sheet.appendRow([
        "Daty",
        "Antony",
        "Miditra",
        "Mivoaka",
        "Am-pelantanana",
      ]);

      double totalEntrant = 0;
      double totalSortant = 0;

      for (var e in data) {
        sheet.appendRow([
          e['date'].toString().split('T')[0],
          e['description'],
          e['type'] == 'Entrant',
          e['type'] == 'Sortant',
          e['montant'],
        ]);

        if (e['type'] == 'Entrant') {
          totalEntrant += e['montant'];
        } else {
          totalSortant += e['montant'];
        }
      }

      sheet.appendRow([]);
      sheet.appendRow(["Total Entrant", totalEntrant]);
      sheet.appendRow(["Total Sortant", totalSortant]);
      sheet.appendRow(["Solde", totalEntrant - totalSortant]);

      final directory = await getApplicationDocumentsDirectory();

      final path = "${directory.path}/transactions.xlsx";

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception("Erreur génération fichier");
      }

      final file = File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

      // Notification
      Fluttertoast.showToast(msg: "Fichier Excel exporté avec succès");

      // Ouvrir automatiquement le fichier
      await OpenFile.open(path);

      print("Excel exporté : $path");
    } catch (e) {
      print("Erreur export Excel : $e");
    }
  }
}
