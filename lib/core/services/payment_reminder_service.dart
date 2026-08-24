import '../models/billing_models.dart';

class PaymentReminderService {
  static List<Invoice> getOverdueInvoices(List<Invoice> invoices) {
    final now = DateTime.now();
    return invoices.where((inv) {
      if (inv.status != InvoiceStatus.confirmed && inv.status != InvoiceStatus.partiallyPaid) {
        return false;
      }
      // Assuming a default credit period of 30 days for calculation if due date is not stored
      final dueDate = inv.invoiceDate.add(const Duration(days: 30));
      return dueDate.isBefore(now) && inv.balanceAmount > 0;
    }).toList();
  }

  static String generateReminderMessage(Invoice invoice, String channel) {
    final dueDate = invoice.invoiceDate.add(const Duration(days: 30));
    final daysOverdue = DateTime.now().difference(dueDate).inDays;

    final baseMessage = 'Dear ${invoice.customerName},\n\n'
        'This is a friendly reminder that payment for Invoice ${invoice.invoiceNumber} '
        'dated ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year} '
        'of amount ₹${invoice.grandTotal.toStringAsFixed(2)} is now overdue by $daysOverdue days. '
        'Remaining balance: ₹${invoice.balanceAmount.toStringAsFixed(2)}.\n\n'
        'Please complete payment at your earliest convenience. Thank you!';

    if (channel == 'WhatsApp') {
      return '*Overdue Payment Reminder*\n\n$baseMessage';
    }
    return baseMessage;
  }
}
