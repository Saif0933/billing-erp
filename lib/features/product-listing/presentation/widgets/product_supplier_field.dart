import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/billing_models.dart';
import '../../../supplier/presentation/providers/supplier_provider.dart';

/// Pick an existing supplier, or open the supplier profile screen to create one.
class ProductSupplierField extends ConsumerWidget {
  final String supplierId;
  final String supplierName;
  final ValueChanged<({String id, String name})> onChanged;
  final bool dense;

  const ProductSupplierField({
    super.key,
    required this.supplierId,
    required this.supplierName,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierState = ref.watch(supplierProvider);
    final suppliers = supplierState.suppliers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ids = suppliers.map((s) => s.id).toSet();
    final selectedId = supplierId.isNotEmpty && ids.contains(supplierId)
        ? supplierId
        : (supplierId.isNotEmpty ? supplierId : '');

    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('No supplier', style: TextStyle(fontSize: 12)),
      ),
      if (supplierId.isNotEmpty && !ids.contains(supplierId))
        DropdownMenuItem<String>(
          value: supplierId,
          child: Text(
            supplierName.isNotEmpty ? supplierName : 'Selected supplier',
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ...suppliers.map(
        (s) => DropdownMenuItem<String>(
          value: s.id,
          child: Text(
            s.name,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!dense)
          Text(
            'Supplier',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        if (!dense) const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('supplier-dd-$selectedId-${suppliers.length}'),
                initialValue: items.any((i) => i.value == selectedId)
                    ? selectedId
                    : '',
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: dense
                      ? null
                      : const Icon(Icons.local_shipping_outlined, size: 18),
                  hintText: 'Select supplier',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: items,
                onChanged: (val) {
                  if (val == null || val.isEmpty) {
                    onChanged((id: '', name: ''));
                    return;
                  }
                  Supplier? match;
                  for (final s in suppliers) {
                    if (s.id == val) {
                      match = s;
                      break;
                    }
                  }
                  onChanged((id: val, name: match?.name ?? supplierName));
                },
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Create supplier',
              child: OutlinedButton(
                onPressed: () => _openSupplierProfileScreen(context, ref),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: dense ? 8 : 12,
                    vertical: 12,
                  ),
                  minimumSize: Size(dense ? 40 : 0, 42),
                  side: const BorderSide(color: Color(0xFF15803D)),
                  foregroundColor: const Color(0xFF15803D),
                ),
                child: dense
                    ? const Icon(Icons.add, size: 18)
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16),
                          SizedBox(width: 4),
                          Text('New', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openSupplierProfileScreen(BuildContext context, WidgetRef ref) async {
    final beforeIds = ref.read(supplierProvider).suppliers.map((s) => s.id).toSet();

    await context.push('/suppliers/new');
    if (!context.mounted) return;

    await ref.read(supplierProvider.notifier).loadSuppliers();
    if (!context.mounted) return;

    final after = ref.read(supplierProvider).suppliers;
    for (final s in after) {
      if (!beforeIds.contains(s.id)) {
        onChanged((id: s.id, name: s.name));
        break;
      }
    }
  }
}
