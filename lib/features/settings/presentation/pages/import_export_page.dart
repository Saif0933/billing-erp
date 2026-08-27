import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
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

  // Validation stats
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
      // Add valid mock rows
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
      // Add valid products
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

    final leftConfigCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(
                Icons.cloud_upload_outlined,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Excel/CSV Import Panel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 24),
          AppDropdownField<String>(
            label: 'Import Entity Group *',
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
          const SizedBox(height: AppSpacing.lg),
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
          if (_uploadedFilename != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _uploadedFilename!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          AppButton(
            label: _uploadedFilename == null
                ? 'Upload File & Validate'
                : 'Re-upload & Validate',
            icon: Icons.cloud_upload_outlined,
            onPressed: _simulateUploadAndValidate,
          ),
        ],
      ),
    );

    final rightValidationCard = Column(
      children: [
        if (_isValidating)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade100,
              ),
            ),
            child: const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 16),
                    Text(
                      'Parsing CSV contents and executing schema validation checks...',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_validationComplete)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.analytics_outlined,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Dry-Run Validation Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildValStat('Total Rows', _totalRows, Colors.blue),
                        _buildValStat('Valid Rows', _validRows, Colors.green),
                        _buildValStat('Error Rows', _errorRows, Colors.red),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_errorRows > 0)
                          TextButton.icon(
                            icon: const Icon(
                              Icons.warning,
                              color: Colors.amber,
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
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Commit Rows',
                          icon: Icons.check,
                          onPressed: _commitImport,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.preview_outlined,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Import Data Preview Grid',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    AppTable<Map<String, String>>(
                      items: _previewData,
                      emptyMessage: 'No preview rows.',
                      columns: [
                        TableColumnSpec<Map<String, String>>(
                          label: 'Row',
                          cellBuilder: (row) => Text(row['row'] ?? ''),
                        ),
                        TableColumnSpec<Map<String, String>>(
                          label: 'Name',
                          flex: 2,
                          cellBuilder: (row) => Text(
                            row['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TableColumnSpec<Map<String, String>>(
                          label: 'Identifier / SKU',
                          cellBuilder: (row) =>
                              Text(row['code'] ?? row['mobile'] ?? ''),
                        ),
                        TableColumnSpec<Map<String, String>>(
                          label: 'Validation Status',
                          flex: 2,
                          cellBuilder: (row) {
                            final isErr = (row['status'] ?? '').startsWith(
                              'Error',
                            );
                            return Text(
                              row['status'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isErr ? Colors.red : Colors.green,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade100,
              ),
            ),
            child: const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Download the sample template, populate data, and upload the file to start validation.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );

    final contentLayout = Responsive.isMobile(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftConfigCard,
              const SizedBox(height: 16),
              rightValidationCard,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: leftConfigCard),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: rightValidationCard),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Data Import / Export Wizard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: contentLayout,
      ),
    );
  }

  Widget _buildValStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
