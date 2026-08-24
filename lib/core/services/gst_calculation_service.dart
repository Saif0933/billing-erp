class GstCalculationResult {
  final double taxableValue;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalTax;
  final double grandTotal;

  const GstCalculationResult({
    required this.taxableValue,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.cessAmount,
    required this.totalTax,
    required this.grandTotal,
  });
}

class GstCalculationService {
  GstCalculationService._();

  static GstCalculationResult calculate({
    required double quantity,
    required double rate,
    required double discountPercentage,
    required double gstRate, // overall percentage (e.g., 18.0)
    required String businessStateCode,
    required String placeOfSupplyStateCode,
    required String customerGstType, // "Regular", "Composition", "Unregistered", "Exempt", "Nil Rated", "Non-GST", "Export"
    double cessPercentage = 0.0,
  }) {
    final double grossAmount = quantity * rate;
    final double discountAmount = grossAmount * (discountPercentage / 100.0);
    final double taxableValue = grossAmount - discountAmount;

    // Tax treatment checks
    final bool isExempt = customerGstType == 'Exempt' || customerGstType == 'Nil Rated' || customerGstType == 'Non-GST';
    final bool isExport = customerGstType == 'Export';

    double cgstR = 0.0;
    double sgstR = 0.0;
    double igstR = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;
    double cess = 0.0;

    if (!isExempt) {
      if (isExport) {
        // Exports can be zero-rated or have IGST (assuming zero-rated by default or standard IGST)
        igstR = gstRate;
        igst = taxableValue * (igstR / 100.0);
      } else if (businessStateCode.trim() == placeOfSupplyStateCode.trim()) {
        // Same State: CGST + SGST
        cgstR = gstRate / 2.0;
        sgstR = gstRate / 2.0;
        cgst = taxableValue * (cgstR / 100.0);
        sgst = taxableValue * (sgstR / 100.0);
      } else {
        // Inter State: IGST
        igstR = gstRate;
        igst = taxableValue * (igstR / 100.0);
      }

      if (cessPercentage > 0.0) {
        cess = taxableValue * (cessPercentage / 100.0);
      }
    }

    final double totalTax = cgst + sgst + igst + cess;
    final double grandTotal = taxableValue + totalTax;

    return GstCalculationResult(
      taxableValue: double.parse(taxableValue.toStringAsFixed(2)),
      cgstRate: cgstR,
      sgstRate: sgstR,
      igstRate: igstR,
      cgstAmount: double.parse(cgst.toStringAsFixed(2)),
      sgstAmount: double.parse(sgst.toStringAsFixed(2)),
      igstAmount: double.parse(igst.toStringAsFixed(2)),
      cessAmount: double.parse(cess.toStringAsFixed(2)),
      totalTax: double.parse(totalTax.toStringAsFixed(2)),
      grandTotal: double.parse(grandTotal.toStringAsFixed(2)),
    );
  }
}
