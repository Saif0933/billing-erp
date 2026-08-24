import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../features/business/data/models/business_model.dart';
import '../models/billing_models.dart';

class InvoicePdfService {
  InvoicePdfService._();

  static Future<Uint8List> generate(Invoice invoice, BusinessModel business) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        business.name.toUpperCase(),
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(business.legalName.isNotEmpty ? business.legalName : business.name),
                      if (business.gstNumber.isNotEmpty && business.gstNumber != 'N/A')
                        pw.Text('GSTIN: ${business.gstNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(business.address),
                      pw.Text('Email: ${business.email} | Mobile: ${business.mobile}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        invoice.isCreditNote ? 'CREDIT NOTE' : 'TAX INVOICE',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Invoice No: ${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}'),
                      pw.Text('Place of Supply: ${invoice.placeOfSupply}'),
                      if (invoice.isCreditNote)
                        pw.Text('Orig Inv: ${invoice.originalInvoiceId}', style: pw.TextStyle(color: PdfColors.red)),
                    ],
                  ),
                ],
              ),

              pw.Divider(thickness: 1, height: 24),

              // Billed To / Shipped To
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILLED TO:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.billingAddress),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SHIPPED TO:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.shippingAddress),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Table header
              pw.TableHelper.fromTextArray(
                headers: ['Sl.', 'Item Description', 'HSN/SAC', 'Qty', 'Rate', 'Disc%', 'Taxable', 'GST%', 'Total'],
                data: List.generate(invoice.items.length, (idx) {
                  final item = invoice.items[idx];
                  final gstVal = item.cgst + item.sgst + item.igst;
                  final totalVal = item.taxableValue + gstVal;
                  return [
                    '${idx + 1}',
                    item.name,
                    item.hsnSac,
                    item.quantity.toStringAsFixed(1),
                    '₹${item.rate.toStringAsFixed(2)}',
                    '${item.discountPercentage.toStringAsFixed(0)}%',
                    '₹${item.taxableValue.toStringAsFixed(2)}',
                    '${item.gstRate.toStringAsFixed(0)}%',
                    '₹${totalVal.toStringAsFixed(2)}',
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                  7: pw.Alignment.center,
                  8: pw.Alignment.centerRight,
                },
              ),

              pw.SizedBox(height: 20),

              // Summary values
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bank Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('Bank: ${business.bankName.isNotEmpty ? business.bankName : "Acme State Bank"}'),
                        pw.Text('A/C: ${business.bankAccountNo.isNotEmpty ? business.bankAccountNo : "XXXXXXXX1234"}'),
                        pw.Text('IFSC: ${business.bankIfsc.isNotEmpty ? business.bankIfsc : "ASB0001234"}'),
                        pw.Text('UPI ID: ${business.upiId.isNotEmpty ? business.upiId : "acme@upi"}'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryRow('Taxable Amount:', '₹${invoice.taxableAmount.toStringAsFixed(2)}'),
                        if (invoice.cgst > 0) _buildSummaryRow('CGST:', '₹${invoice.cgst.toStringAsFixed(2)}'),
                        if (invoice.sgst > 0) _buildSummaryRow('SGST:', '₹${invoice.sgst.toStringAsFixed(2)}'),
                        if (invoice.igst > 0) _buildSummaryRow('IGST:', '₹${invoice.igst.toStringAsFixed(2)}'),
                        if (invoice.cess > 0) _buildSummaryRow('Cess:', '₹${invoice.cess.toStringAsFixed(2)}'),
                        _buildSummaryRow('Round Off:', '₹${invoice.roundOff.toStringAsFixed(2)}'),
                        pw.Divider(thickness: 1),
                        _buildSummaryRow(
                          'Grand Total:',
                          '₹${invoice.grandTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Amount in Words: ${_convertToWords(invoice.grandTotal)}',
                          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Row _buildSummaryRow(String label, String value, {pw.TextStyle? style}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }

  static Future<void> share(Invoice invoice, BusinessModel business) async {
    final pdfBytes = await generate(invoice, business);
    final filename = '${invoice.invoiceNumber.replaceAll("/", "_")}.pdf';
    
    await Share.shareXFiles(
      [
        XFile.fromData(
          pdfBytes,
          name: filename,
          mimeType: 'application/pdf',
        ),
      ],
      subject: 'Invoice ${invoice.invoiceNumber} from ${business.name}',
      text: 'Hello, please find attached invoice ${invoice.invoiceNumber} for your reference.',
    );
  }

  static String _convertToWords(double amount) {
    // Simple helper to convert invoice amount into English words (Indian numbering style format)
    int amt = amount.round();
    if (amt == 0) return 'Zero Rupees Only';

    final Map<int, String> units = {
      0: '', 1: 'One', 2: 'Two', 3: 'Three', 4: 'Four', 5: 'Five', 6: 'Six', 7: 'Seven', 8: 'Eight', 9: 'Nine',
      10: 'Ten', 11: 'Eleven', 12: 'Twelve', 13: 'Thirteen', 14: 'Fourteen', 15: 'Fifteen', 16: 'Sixteen',
      17: 'Seventeen', 18: 'Eighteen', 19: 'Nineteen'
    };

    final Map<int, String> tens = {
      20: 'Twenty', 30: 'Thirty', 40: 'Forty', 50: 'Fifty', 60: 'Sixty', 70: 'Seventy', 80: 'Eighty', 90: 'Ninety'
    };

    String numToWords(int n) {
      if (n < 20) return units[n]!;
      if (n < 100) return '${tens[(n ~/ 10) * 10]!} ${units[n % 10]!}';
      if (n < 1000) return '${units[n ~/ 100]!} Hundred ${numToWords(n % 100)}';
      if (n < 100000) return '${numToWords(n ~/ 1000)} Thousand ${numToWords(n % 1000)}';
      if (n < 10000000) return '${numToWords(n ~/ 100000)} Lakh ${numToWords(n % 100000)}';
      return '${numToWords(n ~/ 10000000)} Crore ${numToWords(n % 10000000)}';
    }

    return '${numToWords(amt)} Rupees Only';
  }
}
