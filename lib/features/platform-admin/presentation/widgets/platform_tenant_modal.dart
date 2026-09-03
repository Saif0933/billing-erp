import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/platform_admin_models.dart';
import '../providers/platform_admin_provider.dart';

class PlatformTenantModal extends ConsumerStatefulWidget {
  final OrganizationTenant? tenant;

  const PlatformTenantModal({super.key, this.tenant});

  static void show(BuildContext context, {OrganizationTenant? tenant}) {
    showDialog(
      context: context,
      builder: (ctx) => PlatformTenantModal(tenant: tenant),
    );
  }

  @override
  ConsumerState<PlatformTenantModal> createState() => _PlatformTenantModalState();
}

class _PlatformTenantModalState extends ConsumerState<PlatformTenantModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _domainController;
  late TextEditingController _gstinController;
  late TextEditingController _contactPersonController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _maxUsersController;
  late TextEditingController _storageLimitController;
  late String _selectedPlan;
  late TenantStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    _nameController = TextEditingController(text: t?.name ?? '');
    _codeController = TextEditingController(text: t?.code ?? '');
    _domainController = TextEditingController(text: t?.domain ?? '');
    _gstinController = TextEditingController(text: t?.gstin ?? '');
    _contactPersonController = TextEditingController(text: t?.contactPerson ?? '');
    _emailController = TextEditingController(text: t?.contactEmail ?? '');
    _phoneController = TextEditingController(text: t?.contactPhone ?? '');
    _maxUsersController = TextEditingController(text: (t?.maxUsersLimit ?? 15).toString());
    _storageLimitController = TextEditingController(text: (t?.storageLimitGb ?? 25.0).toString());
    _selectedPlan = t?.planName ?? 'Growth';
    _selectedStatus = t?.status ?? TenantStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _domainController.dispose();
    _gstinController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _maxUsersController.dispose();
    _storageLimitController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final isNew = widget.tenant == null;
    final notifier = ref.read(platformAdminProvider.notifier);

    final updatedTenant = OrganizationTenant(
      id: widget.tenant?.id ?? 'org_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      domain: _domainController.text.trim().toLowerCase(),
      gstin: _gstinController.text.trim().toUpperCase(),
      contactPerson: _contactPersonController.text.trim(),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      planId: _selectedPlan == 'Enterprise' ? 'plan_ent' : (_selectedPlan == 'Growth' ? 'plan_growth' : 'plan_starter'),
      planName: _selectedPlan,
      status: _selectedStatus,
      monthlySpend: _selectedPlan == 'Enterprise' ? 6999.0 : (_selectedPlan == 'Growth' ? 2499.0 : 999.0),
      totalInvoices: widget.tenant?.totalInvoices ?? 0,
      activeUsersCount: widget.tenant?.activeUsersCount ?? 1,
      maxUsersLimit: int.tryParse(_maxUsersController.text) ?? 15,
      storageUsedGb: widget.tenant?.storageUsedGb ?? 0.1,
      storageLimitGb: double.tryParse(_storageLimitController.text) ?? 25.0,
      createdAt: widget.tenant?.createdAt ?? DateTime.now(),
      renewalDate: widget.tenant?.renewalDate ?? DateTime.now().add(const Duration(days: 30)),
    );

    if (isNew) {
      notifier.addTenant(updatedTenant);
      AppFeedback.showSnackbar(context, message: 'Organization "${updatedTenant.name}" created successfully!');
    } else {
      notifier.updateTenant(updatedTenant);
      AppFeedback.showSnackbar(context, message: 'Organization "${updatedTenant.name}" updated successfully!');
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNew = widget.tenant == null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.domain_add, color: Color(0xFF4F46E5), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isNew ? 'Create New Organization' : 'Edit Organization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Name & Code
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Organization Name *',
                          hintText: 'e.g. Acme Corp',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        onChanged: (val) {
                          if (isNew && _codeController.text.isEmpty) {
                            final code = val.replaceAll(RegExp(r'\s+'), '').toUpperCase();
                            if (code.length >= 4) {
                              _codeController.text = code.substring(0, 4);
                            }
                          }
                          if (isNew && _domainController.text.isEmpty) {
                            final sub = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                            _domainController.text = '$sub.billing-erp.in';
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Tenant Code *',
                          hintText: 'e.g. ACME',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Domain & GSTIN
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _domainController,
                        decoration: const InputDecoration(
                          labelText: 'Subdomain URL *',
                          hintText: 'e.g. acme.billing-erp.in',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _gstinController,
                        decoration: const InputDecoration(
                          labelText: 'GSTIN',
                          hintText: '27AABCU9603R1ZM',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Contact Person & Email
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contactPersonController,
                        decoration: const InputDecoration(
                          labelText: 'Primary Admin Name *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Admin Email *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Plan & Status Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPlan,
                        decoration: const InputDecoration(
                          labelText: 'SaaS Plan *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Starter', child: Text('Starter (₹999/mo)')),
                          DropdownMenuItem(value: 'Growth', child: Text('Growth (₹2,499/mo)')),
                          DropdownMenuItem(value: 'Enterprise', child: Text('Enterprise (₹6,999/mo)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPlan = val;
                              if (val == 'Enterprise') {
                                _maxUsersController.text = '100';
                                _storageLimitController.text = '100.0';
                              } else if (val == 'Growth') {
                                _maxUsersController.text = '15';
                                _storageLimitController.text = '25.0';
                              } else {
                                _maxUsersController.text = '3';
                                _storageLimitController.text = '5.0';
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TenantStatus>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Tenant Status *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: TenantStatus.active, child: Text('Active')),
                          DropdownMenuItem(value: TenantStatus.trial, child: Text('Free Trial (14d)')),
                          DropdownMenuItem(value: TenantStatus.suspended, child: Text('Suspended')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Max Users & Storage Limits
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxUsersController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max User Seats',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _storageLimitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Storage Limit (GB)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 18, color: Colors.white),
                      label: Text(
                        isNew ? 'Create Tenant' : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
