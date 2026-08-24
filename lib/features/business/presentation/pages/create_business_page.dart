import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/business_provider.dart';

class CreateBusinessPage extends ConsumerStatefulWidget {
  const CreateBusinessPage({super.key});

  @override
  ConsumerState<CreateBusinessPage> createState() => _CreateBusinessPageState();
}

class _CreateBusinessPageState extends ConsumerState<CreateBusinessPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gstinController = TextEditingController();
  String? _selectedType = 'Retail';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await ref.read(businessProvider.notifier).createBusiness(
            name: _nameController.text,
            type: _selectedType ?? 'Retail',
            gstNumber: _gstinController.text.isNotEmpty ? _gstinController.text : 'N/A',
          );
      setState(() => _isLoading = false);
      if (mounted) {
        AppFeedback.showSnackbar(context, message: 'New business created successfully!');
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessTypes = ['Service', 'Retail', 'Trading', 'Wholesale', 'Manufacturing'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Business'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Business Profile',
                  style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Set up an additional legal entity to manage transactions.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Business Name *',
                  hintText: 'e.g. Acme Retailers',
                  controller: _nameController,
                  validator: (val) => val == null || val.isEmpty ? 'Business name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdownField<String>(
                  label: 'Business Type *',
                  value: _selectedType,
                  items: businessTypes.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                const SizedBox(height: AppSpacing.md),
                AppGstinField(
                  label: 'GSTIN (Optional)',
                  controller: _gstinController,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Save & Switch',
                  onPressed: _handleSave,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Cancel',
                  onPressed: () => context.pop(),
                  type: AppButtonType.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
