import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class FollowUpExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return _dateFormat.format(date);
  }

  /// Export Follow-up Report as PDF document
  static Future<void> exportToPdf(List<UserData> users) async {
    try {
      final pdf = pw.Document();
      final dateStr = _dateFormat.format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              // Header Title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Follow-up & Attendance Report',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Egtma3na Platform Admin System',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'Date: $dateStr',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Summary stats
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfSummaryTile('Total Users', '${users.length}'),
                  _buildPdfSummaryTile(
                    'Need Follow-up',
                    '${users.where((u) => u.followUpStatus == "Needs Follow-up" || (u.attendancePercentage ?? 0) < 50).length}',
                  ),
                  _buildPdfSummaryTile(
                    'Urgent Cases',
                    '${users.where((u) => u.followUpStatus == "Urgent").length}',
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // User Table
              pw.TableHelper.fromTextArray(
                headers: [
                  'Name',
                  'Phone',
                  'Status',
                  'Att. %',
                  'Last Call',
                  'Last Visit',
                  'Notes',
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.indigo800,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                data: users.map((u) {
                  return [
                    u.name ?? 'No Name',
                    u.phone ?? 'N/A',
                    u.followUpStatus ?? 'Regular',
                    '${(u.attendancePercentage ?? 0.0).toStringAsFixed(0)}%',
                    _formatDate(u.lastCallDate),
                    _formatDate(u.lastVisitDate),
                    u.notes ?? '-',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated automatically by Egtma3na Platform Admin UI',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      final outputDir = await getTemporaryDirectory();
      final filePath =
          '${outputDir.path}/FollowUp_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: '📊 Follow-up Summary Report (PDF)');
    } catch (e) {
      debugPrint('Error generating PDF report: $e');
      rethrow;
    }
  }

  static pw.Widget _buildPdfSummaryTile(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
      ],
    );
  }

  /// Export Follow-up Report as Excel (.xlsx) file
  static Future<void> exportToExcel(List<UserData> users) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['FollowUp_Report'];
      excel.setDefaultSheet('FollowUp_Report');

      // Add Headers
      List<String> headers = [
        'Name',
        'Email',
        'Phone',
        'Father Phone',
        'Mother Phone',
        'Follow-up Status',
        'Attendance %',
        'Need Visit',
        'Last Contact',
        'Last Call Date',
        'Last Visit Date',
        'Group',
        'Address',
        'School',
        'University',
        'Work',
        'Notes',
        'Servant Notes',
      ];

      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Add User Rows
      for (var u in users) {
        sheetObject.appendRow([
          TextCellValue(u.name ?? ''),
          TextCellValue(u.email ?? ''),
          TextCellValue(u.phone ?? ''),
          TextCellValue(u.fatherPhone ?? ''),
          TextCellValue(u.motherPhone ?? ''),
          TextCellValue(u.followUpStatus ?? 'Regular'),
          TextCellValue(
            '${(u.attendancePercentage ?? 0.0).toStringAsFixed(1)}%',
          ),
          TextCellValue(u.needVisit == true ? 'Yes' : 'No'),
          TextCellValue(_formatDate(u.lastContact)),
          TextCellValue(_formatDate(u.lastCallDate)),
          TextCellValue(_formatDate(u.lastVisitDate)),
          TextCellValue(u.group ?? 'General'),
          TextCellValue(u.address ?? ''),
          TextCellValue(u.school ?? ''),
          TextCellValue(u.university ?? ''),
          TextCellValue(u.work ?? ''),
          TextCellValue(u.notes ?? ''),
          TextCellValue(u.servantNotes ?? ''),
        ]);
      }

      final outputDir = await getTemporaryDirectory();
      final filePath =
          '${outputDir.path}/FollowUp_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);

      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: '📊 Follow-up Summary Report (Excel)');
      }
    } catch (e) {
      debugPrint('Error generating Excel report: $e');
      rethrow;
    }
  }
}
