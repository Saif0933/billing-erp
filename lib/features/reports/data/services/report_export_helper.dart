import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportExportHelper {
  ReportExportHelper._();

  /// 1. Open / Share Excel (.csv) file directly with native spreadsheet viewers
  static Future<void> openExcelReport({
    required String fileName,
    required String csvContent,
    required String reportTitle,
  }) async {
    // Prefix UTF-8 BOM so Microsoft Excel cleanly renders Indian Rupees (₹) and UTF-8 characters
    final contentWithBom = '\uFEFF$csvContent';
    final bytes = Uint8List.fromList(utf8.encode(contentWithBom));

    final cleanName = fileName.endsWith('.csv')
        ? fileName
        : (fileName.endsWith('.xlsx')
            ? '${fileName.substring(0, fileName.length - 5)}.csv'
            : '$fileName.csv');

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: cleanName,
          mimeType: 'application/vnd.ms-excel',
        ),
      ],
      subject: '$reportTitle Export (Excel)',
      text: 'Here is the $reportTitle spreadsheet document.',
    );
  }

  /// 2. Generate and Open / Share PDF document directly with native PDF viewers
  static Future<void> openPdfReport({
    required String title,
    required String dateRange,
    required String warehouse,
    required List<String> headers,
    required List<List<String>> rows,
    required Map<String, String> summaryMetrics,
    String? businessName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        (businessName != null && businessName.isNotEmpty)
                            ? businessName.toUpperCase()
                            : 'BILLING ERP',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        title.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Period: $dateRange',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Location: $warehouse',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // KPI Summary Badges
              if (summaryMetrics.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: summaryMetrics.entries.map((entry) {
                      return pw.Column(
                        children: [
                          pw.Text(
                            entry.key.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            entry.value,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          if (rows.isEmpty) {
            return [
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Center(
                  child: pw.Text(
                    'No records found for the selected period.',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ),
              ),
            ];
          }

          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              headerHeight: 22,
              cellHeight: 18,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey50,
              ),
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final sanitizedTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '${sanitizedTitle}_report.pdf';

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [
        XFile.fromData(
          pdfBytes,
          name: fileName,
          mimeType: 'application/pdf',
        ),
      ],
      subject: '$title PDF Document',
      text: 'Please find attached the $title PDF.',
    );
  }
}
