import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class InvoiceCustomizationPage extends ConsumerStatefulWidget {
  const InvoiceCustomizationPage({super.key});

  @override
  ConsumerState<InvoiceCustomizationPage> createState() =>
      _InvoiceCustomizationPageState();
}

class _InvoiceCustomizationPageState
    extends ConsumerState<InvoiceCustomizationPage> {
  final _primaryColorController = TextEditingController();
  final _fontController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _upiController = TextEditingController();
  final _signatoryController = TextEditingController();
  final _termsController = TextEditingController();
  final _footerController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _primaryColorController.dispose();
    _fontController.dispose();
    _bankNameController.dispose();
    _bankAccController.dispose();
    _bankIfscController.dispose();
    _upiController.dispose();
    _signatoryController.dispose();
    _termsController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _initFields(InvoiceBrandingConfig config) {
    if (_initialized) return;
    _primaryColorController.text = config.primaryColor;
    _fontController.text = config.fontName;
    _bankNameController.text = config.bankName;
    _bankAccController.text = config.bankAccountNumber;
    _bankIfscController.text = config.bankIfsc;
    _upiController.text = config.upiId;
    _signatoryController.text = config.authorizedSignatoryName;
    _termsController.text = config.termsConditions;
    _footerController.text = config.footerText;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final brandingConfig = billingState.invoiceBrandingConfig;

    _initFields(brandingConfig);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color brandingColor = const Color(0xFF2E7D32);
    try {
      if (_primaryColorController.text.isNotEmpty &&
          _primaryColorController.text.startsWith('#')) {
        brandingColor = Color(int.parse(
            _primaryColorController.text.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}

    final settingsEditor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Branding & Style Parameters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.palette_outlined,
                      color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Branding & Style Parameters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Branding Primary Color Code *',
                      controller: _primaryColorController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: 'Typography Font *',
                      controller: _fontController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Payment Details Allocation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.account_balance_outlined,
                      color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Payment Details Allocation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Bank Account Name',
                      controller: _bankNameController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: 'Account Number',
                      controller: _bankAccController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'IFSC Code',
                      controller: _bankIfscController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: 'UPI QR ID String',
                      controller: _upiController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Signatures & Legal Disclaimers
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.history_edu_outlined,
                      color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Signatures & Legal Disclaimers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              AppTextField(
                label: 'Authorized Signatory Name',
                controller: _signatoryController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Terms & Conditions Footer Disclaimer',
                controller: _termsController,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Footer Greeting Text',
                controller: _footerController,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Apply Template Branding Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          onPressed: () async {
            final config = InvoiceBrandingConfig(
              logoUrl: '',
              primaryColor: _primaryColorController.text,
              fontName: _fontController.text,
              bankName: _bankNameController.text,
              bankAccountNumber: _bankAccController.text,
              bankIfsc: _bankIfscController.text,
              upiId: _upiController.text,
              authorizedSignatoryName: _signatoryController.text,
              termsConditions: _termsController.text,
              footerText: _footerController.text,
            );

            await ref
                .read(billingRepositoryProvider.notifier)
                .updateInvoiceBranding(config);
            if (context.mounted) {
              AppFeedback.showSnackbar(context,
                  message: 'Invoice branding template layout updated!');
            }
          },
        ),
      ],
    );

    final visualizerCanvas = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: 380,
          height: 520,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Simulated Logo Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: brandingColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Icon(Icons.business_center,
                            color: brandingColor, size: 24)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('TAX INVOICE',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      Text('INV-2026-0001',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(thickness: 1.5),
              const SizedBox(height: 6),
              // Simulated bill to
              const Text('BILL TO:',
                  style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              const Text('Acme Corporates',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const Text('101 Industrial Area, Mumbai',
                  style: TextStyle(fontSize: 9, color: Colors.black54)),
              const SizedBox(height: 12),
              // Simulated item table
              Container(
                color: brandingColor.withValues(alpha: 0.08),
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Item Particulars',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text('Amount (₹)',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Organic Wheat Flour x10 Bags',
                        style: TextStyle(fontSize: 9, color: Colors.black87)),
                    Text('₹2,200.00',
                        style: TextStyle(fontSize: 9, color: Colors.black87)),
                  ],
                ),
              ),
              const Spacer(),
              // Payment Details
              const Divider(),
              const Text('PAYMENT DETAILS:',
                  style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              Text('Bank: ${_bankNameController.text}',
                  style: const TextStyle(fontSize: 9, color: Colors.black87)),
              Text(
                  'Account: ${_bankAccController.text} | IFSC: ${_bankIfscController.text}',
                  style: const TextStyle(fontSize: 9, color: Colors.black87)),
              Text('UPI: ${_upiController.text}',
                  style: const TextStyle(fontSize: 9, color: Colors.black87)),
              const SizedBox(height: 8),
              // Disclaimer & footer
              Text('Terms: ${_termsController.text}',
                  style: const TextStyle(fontSize: 7, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('Authorized Signatory: ${_signatoryController.text}',
                  style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.right),
              const Divider(),
              Text(_footerController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87)),
            ],
          ),
        ),
      ),
    );

    final contentLayout = Responsive.isMobile(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              settingsEditor,
              const SizedBox(height: 16),
              visualizerCanvas,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: settingsEditor),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: visualizerCanvas),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Templates & Branding')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: contentLayout,
      ),
    );
  }
}
