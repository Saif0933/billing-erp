import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../data/models/purchase_return_dto.dart';
import '../../domain/models/purchase_return_model.dart';
import '../providers/purchase_return_provider.dart';

class CreatePurchaseReturnDialog extends ConsumerStatefulWidget {
  const CreatePurchaseReturnDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CreatePurchaseReturnDialog(),
    );
  }

  @override
  ConsumerState<CreatePurchaseReturnDialog> createState() =>
      _CreatePurchaseReturnDialogState();
}

class _CreatePurchaseReturnDialogState
    extends ConsumerState<CreatePurchaseReturnDialog> {
  static const _green = Color(0xFF15803D);
  static const _greenSoft = Color(0xFFDCFCE7);
  static const _greenBg = Color(0xFFF0FDF4);
  static const _slate = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  final _debitNoteNoController = TextEditingController();
  final _reasonController = TextEditingController();
  final _purchaseSearchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');

  bool _loadingMeta = true;
  bool _searching = false;
  bool _submitting = false;
  String? _loadError;

  List<EligiblePurchaseDto> _eligiblePurchases = [];
  EligiblePurchaseDto? _selectedPurchase;
  EligiblePurchaseItemDto? _selectedItem;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingMeta = true;
      _loadError = null;
    });
    try {
      final api = ref.read(purchaseReturnApiServiceProvider);
      final results = await Future.wait([
        api.getNextDebitNoteNumber(),
        api.getEligiblePurchases(limit: 50),
      ]);
      if (!mounted) return;
      setState(() {
        _debitNoteNoController.text = results[0] as String;
        _eligiblePurchases = results[1] as List<EligiblePurchaseDto>;
        _loadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMeta = false;
        _loadError = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _searchPurchases(String query) async {
    setState(() => _searching = true);
    try {
      final api = ref.read(purchaseReturnApiServiceProvider);
      final list = await api.getEligiblePurchases(search: query, limit: 50);
      if (!mounted) return;
      setState(() {
        _eligiblePurchases = list;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _debitNoteNoController.dispose();
    _reasonController.dispose();
    _purchaseSearchController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_qtyController.text) ?? 0;
  double get _rate => _selectedItem?.rate ?? 0;
  double get _gstRate => _selectedItem?.gstRate ?? 0;
  double get _subtotal => _qty * _rate;
  double get _tax => _subtotal * (_gstRate / 100);
  double get _total => _subtotal + _tax;

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? helper,
    Widget? prefixIcon,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 1,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      labelStyle: TextStyle(
        fontSize: 12.5,
        color: isDark ? Colors.white60 : _muted,
      ),
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white24 : _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white24 : _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _green, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedPurchase == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select the original purchase bill',
      );
      return;
    }
    if (_selectedItem == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select a product to return',
      );
      return;
    }
    if (_qty <= 0 || _qty > _selectedItem!.remainingQty) {
      AppFeedback.showSnackbar(
        context,
        message:
            'Return qty must be between 0.001 and ${_selectedItem!.remainingQty}',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final newReturn = PurchaseReturn(
        id: '',
        debitNoteNumber: _debitNoteNoController.text.trim(),
        originalPurchaseId: _selectedPurchase!.id,
        originalPurchaseBillNumber: _selectedPurchase!.displayBillNumber,
        supplierId: _selectedPurchase!.supplierId,
        supplierName: _selectedPurchase!.supplierName,
        supplierGstin: _selectedPurchase!.supplierGstin,
        returnDate: DateTime.now(),
        items: [
          PurchaseReturnItem(
            id: '',
            productId: _selectedItem!.productId,
            productName: _selectedItem!.productName,
            hsnCode: _selectedItem!.hsnCode,
            quantityReturned: _qty,
            unit: _selectedItem!.unit,
            unitPrice: _rate,
            gstRate: _gstRate,
            taxAmount: _tax,
            totalAmount: _total,
            returnReason: _reasonController.text.trim(),
          ),
        ],
        subtotal: _subtotal,
        taxAmount: _tax,
        totalAmount: _total,
        amountAdjusted: 0,
        status: PurchaseReturnStatus.confirmed,
        returnReason: _reasonController.text.trim(),
      );

      final created = await ref
          .read(purchaseReturnListProvider.notifier)
          .createReturn(newReturn, saveAs: PurchaseReturnStatus.confirmed);

      if (!mounted) return;
      Navigator.pop(context);
      AppFeedback.showSnackbar(
        context,
        message:
            'Debit Note ${created?.debitNoteNumber ?? _debitNoteNoController.text} issued successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showSnackbar(
        context,
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _selectPurchase(EligiblePurchaseDto purchase) {
    setState(() {
      _selectedPurchase = purchase;
      _selectedItem = purchase.items.isNotEmpty ? purchase.items.first : null;
      _qtyController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final isCompact = width < 600;
    final isWide = width >= 900;

    final horizontalInset = isCompact ? 10.0 : (isWide ? 48.0 : 20.0);
    final verticalInset = isCompact ? 12.0 : 24.0;
    final maxDialogWidth = isWide ? 860.0 : (isCompact ? width : 640.0);
    final maxDialogHeight = height - (verticalInset * 2);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight,
          minWidth: isCompact ? 0 : 320,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isDark, isCompact),
              Flexible(
                child: _loadingMeta
                    ? _buildLoading(isDark)
                    : _loadError != null
                        ? _buildError(isDark)
                        : SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              isCompact ? 14 : 20,
                              4,
                              isCompact ? 14 : 20,
                              8,
                            ),
                            child: isWide
                                ? _buildWideBody(isDark)
                                : _buildNarrowBody(isDark, isCompact),
                          ),
              ),
              _buildFooter(isDark, isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isCompact) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 20,
        isCompact ? 14 : 16,
        8,
        isCompact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF064E3B), Color(0xFF1E293B)]
              : const [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFBBF7D0),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? _green.withValues(alpha: 0.25)
                  : _greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_return_rounded,
              color: isDark ? const Color(0xFF34D399) : _green,
              size: isCompact ? 20 : 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Purchase Return',
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _slate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Issue debit note against a confirmed purchase bill',
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    color: isDark ? Colors.white60 : _muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _submitting ? null : () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _green),
          const SizedBox(height: 14),
          Text(
            'Loading purchase bills…',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            _loadError ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _bootstrap,
            style: FilledButton.styleFrom(backgroundColor: _green),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowBody(bool isDark, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('Debit Note', isDark),
        const SizedBox(height: 8),
        _buildDebitNoteField(isDark),
        const SizedBox(height: 18),
        _sectionLabel('Original Purchase Bill', isDark),
        const SizedBox(height: 8),
        _buildPurchaseSearch(isDark),
        const SizedBox(height: 10),
        _buildPurchaseList(isDark, compact: true),
        if (_selectedPurchase != null) ...[
          const SizedBox(height: 10),
          _buildSupplierChip(isDark),
        ],
        const SizedBox(height: 18),
        _sectionLabel('Item Return Details', isDark),
        const SizedBox(height: 8),
        _buildProductDropdown(isDark),
        const SizedBox(height: 10),
        isCompact
            ? Column(
                children: [
                  _buildQtyField(isDark),
                  const SizedBox(height: 10),
                  _buildRateField(isDark),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildQtyField(isDark)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildRateField(isDark)),
                ],
              ),
        const SizedBox(height: 10),
        _buildReasonField(isDark),
        const SizedBox(height: 14),
        _buildSummaryCard(isDark),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildWideBody(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('Debit Note & Purchase Bill', isDark),
                  const SizedBox(height: 8),
                  _buildDebitNoteField(isDark),
                  const SizedBox(height: 12),
                  _buildPurchaseSearch(isDark),
                  const SizedBox(height: 10),
                  _buildPurchaseList(isDark, compact: false),
                  if (_selectedPurchase != null) ...[
                    const SizedBox(height: 10),
                    _buildSupplierChip(isDark),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('Item Return Details', isDark),
                  const SizedBox(height: 8),
                  _buildProductDropdown(isDark),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildQtyField(isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildRateField(isDark)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildReasonField(isDark),
                  const SizedBox(height: 14),
                  _buildSummaryCard(isDark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _sectionLabel(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: isDark ? Colors.white70 : const Color(0xFF334155),
      ),
    );
  }

  Widget _buildDebitNoteField(bool isDark) {
    return TextFormField(
      controller: _debitNoteNoController,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : _slate,
      ),
      decoration: _fieldDecoration(
        label: 'Debit Note # *',
        prefixIcon: Icon(
          Icons.tag_rounded,
          size: 18,
          color: isDark ? const Color(0xFF34D399) : _green,
        ),
        isDark: isDark,
      ),
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildPurchaseSearch(bool isDark) {
    return TextField(
      controller: _purchaseSearchController,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : _slate,
      ),
      decoration: _fieldDecoration(
        label: 'Search purchase bill',
        hint: 'Bill # / supplier name…',
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
        ),
        suffixIcon: _searching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _green),
                ),
              )
            : IconButton(
                tooltip: 'Search',
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: isDark ? Colors.white54 : _muted,
                ),
                onPressed: () =>
                    _searchPurchases(_purchaseSearchController.text.trim()),
              ),
        isDark: isDark,
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: _searchPurchases,
    );
  }

  Widget _buildPurchaseList(bool isDark, {required bool compact}) {
    if (_eligiblePurchases.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : _border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 22,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No confirmed purchases with returnable stock found.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : _muted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: compact ? 168 : 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : _border),
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        shrinkWrap: true,
        itemCount: _eligiblePurchases.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
        itemBuilder: (context, index) {
          final p = _eligiblePurchases[index];
          final selected = _selectedPurchase?.id == p.id;
          return Material(
            color: selected
                ? (isDark
                    ? _green.withValues(alpha: 0.18)
                    : _greenSoft)
                : Colors.transparent,
            child: InkWell(
              onTap: () => _selectPurchase(p),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? _green
                            : (isDark
                                ? Colors.white10
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        selected
                            ? Icons.check_rounded
                            : Icons.receipt_long_outlined,
                        size: 16,
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white54 : _muted),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.displayBillNumber,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? (isDark
                                      ? const Color(0xFF34D399)
                                      : _green)
                                  : (isDark ? Colors.white : _slate),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.supplierName,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white54 : _muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${p.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierChip(bool isDark) {
    final p = _selectedPurchase!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : _greenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 18,
            color: isDark ? const Color(0xFF34D399) : _green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.supplierName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _slate,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (p.supplierGstin.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'GSTIN: ${p.supplierGstin}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : _muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${p.items.length} item${p.items.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF34D399) : _green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(bool isDark) {
    final items = _selectedPurchase?.items ?? [];
    return DropdownButtonFormField<String>(
      value: _selectedItem?.productId,
      isExpanded: true,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      decoration: _fieldDecoration(
        label: 'Product / Item *',
        prefixIcon: Icon(
          Icons.inventory_2_outlined,
          size: 18,
          color: isDark ? Colors.white54 : _muted,
        ),
        isDark: isDark,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item.productId,
              child: Text(
                '${item.productName}  ·  Rem ${item.remainingQty} ${item.unit}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : _slate,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: items.isEmpty
          ? null
          : (val) {
              if (val == null || _selectedPurchase == null) return;
              final match = _selectedPurchase!.items
                  .where((i) => i.productId == val)
                  .toList();
              setState(() {
                _selectedItem = match.isNotEmpty ? match.first : null;
                _qtyController.text = '1';
              });
            },
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildQtyField(bool isDark) {
    return TextFormField(
      controller: _qtyController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : _slate,
      ),
      decoration: _fieldDecoration(
        label: 'Return Qty *',
        helper: _selectedItem == null
            ? null
            : 'Max ${_selectedItem!.remainingQty} ${_selectedItem!.unit}',
        isDark: isDark,
      ),
      onChanged: (_) => setState(() {}),
      validator: (val) {
        final q = double.tryParse(val ?? '');
        if (q == null || q <= 0) return 'Invalid qty';
        if (_selectedItem != null && q > _selectedItem!.remainingQty) {
          return 'Exceeds remaining';
        }
        return null;
      },
    );
  }

  Widget _buildRateField(bool isDark) {
    return InputDecorator(
      decoration: _fieldDecoration(
        label: 'Unit Rate (₹)',
        isDark: isDark,
      ),
      child: Text(
        '₹ ${_rate.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : _slate,
        ),
      ),
    );
  }

  Widget _buildReasonField(bool isDark) {
    return TextFormField(
      controller: _reasonController,
      maxLines: 3,
      minLines: 2,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : _slate,
      ),
      decoration: _fieldDecoration(
        label: 'Return Reason *',
        hint: 'e.g. Defective items, transit damage…',
        isDark: isDark,
      ),
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF064E3B).withValues(alpha: 0.45),
                  const Color(0xFF0F172A),
                ]
              : const [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', _subtotal, isDark, bold: false),
          const SizedBox(height: 6),
          _summaryRow(
            'GST (${_gstRate.toStringAsFixed(0)}%)',
            _tax,
            isDark,
            bold: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              color: isDark ? Colors.white24 : const Color(0xFF86EFAC),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Debit Note Total',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _slate,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  '₹${_total.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF34D399) : _green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount,
    bool isDark, {
    required bool bold,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark, bool isCompact) {
    final cancelBtn = OutlinedButton(
      onPressed: _submitting ? null : () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
        side: BorderSide(color: isDark ? Colors.white24 : _border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Cancel'),
    );

    final submitBtn = FilledButton.icon(
      onPressed: _submitting || _loadingMeta || _loadError != null
          ? null
          : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        disabledBackgroundColor: _green.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: _submitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_outline, size: 18),
      label: Text(
        _submitting ? 'Issuing…' : 'Issue Debit Note',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 20,
        12,
        isCompact ? 14 : 20,
        isCompact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : _border),
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                submitBtn,
                const SizedBox(height: 8),
                cancelBtn,
              ],
            )
          : Row(
              children: [
                const Spacer(),
                cancelBtn,
                const SizedBox(width: 10),
                submitBtn,
              ],
            ),
    );
  }
}
