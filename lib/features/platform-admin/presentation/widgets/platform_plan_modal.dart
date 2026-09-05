import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/platform_admin_models.dart';
import '../providers/platform_admin_provider.dart';

class PlatformPlanModal extends ConsumerStatefulWidget {
  final PlatformPlan? plan;

  const PlatformPlanModal({super.key, this.plan});

  static void show(BuildContext context, {PlatformPlan? plan}) {
    showDialog(
      context: context,
      builder: (ctx) => PlatformPlanModal(plan: plan),
    );
  }

  @override
  ConsumerState<PlatformPlanModal> createState() => _PlatformPlanModalState();
}

class _PlatformPlanModalState extends ConsumerState<PlatformPlanModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _monthlyPriceController;
  late TextEditingController _yearlyPriceController;
  late TextEditingController _maxUsersController;
  late TextEditingController _maxInvoicesController;
  late TextEditingController _storageLimitController;
  late TextEditingController _newFeatureController;

  late bool _isPopular;
  late Color _selectedColor;
  late List<String> _features;

  final List<Color> _availableColors = const [
    Color(0xFF2563EB), // Blue
    Color(0xFF15803D), // Green
    Color(0xFF6D28D9), // Purple
    Color(0xFF4F46E5), // Indigo
    Color(0xFFD97706), // Amber
    Color(0xFFDC2626), // Red
    Color(0xFF0D9488), // Teal
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameController = TextEditingController(text: p?.name ?? '');
    _taglineController = TextEditingController(text: p?.tagline ?? '');
    _monthlyPriceController =
        TextEditingController(text: (p?.priceMonthly.toInt() ?? 1499).toString());
    _yearlyPriceController =
        TextEditingController(text: (p?.priceYearly.toInt() ?? 14990).toString());
    _maxUsersController =
        TextEditingController(text: (p?.maxUsers ?? 10).toString());
    _maxInvoicesController =
        TextEditingController(text: (p?.maxInvoicesPerMonth ?? 5000).toString());
    _storageLimitController =
        TextEditingController(text: (p?.storageLimitGb ?? 25.0).toString());
    _newFeatureController = TextEditingController();

    _isPopular = p?.isPopular ?? false;
    _selectedColor = p?.themeColor ?? const Color(0xFF4F46E5);
    _features = p?.features != null ? List<String>.from(p!.features) : [
      'Multi-User Team Access',
      'GST Compliant Invoicing',
      'Inventory & Stock Tracking',
      'Cloud Backups & SSL Security',
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _monthlyPriceController.dispose();
    _yearlyPriceController.dispose();
    _maxUsersController.dispose();
    _maxInvoicesController.dispose();
    _storageLimitController.dispose();
    _newFeatureController.dispose();
    super.dispose();
  }

  void _addFeature() {
    final text = _newFeatureController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _features.add(text);
        _newFeatureController.clear();
      });
    }
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final isNew = widget.plan == null;
    final notifier = ref.read(platformAdminProvider.notifier);

    final monthly = double.tryParse(_monthlyPriceController.text.trim()) ?? 0.0;
    final yearly = double.tryParse(_yearlyPriceController.text.trim()) ?? (monthly * 10);
    final maxUsers = int.tryParse(_maxUsersController.text.trim()) ?? 10;
    final maxInvoices = int.tryParse(_maxInvoicesController.text.trim()) ?? 5000;
    final storage = double.tryParse(_storageLimitController.text.trim()) ?? 25.0;

    final planToSave = PlatformPlan(
      id: widget.plan?.id ?? 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      tagline: _taglineController.text.trim().isNotEmpty
          ? _taglineController.text.trim()
          : 'Tailored for growing modern businesses.',
      priceMonthly: monthly,
      priceYearly: yearly,
      maxUsers: maxUsers,
      maxInvoicesPerMonth: maxInvoices,
      storageLimitGb: storage,
      features: _features.isNotEmpty
          ? _features
          : ['Full ERP Access', 'Standard Cloud Backups'],
      isPopular: _isPopular,
      activeTenantsCount: widget.plan?.activeTenantsCount ?? 0,
      themeColor: _selectedColor,
    );

    if (isNew) {
      notifier.createPlan(planToSave);
      AppFeedback.showSnackbar(
        context,
        message: 'Plan "${planToSave.name}" created successfully!',
      );
    } else {
      notifier.updatePlan(planToSave);
      AppFeedback.showSnackbar(
        context,
        message: 'Plan "${planToSave.name}" updated successfully!',
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNew = widget.plan == null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
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
                        color: _selectedColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.stars_rounded, color: _selectedColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isNew ? 'Create New Plan Tier' : 'Edit Plan: ${widget.plan!.name}',
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

                // Plan Name & Tagline
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Plan Name *',
                    hintText: 'e.g. Pro, Scale, Premium',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _taglineController,
                  decoration: const InputDecoration(
                    labelText: 'Tagline / Summary Description',
                    hintText: 'e.g. Best for high-volume retail chains and multi-store setups',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),

                // Pricing Section: Monthly & Yearly
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthlyPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Price (₹) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) return 'Invalid amount';
                          return null;
                        },
                        onChanged: (val) {
                          final m = double.tryParse(val);
                          if (m != null) {
                            _yearlyPriceController.text = (m * 10).toInt().toString();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yearlyPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Yearly Price (₹) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) return 'Invalid amount';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quotas: Max Users, Invoices, Storage
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxUsersController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Users Seats',
                          hintText: 'e.g. 15',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxInvoicesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Invoices / Month',
                          hintText: 'e.g. 5000',
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
                          labelText: 'Storage (GB)',
                          hintText: 'e.g. 25.0',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Popular Toggle & Theme Color
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Most Popular Badge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Highlights this tier with border & badge', style: TextStyle(fontSize: 11)),
                        value: _isPopular,
                        activeThumbColor: _selectedColor,
                        activeTrackColor: _selectedColor.withValues(alpha: 0.5),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _isPopular = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Theme Color Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Card Accent Color:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Feature Capabilities Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FEATURE CAPABILITIES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                    ),
                    Text(
                      '${_features.length} Features',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Features list items
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _features.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 15, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _features[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeFeature(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Add Feature Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newFeatureController,
                        decoration: const InputDecoration(
                          hintText: 'Add a new feature entitlement...',
                          hintStyle: TextStyle(fontSize: 12),
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onSubmitted: (_) => _addFeature(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _addFeature,
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                        backgroundColor: _selectedColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 18, color: Colors.white),
                      label: Text(
                        isNew ? 'Create Plan' : 'Save Plan Changes',
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
