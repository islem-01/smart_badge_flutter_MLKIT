// lib/services/export_service.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'database_service.dart';

class ExportService {
  final _db = DatabaseService();

  Future<void> exportToPDF(String date) async {
    final list  = await _db.getAttendanceByDate(date);
    final stats = await _db.getTodayStats();
    final pdf   = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('RAPPORT DE PRÉSENCE',
                  style: pw.TextStyle(fontSize: 22,
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('Date: $date',
                  style: const pw.TextStyle(fontSize: 13, color: PdfColors.white)),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
          _statBox('Total',    '${stats['total']}',   PdfColors.blue),
          _statBox('Présents', '${stats['present']}', PdfColors.green),
          _statBox('Absents',  '${stats['absent']}',  PdfColors.red),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('Détail', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: ['Nom','Département','Entrée','Sortie','Durée']
                  .map((h) => _cell(h, header: true)).toList(),
            ),
            ...list.map((a) => pw.TableRow(children: [
              _cell(a.employeeName),
              _cell(a.department),
              _cell(_fmt(a.checkIn)),
              _cell(a.checkOut != null ? _fmt(a.checkOut!) : 'En cours'),
              _cell(a.workDurationFormatted),
            ])),
          ],
        ),
      ],
    ));

    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/rapport_$date.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Rapport – $date');
  }

  pw.Widget _statBox(String label, String val, PdfColor color) =>
      pw.Container(
        width: 90, padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: color),
            borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          pw.Text(val, style: pw.TextStyle(fontSize: 22,
              fontWeight: pw.FontWeight.bold, color: color)),
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        ]),
      );

  pw.Widget _cell(String t, {bool header = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: header ? 11 : 10)),
      );

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
