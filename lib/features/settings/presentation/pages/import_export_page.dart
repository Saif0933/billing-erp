import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class ImportExportPage extends ConsumerStatefulWidget {
  const ImportExportPage({super.key});

  @override
  ConsumerState<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends ConsumerState<ImportExportPage> {
  String _selectedImportEntity = 'Customer';
  String? _uploadedFilename;
  bool _isValidating = false;
  bool _validationComplete = false;

  int _totalRows = 0;
  int _validRows = 0;
  int _errorRows = 0;
  List<Map<String, String>> _previewData = [];

  void _simulateUploadAndValidate() async {
    setState(() {
      _isValidating = true;
      _uploadedFilename =
          'bunny_${_selectedImportEntity.toLowerCase()}_import.csv';
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isValidating = false;
        _validationComplete = true;

        if (_selectedImportEntity == 'Customer') {
          _totalRows = 4;
          _validRows = 3;
          _errorRows = 1;
          _previewData = [
            {
              'row': '1',
              'name': 'Aditya Birla Ltd',
              'mobile': '9890123456',
              'gstin': '27AADCB1234F1Z0',
              'status': 'Valid',
            },
            {
              'row': '2',
              'name': 'Karan Johar',
              'mobile': '9123456780',
              'gstin': '',
              'status': 'Valid',
            },
            {
              'row': '3',
              'name': 'Anonymous Buyer',
              'mobile': '12345',
              'gstin': 'invalid_gst',
              'status': 'Error: Invalid Mobile & GSTIN format',
            },
            {
              'row': '4',
              'name': 'Indore Agri Corp',
              'mobile': '9900990099',
              'gstin': '23AAAAA1234A1Z9',
              'status': 'Valid',
            },
          ];
        } else {
          _totalRows = 3;
          _validRows = 2;
          _errorRows = 1;
          _previewData = [
            {
              'row': '1',
              'name': 'Organic Rice Bags (20kg)',
              'code': 'RCE20K',
              'price': '1500.0',
              'status': 'Valid',
            },
            {
              'row': '2',
              'name': 'Invalid Item Name Empty',
              'code': '',
              'price': '-50.0',
              'status': 'Error: Name/Code missing, Negative Price',
            },
            {
              'row': '3',
              'name': 'Refined Sunflower Oil (5L)',
              'code': 'OIL5L',
              'price': '680.0',
              'status': 'Valid',
            },
          ];
        }
      });
    }
  }

  void _commitImport() async {
    final notifier = ref.read(billingRepositoryProvider.notifier);

    if (_selectedImportEntity == 'Customer') {
      await notifier.addCustomer(
        const Customer(
          id: 'imp_cust_1',
          name: 'Aditya Birla Ltd',
          type: 'Corporate',
          gstin: '27AADCB1234F1Z0',
          pan: 'AADCB1234F',
          mobile: '9890123456',
          email: 'billing@birla.com',
          billingAddress: 'Mumbai Head Office',
          shippingAddress: 'Mumbai Head Office',
          state: 'Maharashtra',
          stateCode: '27',
          creditLimit: 200000.0,
          creditPeriod: 45,
          openingBalance: 0.0,
          currentBalance: 0.0,
          customerGroup: 'Corporate',
          notes: 'Imported customer',
          isRegistered: true,
        ),
      );
      await notifier.addCustomer(
        const Customer(
          id: 'imp_cust_2',
          name: 'Karan Johar',
          type: 'Retail',
          gstin: '',
          pan: '',
          mobile: '9123456780',
          email: 'karan@gmail.com',
          billingAddress: 'Bandra, Mumbai',
          shippingAddress: 'Bandra, Mumbai',
          state: 'Maharashtra',
          stateCode: '27',
          creditLimit: 0.0,
          creditPeriod: 0,
          openingBalance: 0.0,
          currentBalance: 0.0,
          customerGroup: 'Retail',
          notes: 'Imported customer',
          isRegistered: false,
        ),
      );
    } else {
      await notifier.addProduct(
        const Product(
          id: 'imp_prod_1',
          name: 'Organic Rice Bags (20kg)',
          code: 'RCE20K',
          sku: 'RCE-020',
          barcode: '8901234567899',
          hsnCode: '1006',
          primaryUnit: 'Bag',
          secondaryUnit: 'Kg',
          gstRate: 5.0,
          purchasePrice: 1200.0,
          sellingPrice: 1500.0,
          mrp: 1800.0,
          wholesalePrice: 1400.0,
          minStockLevel: 5.0,
          openingStock: 20.0,
          currentStock: 20.0,
          batchNumber: 'B-IMP-01',
          expiryDate: '2027-12-31',
          serialNumber: '',
          category: 'Grocery',
          brand: 'Bunny Farms',
        ),
      );
    }

    if (mounted) {
      setState(() {
        _uploadedFilename = null;
        _validationComplete = false;
      });
      AppFeedback.showSnackbar(
        context,
        message: 'Valid items successfully committed to database!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryText =
        isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final mutedText =
        isDark ? AppColors.textDarkMuted : AppColors.textLightMuted;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    Widget panel({required Widget child}) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: child,
      );
    }

    final importPanel = panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('IMPORT', mutedText),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<String>(
            label: 'Entity group',
            value: _selectedImportEntity,
            items: const [
              DropdownMenuItem(
                value: 'Customer',
                child: Text('Customers Directory'),
              ),
              DropdownMenuItem(
                value: 'Product',
                child: Text('Products Catalogue'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedImportEntity = val;
                  _validationComplete = false;
                  _uploadedFilename = null;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Download Sample Template',
            icon: Icons.download_outlined,
            type: AppButtonType.secondary,
            onPressed: () {
              AppFeedback.showSnackbar(
                context,
                message: 'Sample $_selectedImportEntity template downloaded!',
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _simulateUploadAndValidate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF34D399).withValues(alpha: 0.35)
                        : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadedFilename == null
                          ? 'Tap to upload CSV and validate'
                          : 'Tap to re-upload and validate',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _uploadedFilename ?? 'Supports .csv and Excel templates',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: mutedText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final exportPanel = panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('EXPORT', mutedText),
          const SizedBox(height: 6),
          Text(
            'Download current master data as CSV for backup or migration.',
            style: AppTypography.bodySmall.copyWith(color: mutedText),
          ),
          const SizedBox(height: AppSpacing.md),
          _ExportRow(
            icon: Icons.people_outline,
            title: 'Customers',
            subtitle: 'Directory, GSTIN and contacts',
            isDark: isDark,
            onTap: () {
              AppFeedback.showSnackbar(
                context,
                message: 'Customers CSV exported.',
              );
            },
          ),
          const SizedBox(height: 8),
          _ExportRow(
            icon: Icons.inventory_2_outlined,
            title: 'Products',
            subtitle: 'Catalogue, HSN and pricing',
            isDark: isDark,
            onTap: () {
              AppFeedback.showSnackbar(
                context,
                message: 'Products CSV exported.',
              );
            },
          ),
        ],
      ),
    );

    final validationPanel = panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('VALIDATION', mutedText),
          const SizedBox(height: AppSpacing.md),
          if (_isValidating)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    'Parsing CSV and running schema checks…',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: mutedText),
                  ),
                ],
              ),
            )
          else if (_validationComplete)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Total',
                        value: '$_totalRows',
                        color: AppColors.info,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        label: 'Valid',
                        value: '$_validRows',
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        label: 'Errors',
                        value: '$_errorRows',
                        color: AppColors.error,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (_errorRows > 0)
                      TextButton.icon(
                        icon: const Icon(
                          Icons.warning_amber_outlined,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        label: const Text(
                          'Download Log',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          AppFeedback.showSnackbar(
                            context,
                            message: 'Downloaded validation error log.',
                          );
                        },
                      ),
                    AppButton(
                      label: 'Commit Rows',
                      icon: Icons.check,
                      onPressed: _commitImport,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel('PREVIEW', mutedText),
                const SizedBox(height: AppSpacing.sm),
                ...List.generate(_previewData.length, (index) {
                  final row = _previewData[index];
                  final isErr = (row['status'] ?? '').startsWith('Error');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isErr
                              ? AppColors.error.withValues(alpha: 0.35)
                              : border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: (isErr
                                    ? AppColors.error
                                    : AppColors.success)
                                .withValues(alpha: 0.15),
                            child: Text(
                              row['row'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isErr
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row['name'] ?? '',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  row['code'] ?? row['mobile'] ?? '',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: mutedText),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isErr
                                            ? AppColors.error
                                            : AppColors.success)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isErr ? 'ERROR' : 'VALID',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isErr
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                                if (isErr) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    row['status'] ?? '',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(Icons.fact_check_outlined, size: 36, color: mutedText),
                  const SizedBox(height: 10),
                  Text(
                    'Download the sample template, populate data, and upload to start validation.',
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.bodyMedium.copyWith(color: mutedText),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(
                    context: context,
                    isDark: isDark,
                    secondaryText: secondaryText,
                  ),
                  const SizedBox(height: 18),
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        importPanel,
                        const SizedBox(height: 14),
                        exportPanel,
                        const SizedBox(height: 14),
                        validationPanel,
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              importPanel,
                              const SizedBox(height: 14),
                              exportPanel,
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(flex: 6, child: validationPanel),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required bool isDark,
    required Color secondaryText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Import & Export',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Migrate master data with CSV templates, dry-run validation, and commit',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, Color mutedText) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: mutedText,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _ExportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_outlined,
              size: 18,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
