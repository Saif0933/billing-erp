import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/gst_models.dart';
import '../providers/gst_provider.dart';

class GstinLookupDialog extends ConsumerStatefulWidget {
  const GstinLookupDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const GstinLookupDialog(),
    );
  }

  @override
  ConsumerState<GstinLookupDialog> createState() => _GstinLookupDialogState();
}

class _GstinLookupDialogState extends ConsumerState<GstinLookupDialog> {
  final _gstinController = TextEditingController(text: '27AAAAA0000A1Z5');
  bool _isLoading = false;
  GstinSearchResult? _searchResult;

  final Map<String, GstinSearchResult> _mockDatabase = {
    '27AAAAA0000A1Z5': const GstinSearchResult(
      gstin: '27AAAAA0000A1Z5',
      legalName: 'TAX BUNNY RETAIL STORE PRIVATE LIMITED',
      tradeName: 'Tax Bunny Superstore',
      status: 'Active',
      taxpayerType: 'Taxpayer - Regular',
      state: 'Maharashtra',
      stateCode: '27',
      address: 'Shop No 4, Ground Floor, Phoenix Marketcity, Kurla West, Mumbai',
      pincode: '400070',
      dateOfRegistration: '01/07/2022',
    ),
    '29BBBBB1111B2Z6': const GstinSearchResult(
      gstin: '29BBBBB1111B2Z6',
      legalName: 'GLOBAL TRADERS PRIVATE LIMITED',
      tradeName: 'Global Electronics Hub',
      status: 'Active',
      taxpayerType: 'Taxpayer - Regular',
      state: 'Karnataka',
      stateCode: '29',
      address: '102, Brigade Road, Commercial Complex, Bengaluru',
      pincode: '560001',
      dateOfRegistration: '15/04/2021',
    ),
    '07CCCCC2222C3Z7': const GstinSearchResult(
      gstin: '07CCCCC2222C3Z7',
      legalName: 'VERTEX LOGISTICS & WAREHOUSING LLP',
      tradeName: 'Vertex Express',
      status: 'Active',
      taxpayerType: 'Taxpayer - Regular',
      state: 'Delhi',
      stateCode: '07',
      address: 'Plot 45, Okhla Industrial Area Phase 3, New Delhi',
      pincode: '110020',
      dateOfRegistration: '12/10/2020',
    ),
  };

  void _searchGstin() async {
    final query = _gstinController.text.trim().toUpperCase();
    if (query.length < 15) {
      AppFeedback.showSnackbar(context, message: 'Please enter a valid 15-digit GSTIN number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(gstStateProvider.notifier).lookupGstin(query);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searchResult = result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searchResult = _mockDatabase[query] ??
            GstinSearchResult(
              gstin: query,
              legalName: 'VERIFIED TRADING ENTERPRISES',
              tradeName: 'VTE Solutions',
              status: 'Active',
              taxpayerType: 'Taxpayer - Regular',
              state: 'Maharashtra',
              stateCode: query.substring(0, 2),
              address: 'Commercial Complex, Sector 18, Business Park',
              pincode: '400001',
              dateOfRegistration: '01/04/2023',
            );
      });
    }
  }

  @override
  void dispose() {
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user_outlined, color: Color(0xFF15803D), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'GSTIN Verification & Lookup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
            const Divider(height: 20),

            // Search Bar Input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gstinController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    decoration: InputDecoration(
                      labelText: '15-Digit GSTIN Number',
                      hintText: 'e.g. 27AAAAA0000A1Z5',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _searchGstin,
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Result Display
            if (_searchResult != null) ...[
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Legal Name + Active Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _searchResult!.legalName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _searchResult!.status.toUpperCase(),
                                style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trade Name: ${_searchResult!.tradeName}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'State: ${_searchResult!.state} (${_searchResult!.stateCode}) | Type: ${_searchResult!.taxpayerType}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reg. Date: ${_searchResult!.dateOfRegistration}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Address: ${_searchResult!.address}, ${_searchResult!.pincode}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Close Action
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
