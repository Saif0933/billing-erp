import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/file_downloader_helper.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../presentation/providers/financial_statements_provider.dart';

class FinancialStatementExportHelper {
  FinancialStatementExportHelper._();

  /// 1. Download Financial Statement as Excel (.csv with UTF-8 BOM)
  static Future<void> downloadExcelStatement({
    required BuildContext context,
    required WidgetRef ref,
    required FinancialStatementsSummaryData summary,
    required FinancialStatementFilterState filter,
  }) async {
    try {
      AppFeedback.showSnackbar(
        context,
        message: 'Downloading ${filter.reportTypeLabel} in Excel...',
      );

      String csvContent = '';
      try {
        final res = await ref
            .read(financialStatementsNotifierProvider.notifier)
            .exportStatement(format: 'csv');
        csvContent = res['content']?.toString() ?? '';
      } catch (_) {
        // Fallback to local generation if backend is offline
      }

      if (csvContent.isEmpty) {
        csvContent = _generateCsv(summary, filter);
      }

      final fileName = '${_sanitize(filter.reportTypeLabel)}_Statement.csv';
      await downloadFileToDevice(
        content: csvContent,
        fileName: fileName,
        mimeType: 'text/csv;charset=utf-8',
      );

      if (context.mounted) {
        AppFeedback.showSnackbar(
          context,
          message: '${filter.reportTypeLabel} downloaded for Excel successfully!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Failed to download Excel file: $e',
          isError: true,
        );
      }
    }
  }

  /// 2. Download Financial Statement as PDF
  static Future<void> downloadPdfStatement({
    required BuildContext context,
    required FinancialStatementsSummaryData summary,
    required FinancialStatementFilterState filter,
  }) async {
    try {
      AppFeedback.showSnackbar(
        context,
        message: 'Generating ${filter.reportTypeLabel} PDF...',
      );

      final pdfBytes = await _generatePdf(summary, filter);
      final fileName = '${_sanitize(filter.reportTypeLabel)}_Statement.pdf';

      await downloadBytesToDevice(
        bytes: pdfBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );

      if (context.mounted) {
        AppFeedback.showSnackbar(
          context,
          message: '${filter.reportTypeLabel} PDF downloaded successfully!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Failed to generate PDF: $e',
          isError: true,
        );
      }
    }
  }

  /// Helper to generate PDF document bytes
  static Future<Uint8List> _generatePdf(
    FinancialStatementsSummaryData summary,
    FinancialStatementFilterState filter,
  ) async {
    final pdf = pw.Document();

    final hasSections = summary.sections.isNotEmpty;
    final primaryColor = PdfColor.fromHex('15803D');
    final darkHeaderBg = PdfColor.fromHex('0F172A');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context ctx) {
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
                        summary.companyName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: darkHeaderBg,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        filter.reportTypeLabel.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Period: ${filter.dateRangeLabel}',
                        style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Currency: INR (Rs.)',
                        style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Generated: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Tax Bunny Billing ERP • Confidential Financial Statement',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
        build: (pw.Context ctx) {
          final List<pw.Widget> widgets = [];

          // Column Headers Row
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      'PARTICULARS',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      '${summary.currentPeriodLabel}\n(Current Period)',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      '${summary.previousPeriodLabel}\n(${filter.compareWith})',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '% CHANGE',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 6));

          if (hasSections) {
            for (final section in summary.sections) {
              // Section Header
              widgets.add(
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(6, 6, 6, 4),
                  child: pw.Text(
                    section.sectionTitle.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _parsePdfColor(section.sectionColor),
                    ),
                  ),
                ),
              );

              // Line Items
              for (final item in section.items) {
                widgets.add(_buildPdfRow(item.label, item.currentAmount, item.previousAmount, item.percentChange));
              }

              // Section Total
              widgets.add(
                _buildPdfTotalRow(
                  section.totalItem.label,
                  section.totalItem.currentAmount,
                  section.totalItem.previousAmount,
                  section.totalItem.percentChange,
                ),
              );

              widgets.add(pw.SizedBox(height: 6));
            }
          } else {
            // Income Section
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(6, 6, 6, 4),
                child: pw.Text(
                  'INCOME',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
              ),
            );
            for (final item in summary.incomeItems) {
              widgets.add(_buildPdfRow(item.label, item.currentAmount, item.previousAmount, item.percentChange));
            }
            widgets.add(
              _buildPdfTotalRow(
                summary.totalIncomeItem.label,
                summary.totalIncomeItem.currentAmount,
                summary.totalIncomeItem.previousAmount,
                summary.totalIncomeItem.percentChange,
              ),
            );

            widgets.add(pw.SizedBox(height: 6));

            // Expense Section
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(6, 6, 6, 4),
                child: pw.Text(
                  'EXPENSES',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                ),
              ),
            );
            for (final item in summary.expenseItems) {
              widgets.add(_buildPdfRow(item.label, item.currentAmount, item.previousAmount, item.percentChange));
            }
            widgets.add(
              _buildPdfTotalRow(
                summary.totalExpenseItem.label,
                summary.totalExpenseItem.currentAmount,
                summary.totalExpenseItem.previousAmount,
                summary.totalExpenseItem.percentChange,
              ),
            );

            widgets.add(pw.SizedBox(height: 8));
          }

          // Net Profit Banner Box
          final net = summary.netProfitItem;
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 6),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.green300, width: 1),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      net.label.isNotEmpty ? net.label.toUpperCase() : 'NET PROFIT',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Rs. ${_formatNumber(net.currentAmount)}',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Rs. ${_formatNumber(net.previousAmount)}',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '${net.percentChange > 0 ? "+" : ""}${net.percentChange.toStringAsFixed(2)}%',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfRow(String label, double current, double previous, double change) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'Rs. ${_formatNumber(current)}',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'Rs. ${_formatNumber(previous)}',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '${change > 0 ? "+" : ""}${change.toStringAsFixed(2)}%',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: change >= 0 ? PdfColors.green700 : PdfColors.red700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfTotalRow(String label, double current, double previous, double change) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'Rs. ${_formatNumber(current)}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'Rs. ${_formatNumber(previous)}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '${change > 0 ? "+" : ""}${change.toStringAsFixed(2)}%',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: change >= 0 ? PdfColors.green800 : PdfColors.red800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _generateCsv(
    FinancialStatementsSummaryData summary,
    FinancialStatementFilterState filter,
  ) {
    final rows = <String>[];
    rows.add('"${summary.companyName.toUpperCase()} - ${filter.reportTypeLabel.toUpperCase()}"');
    rows.add('"Period: ${filter.dateRangeLabel}"');
    rows.add('"Currency: INR (₹)"');
    rows.add('"Generated: ${DateTime.now().toIso8601String()}"');
    rows.add('');
    rows.add('"Section","Particulars","Current Period (₹)","Previous Period (₹)","% Change"');

    if (summary.sections.isNotEmpty) {
      for (final sec in summary.sections) {
        rows.add('"--- ${sec.sectionTitle} ---","","","",""');
        for (final it in sec.items) {
          rows.add(
            '"${sec.sectionTitle}","${it.label}","${it.currentAmount}","${it.previousAmount}","${it.percentChange > 0 ? "+" : ""}${it.percentChange.toStringAsFixed(2)}%"',
          );
        }
        rows.add(
          '"${sec.sectionTitle}","${sec.totalItem.label}","${sec.totalItem.currentAmount}","${sec.totalItem.previousAmount}","${sec.totalItem.percentChange > 0 ? "+" : ""}${sec.totalItem.percentChange.toStringAsFixed(2)}%"',
        );
        rows.add('');
      }
    } else {
      rows.add('"--- INCOME ---","","","",""');
      for (final it in summary.incomeItems) {
        rows.add(
          '"INCOME","${it.label}","${it.currentAmount}","${it.previousAmount}","${it.percentChange > 0 ? "+" : ""}${it.percentChange.toStringAsFixed(2)}%"',
        );
      }
      rows.add(
        '"INCOME","${summary.totalIncomeItem.label}","${summary.totalIncomeItem.currentAmount}","${summary.totalIncomeItem.previousAmount}","${summary.totalIncomeItem.percentChange > 0 ? "+" : ""}${summary.totalIncomeItem.percentChange.toStringAsFixed(2)}%"',
      );
      rows.add('');

      rows.add('"--- EXPENSES ---","","","",""');
      for (final it in summary.expenseItems) {
        rows.add(
          '"EXPENSES","${it.label}","${it.currentAmount}","${it.previousAmount}","${it.percentChange > 0 ? "+" : ""}${it.percentChange.toStringAsFixed(2)}%"',
        );
      }
      rows.add(
        '"EXPENSES","${summary.totalExpenseItem.label}","${summary.totalExpenseItem.currentAmount}","${summary.totalExpenseItem.previousAmount}","${summary.totalExpenseItem.percentChange > 0 ? "+" : ""}${summary.totalExpenseItem.percentChange.toStringAsFixed(2)}%"',
      );
      rows.add('');
    }

    final net = summary.netProfitItem;
    rows.add(
      '"SUMMARY","${net.label}","${net.currentAmount}","${net.previousAmount}","${net.percentChange > 0 ? "+" : ""}${net.percentChange.toStringAsFixed(2)}%"',
    );

    return rows.join('\n');
  }

  static PdfColor _parsePdfColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return PdfColors.blueGrey800;
    try {
      final hex = colorStr.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return PdfColor.fromHex(hex);
      }
    } catch (_) {}
    return PdfColors.blueGrey800;
  }

  static String _formatNumber(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final dec = parts[1];

    if (whole.length <= 3) {
      return '$whole.$dec';
    }

    final lastThree = whole.substring(whole.length - 3);
    final otherNumbers = whole.substring(0, whole.length - 3);

    final formattedOther = otherNumbers.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '$formattedOther,$lastThree.$dec';
  }

  static String _sanitize(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
