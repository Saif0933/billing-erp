import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/feedback.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/services/gst_export_helper.dart';
import '../../domain/models/gst_models.dart';
import '../providers/gst_provider.dart';
import '../widgets/gst_file_return_dialog.dart';
import '../widgets/gst_header_profile_card.dart';
import '../widgets/gst_metric_cards.dart';
import '../widgets/gst_navigation_tabs.dart';
import '../widgets/gst_quick_actions_card.dart';
import '../widgets/gst_returns_dashboard_card.dart';
import '../widgets/gst_tax_liability_card.dart';
import '../widgets/gstin_lookup_dialog.dart';

class GstPortalPage extends ConsumerStatefulWidget {
  const GstPortalPage({super.key});

  @override
  ConsumerState<GstPortalPage> createState() => _GstPortalPageState();
}

class _GstPortalPageState extends ConsumerState<GstPortalPage> {
  String _returnTypeFilter = 'All';
  String _returnStatusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.gst)) {
      return const LockedFeaturePage(featureName: 'GST Portal GSTIN');
    }

    final activeTab = ref.watch(gstActiveTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header: GST Portal - GSTIN + [ Refresh from GST Portal ] + [ Go to GST Portal ↗ ]
              _buildPageHeader(context, ref, isDark),
              const SizedBox(height: 14),

              // 1. GSTIN Profile Card (Top Box)
              const GstHeaderProfileCard(),
              const SizedBox(height: 14),

              // 2. Horizontal Navigation Tabs (Overview, Returns, Payments, Ledger, Documents, GSTIN Details, Compliance)
              const GstNavigationTabs(),
              const SizedBox(height: 16),

              // 3. Dynamic Content based on Active Tab
              _buildTabContent(activeTab, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String activeTab, bool isDark) {
    switch (activeTab) {
      case 'Returns':
        return _buildReturnsTab(isDark);
      case 'Payments':
        return _buildPaymentsTab(isDark);
      case 'Ledger':
        return _buildLedgerTab(isDark);
      case 'Documents':
        return _buildDocumentsTab(isDark);
      case 'GSTIN Details':
        return _buildGstinDetailsTab(isDark);
      case 'Compliance':
        return _buildComplianceTab(isDark);
      case 'Overview':
      default:
        return _buildOverviewTab(isDark);
    }
  }

  /// 1. OVERVIEW TAB
  Widget _buildOverviewTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 5 KPI Metric Cards
        const GstMetricCards(),
        const SizedBox(height: 16),

        // Middle Section: Upcoming & Recent Returns (Left) + Liability Summary Donut (Right)
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 850;

            if (isSmall) {
              return Column(
                children: const [
                  GstReturnsDashboardCard(),
                  SizedBox(height: 16),
                  GstTaxLiabilityCard(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  flex: 6,
                  child: GstReturnsDashboardCard(),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: GstTaxLiabilityCard(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Quick Actions Section
        const GstQuickActionsCard(),
      ],
    );
  }

  /// 2. RETURNS TAB
  Widget _buildReturnsTab(bool isDark) {
    final allReturns = ref.watch(gstReturnsListProvider);
    final profile = ref.watch(gstProfileProvider);

    final filteredReturns = allReturns.where((r) {
      if (_returnTypeFilter != 'All' && r.returnType != _returnTypeFilter) {
        return false;
      }
      if (_returnStatusFilter == 'Filed' && r.status != GstReturnStatus.filed) {
        return false;
      }
      if (_returnStatusFilter == 'Not Filed' && r.status != GstReturnStatus.notFiled) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Toolbar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Filter chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildFilterChip('All Types', _returnTypeFilter == 'All', (val) => setState(() => _returnTypeFilter = 'All'), isDark),
                    _buildFilterChip('GSTR-1', _returnTypeFilter == 'GSTR-1', (val) => setState(() => _returnTypeFilter = 'GSTR-1'), isDark),
                    _buildFilterChip('GSTR-3B', _returnTypeFilter == 'GSTR-3B', (val) => setState(() => _returnTypeFilter = 'GSTR-3B'), isDark),
                    _buildFilterChip('GSTR-9', _returnTypeFilter == 'GSTR-9', (val) => setState(() => _returnTypeFilter = 'GSTR-9'), isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('All Status', _returnStatusFilter == 'All', (val) => setState(() => _returnStatusFilter = 'All'), isDark),
                    _buildFilterChip('Filed', _returnStatusFilter == 'Filed', (val) => setState(() => _returnStatusFilter = 'Filed'), isDark),
                    _buildFilterChip('Not Filed', _returnStatusFilter == 'Not Filed', (val) => setState(() => _returnStatusFilter = 'Not Filed'), isDark),
                  ],
                ),
                // Actions: Export All
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 16, color: Colors.white),
                  label: const Text('Export All (Excel)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => GstExportHelper.downloadAllReturnsExcel(
                    context: context,
                    returns: allReturns,
                    profile: profile,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),

          // Table
          LayoutBuilder(
            builder: (context, constraints) {
              const minWidth = 720.0;
              final width = constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        child: Row(
                          children: const [
                            SizedBox(width: 100, child: Text('Return Type', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            SizedBox(width: 110, child: Text('Tax Period', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            SizedBox(width: 110, child: Text('Due Date', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            SizedBox(width: 100, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            Expanded(child: Text('Liability / Tax (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                            SizedBox(width: 180, child: Text('Actions', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),

                      // Rows
                      if (filteredReturns.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No GST returns match the selected filter.',
                              style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else
                        ...filteredReturns.map((item) => _buildReturnsTableRow(context, item, profile, isDark)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsTableRow(BuildContext context, GstReturnRecord item, GstProfile profile, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              item.returnType,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              item.taxPeriod,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              item.dueDate,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
          SizedBox(
            width: 100,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.status == GstReturnStatus.notFiled
                      ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEE2E2))
                      : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status == GstReturnStatus.notFiled ? 'Not Filed' : 'Filed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.status == GstReturnStatus.notFiled ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.liabilityAmount != null ? '₹${_formatCurrency(item.liabilityAmount!)}' : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: item.liabilityAmount != null
                    ? (item.status == GstReturnStatus.notFiled ? const Color(0xFFDC2626) : (isDark ? Colors.white : const Color(0xFF0F172A)))
                    : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Prepare / View Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.status == GstReturnStatus.notFiled ? const Color(0xFF0F172A) : const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => GstFileReturnDialog.show(context, item),
                  child: Text(
                    item.status == GstReturnStatus.notFiled ? 'Prepare' : 'View',
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                // Download JSON
                IconButton(
                  tooltip: 'Download JSON',
                  icon: const Icon(Icons.code, size: 16, color: Color(0xFF0284C7)),
                  onPressed: () => GstExportHelper.downloadReturnJson(context: context, item: item, profile: profile),
                ),
                // Export Excel
                IconButton(
                  tooltip: 'Export to Excel',
                  icon: const Icon(Icons.table_chart_outlined, size: 16, color: Color(0xFF15803D)),
                  onPressed: () => GstExportHelper.downloadReturnExcel(context: context, item: item, profile: profile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. PAYMENTS TAB
  Widget _buildPaymentsTab(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GST Payments & PMT-06 Challans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  const Text('Manage challans, electronic cash offsets and payment records', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_card, size: 16, color: Colors.white),
                label: const Text('Create Challan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  AppFeedback.showSnackbar(context, message: 'Opening PMT-06 Challan Generator...');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Payment Records
          _buildPaymentChallanCard('CH-2026-05-0012', 'May 2026', 'PMT-06 Tax Challan', 18750.00, 'Pending Payment', 'CPIN: 26051900128472', isDark),
          const SizedBox(height: 10),
          _buildPaymentChallanCard('CH-2026-04-0089', 'Apr 2026', 'GSTR-3B Tax Offset', 15420.00, 'Paid & Cleared', 'CIN: HDFC2604200918', isDark),
          const SizedBox(height: 10),
          _buildPaymentChallanCard('CH-2026-03-0045', 'Mar 2026', 'Monthly Advance Tax', 34660.00, 'Paid & Cleared', 'CIN: ICIC2603201124', isDark),
        ],
      ),
    );
  }

  Widget _buildPaymentChallanCard(String chNo, String period, String desc, double amount, String status, String cpin, bool isDark) {
    final isPaid = status.contains('Paid');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFF15803D).withValues(alpha: 0.15) : const Color(0xFFDC2626).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(isPaid ? Icons.check_circle_outline : Icons.pending_actions, color: isPaid ? const Color(0xFF15803D) : const Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$chNo • $desc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text('Period: $period | $cpin', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text('₹${_formatCurrency(amount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isPaid ? const Color(0xFF15803D) : const Color(0xFFDC2626))),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  AppFeedback.showSnackbar(context, message: 'Downloading Challan Receipt for $chNo...');
                },
                child: Text(isPaid ? 'Receipt' : 'Pay Now', style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. LEDGER TAB
  Widget _buildLedgerTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _buildLedgerBox('Electronic Cash Ledger', '₹12,450.00', 'Available for immediate tax settlement', const Color(0xFF16A34A), isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildLedgerBox('Electronic Credit Ledger (ITC)', '₹42,350.00', 'Input Tax Credit as per GSTR-2B', const Color(0xFF0284C7), isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildLedgerBox('Electronic Liability Ledger', '₹18,750.00', 'Upcoming return tax liability', const Color(0xFFDC2626), isDark)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Ledger Transactions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              _buildLedgerEntry('15 May 2026', 'ITC Auto-populated from GSTR-2B (May 2026)', '+ ₹18,420.00', true, isDark),
              _buildLedgerEntry('20 Apr 2026', 'Tax Paid via Net Banking for GSTR-3B', '+ ₹15,420.00', true, isDark),
              _buildLedgerEntry('20 Apr 2026', 'Debit for GSTR-3B Tax Offset (Apr 2026)', '- ₹15,420.00', false, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerBox(String title, String amount, String subtitle, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildLedgerEntry(String date, String desc, String amount, bool isCredit, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 14),
              Text(desc, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            ],
          ),
          Text(
            amount,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  /// 5. DOCUMENTS TAB
  Widget _buildDocumentsTab(bool isDark) {
    final profile = ref.watch(gstProfileProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GST Certificates & Official Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('${profile.legalName} • GSTIN: ${profile.gstin} official records and certificates', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          _buildDocItem('GST Registration Certificate (Form GST REG-06)', 'Active • Issued on 01 Jul 2023', Icons.verified_outlined, () {
            AppFeedback.showSnackbar(context, message: 'Downloading GST Registration Certificate (REG-06)...');
          }, isDark),
          const SizedBox(height: 10),
          _buildDocItem('GSTR-1 Filed Summary (Apr 2026)', 'ARN: AA190426001284 • 11 May 2026', Icons.description_outlined, () {
            AppFeedback.showSnackbar(context, message: 'Downloading GSTR-1 Filed Summary PDF...');
          }, isDark),
          const SizedBox(height: 10),
          _buildDocItem('GSTR-3B Acknowledgement Receipt (Apr 2026)', 'ARN: AA190426009841 • 20 May 2026', Icons.receipt_long_outlined, () {
            AppFeedback.showSnackbar(context, message: 'Downloading GSTR-3B Acknowledgement Receipt...');
          }, isDark),
          const SizedBox(height: 10),
          _buildDocItem('Annual Return GSTR-9 Summary (FY 2024-25)', 'Filed on 28 Dec 2025 • ARN: AA191225008912', Icons.folder_zip_outlined, () {
            AppFeedback.showSnackbar(context, message: 'Downloading GSTR-9 Annual Return Dossier...');
          }, isDark),
        ],
      ),
    );
  }

  Widget _buildDocItem(String title, String subtitle, IconData icon, VoidCallback onDownload, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF15803D), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.download, size: 14, color: Colors.white),
            label: const Text('Download', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }

  /// 6. GSTIN DETAILS TAB
  Widget _buildGstinDetailsTab(bool isDark) {
    final profile = ref.watch(gstProfileProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GSTIN Registration Dossier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  const Text('Verified taxpayer identification details under GSTN Act', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.search, size: 15),
                label: const Text('Lookup Another GSTIN'),
                onPressed: () => GstinLookupDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildProfileField('GSTIN', profile.gstin, isDark, isHighlight: true),
              _buildProfileField('Legal Name', profile.legalName, isDark),
              _buildProfileField('Trade Name', profile.tradeName, isDark),
              _buildProfileField('Constitution of Business', 'Proprietorship / Private Limited', isDark),
              _buildProfileField('Date of Registration', profile.registrationDate, isDark),
              _buildProfileField('Taxpayer Type', 'Regular Taxpayer', isDark),
              _buildProfileField('GSTIN Status', profile.status, isDark, statusColor: const Color(0xFF16A34A)),
              _buildProfileField('State / Jurisdiction', '${profile.state} (Code: ${profile.stateCode})', isDark),
              _buildProfileField('Principal Place of Business', profile.primaryPlaceOfBusiness, isDark, isFullWidth: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value, bool isDark, {bool isHighlight = false, Color? statusColor, bool isFullWidth = false}) {
    return SizedBox(
      width: isFullWidth ? double.infinity : 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 14 : 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: statusColor ?? (isHighlight ? const Color(0xFF15803D) : (isDark ? Colors.white : const Color(0xFF0F172A))),
            ),
          ),
        ],
      ),
    );
  }

  /// 7. COMPLIANCE TAB
  Widget _buildComplianceTab(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GST Compliance Health & Scorecard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Track your return timeliness, ITC match ratio and notice status', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildComplianceCard('Filing Timeliness', '100%', '5 of 5 returns filed on time', const Color(0xFF16A34A), isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildComplianceCard('ITC Match Ratio', '98.4%', 'GSTR-2B vs 3B ITC reconciled', const Color(0xFF0284C7), isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildComplianceCard('Active Notices', '0', 'Zero pending notices / DRC-01', const Color(0xFF16A34A), isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(String title, String score, String desc, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(score, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ValueChanged<bool> onSelected, bool isDark) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)))),
      selected: isSelected,
      selectedColor: const Color(0xFF15803D),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      onSelected: onSelected,
    );
  }

  Widget _buildPageHeader(BuildContext context, WidgetRef ref, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleWidget = Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              tooltip: 'Back',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
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
                    'GST Portal - GSTIN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your GSTIN details, filings, returns and compliance',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final actionsWidget = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Outlined Refresh Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
              ),
              icon: Icon(
                Icons.refresh,
                size: 15,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
              label: Text(
                'Refresh from GST Portal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              onPressed: () async {
                AppFeedback.showSnackbar(context, message: 'Syncing live data from GSTN Portal...');
                final msg = await ref.read(gstStateProvider.notifier).syncFromPortal();
                if (context.mounted) {
                  AppFeedback.showSnackbar(context, message: msg);
                }
              },
            ),

            // Green Solid [ Go to GST Portal ↗ ] Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Text(
                'Go to GST Portal',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              label: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
              onPressed: () {
                AppFeedback.showSnackbar(context, message: 'Opening https://www.gst.gov.in in browser...');
              },
            ),
          ],
        );

        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleWidget,
              const SizedBox(height: 10),
              actionsWidget,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 8),
            actionsWidget,
          ],
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final dec = parts[1];

    if (whole.length <= 3) {
      return '$whole.$dec';
    }

    final lastThree = whole.substring(whole.length - 3);
    final otherNumbers = whole.substring(0, whole.length - 3);

    final formattedOther = otherNumbers.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '$formattedOther,$lastThree.$dec';
  }
}
