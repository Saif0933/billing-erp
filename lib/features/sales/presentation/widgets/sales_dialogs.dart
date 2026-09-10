import 'package:flutter/material.dart';
import '../models/sales_ui_models.dart';

class SalesCustomerDialog extends StatefulWidget {
  final String currentCustomer;
  final List<String> customers;
  final ValueChanged<String> onSelect;

  const SalesCustomerDialog({
    super.key,
    required this.currentCustomer,
    required this.customers,
    required this.onSelect,
  });

  @override
  State<SalesCustomerDialog> createState() => _SalesCustomerDialogState();
}

class _SalesCustomerDialogState extends State<SalesCustomerDialog> {
  final _newCustomerController = TextEditingController();
  final _phoneController = TextEditingController();
  late List<String> _filteredCustomers;
  final _searchController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
  }

  @override
  void dispose() {
    _newCustomerController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      _filteredCustomers = widget.customers
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isCreatingNew ? 'Add New Customer' : 'Select Customer (F4)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: _isCreatingNew ? _buildCreateForm() : _buildSelectionList(),
      ),
      actions: [
        if (!_isCreatingNew)
          TextButton.icon(
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Add New Customer'),
            onPressed: () => setState(() => _isCreatingNew = true),
          ),
        if (_isCreatingNew) ...[
          TextButton(
            onPressed: () => setState(() => _isCreatingNew = false),
            child: const Text('Back to List'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = _newCustomerController.text.trim();
              if (name.isNotEmpty) {
                widget.onSelect(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Save & Select'),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _filter,
          decoration: InputDecoration(
            hintText: 'Search customer name...',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            itemCount: _filteredCustomers.length,
            itemBuilder: (context, index) {
              final name = _filteredCustomers[index];
              final isSelected = name == widget.currentCustomer;

              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                selected: isSelected,
                selectedTileColor: const Color(0xFFDCFCE7),
                leading: CircleAvatar(
                  backgroundColor: isSelected ? const Color(0xFF059669) : const Color(0xFFF3F4F6),
                  foregroundColor: isSelected ? Colors.white : const Color(0xFF4B5563),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C'),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF065F46)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1F2937)),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF059669))
                    : null,
                onTap: () {
                  widget.onSelect(name);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _newCustomerController,
          decoration: InputDecoration(
            labelText: 'Customer Full Name *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class SalesAddNoteDialog extends StatefulWidget {
  final String initialNote;
  final ValueChanged<String> onSave;

  const SalesAddNoteDialog({
    super.key,
    required this.initialNote,
    required this.onSave,
  });

  @override
  State<SalesAddNoteDialog> createState() => _SalesAddNoteDialogState();
}

class _SalesAddNoteDialogState extends State<SalesAddNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Transaction Note', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Delivery instructions, packaging notes...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onSave(_controller.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save Note'),
        ),
      ],
    );
  }
}

class SalesHoldBillsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> heldBills;
  final ValueChanged<int> onResume;
  final ValueChanged<int> onDelete;

  const SalesHoldBillsDialog({
    super.key,
    required this.heldBills,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Held Bills', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        height: 280,
        child: heldBills.isEmpty
            ? const Center(
                child: Text('No held bills at the moment.', style: TextStyle(color: Colors.grey)),
              )
            : ListView.separated(
                itemCount: heldBills.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final bill = heldBills[index];
                  final customer = bill['customer'] as String? ?? 'Walk-in Customer';
                  final items = bill['items'] as List<SalesCartItem>? ?? [];
                  final amount = bill['amount'] as double? ?? 0.0;
                  final time = bill['time'] as String? ?? 'Just now';

                  return ListTile(
                    title: Text(
                      customer,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${items.length} items • ₹${amount.toStringAsFixed(2)} • $time'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => onDelete(index),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Resume'),
                          onPressed: () {
                            onResume(index);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class SalesBillSuccessDialog extends StatelessWidget {
  final String billNumber;
  final String customerName;
  final List<SalesCartItem> items;
  final double subtotal;
  final double discount;
  final double cgst;
  final double sgst;
  final double grandTotal;
  final VoidCallback onPrint;

  const SalesBillSuccessDialog({
    super.key,
    required this.billNumber,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bill Generated Successfully!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Theme(
          data: ThemeData.light(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'TAX BUNNY - RETAIL STORE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Center(
                  child: Text(
                    'Main Branch Terminal',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE5E7EB), height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bill No:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      billNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customer:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE5E7EB), height: 1),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Column(
                      children: items.map(
                        (it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    text: it.product.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '  ×${it.quantity}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${it.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE5E7EB), height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discount:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '-₹${discount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CGST (2.5%):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${cgst.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SGST (2.5%):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${sgst.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE5E7EB), height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '₹${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF10B981),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: const Icon(Icons.print, size: 18),
          label: const Text(
            'Print Receipt (Ctrl+P)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          onPressed: () {
            onPrint();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
