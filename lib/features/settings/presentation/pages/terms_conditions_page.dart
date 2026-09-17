import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_TermsSection> _sections = const [
    _TermsSection(
      index: '01',
      id: 'acceptance',
      title: 'Acceptance of Terms & Enterprise Scope',
      icon: Icons.verified_user_outlined,
      tag: 'Mandatory',
      content:
          'By accessing or using this multi-tenant cloud billing and enterprise resource platform ("Service"), '
          'you agree to be bound by these Terms and Conditions ("Terms"). If you represent an organization or business entity, '
          'you warrant that you have full legal authority to bind that entity to these Terms. If you do not agree to these Terms, '
          'you must immediately cease using the platform.',
    ),
    _TermsSection(
      index: '02',
      id: 'saas_license',
      title: 'SaaS License, Subscriptions & Access Rights',
      icon: Icons.vpn_key_outlined,
      tag: 'Access',
      content:
          'We grant your organization a non-exclusive, non-transferable, revocable subscription license to access '
          'and use the platform in accordance with your subscribed plan. You are solely responsible for safeguarding all administrative '
          'and team user credentials, preventing unauthorized access, and maintaining accurate business profile records.',
    ),
    _TermsSection(
      index: '03',
      id: 'billing_gst',
      title: 'Financial Billing, Invoicing & GST Tax Accuracy',
      icon: Icons.receipt_long_outlined,
      tag: 'Compliance',
      content:
          'The platform provides tools for generating sales invoices, purchase records, e-way bills, and calculating GST tax liabilities. '
          'You acknowledge that your organization is solely responsible for verifying the accuracy of tax percentages, HSN/SAC codes, '
          'customer details, and statutory tax filings with governmental authorities.',
    ),
    _TermsSection(
      index: '04',
      id: 'data_ownership',
      title: 'Data Ownership & Intellectual Property',
      icon: Icons.folder_shared_outlined,
      tag: 'Ownership',
      content:
          'All business records, client ledgers, inventory counts, and financial transaction data entered into your tenant space '
          'remain the exclusive property of your organization. We claim no intellectual property rights over your proprietary business data. '
          'You may export your complete data records at any time using our standard export utilities.',
    ),
    _TermsSection(
      index: '05',
      id: 'uptime_maintenance',
      title: 'Service Availability, SLAs & System Maintenance',
      icon: Icons.cloud_done_outlined,
      tag: 'Service SLA',
      content:
          'We endeavor to maintain 99.9% application availability. Scheduled system upgrades, security patches, and server maintenance '
          'will be announced in advance when feasible. We are not liable for transient interruptions arising from telecommunication failures, '
          'third-party API downtime, or circumstances beyond reasonable control.',
    ),
    _TermsSection(
      index: '06',
      id: 'liability',
      title: 'Limitation of Liability & Statutory Disclaimers',
      icon: Icons.shield_outlined,
      tag: 'Liability',
      content:
          'To the maximum extent permitted by applicable law, the Service is provided "AS IS" and "AS AVAILABLE". '
          'In no event shall the platform providers or affiliates be liable for indirect, incidental, punitive, or consequential damages, '
          'including loss of profits, commercial interruption, or tax penalties resulting from data entry errors.',
    ),
    _TermsSection(
      index: '07',
      id: 'termination',
      title: 'Term, Renewal & Account Termination Safeguards',
      icon: Icons.cancel_outlined,
      tag: 'Termination',
      content:
          'Either party may terminate the subscription upon 30 days prior written notice. Upon account cancellation, '
          'you will retain 30 days of read-only access to download backups, after which the tenant database will be securely decommissioned '
          'in accordance with data retention compliance standards.',
    ),
    _TermsSection(
      index: '08',
      id: 'governing_law',
      title: 'Governing Law & Legal Jurisdiction',
      icon: Icons.gavel_outlined,
      tag: 'Legal',
      content:
          'These Terms shall be governed by and construed in accordance with the laws of the applicable jurisdiction, '
          'without regard to conflict of law principles. Any dispute arising under these Terms shall be resolved exclusively in the '
          'competent courts of jurisdiction.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final filteredSections = _sections.where((section) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return section.title.toLowerCase().contains(query) ||
          section.content.toLowerCase().contains(query) ||
          section.tag.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isMobile = screenWidth < 600;
            final isTablet = screenWidth >= 600 && screenWidth < 960;
            final horizontalPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 24.0);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isMobile ? 12.0 : AppSpacing.md,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroBanner(isDark: isDark, isMobile: isMobile),
                      const SizedBox(height: 16),
                      _buildQuickHighlights(isDark: isDark, screenWidth: screenWidth),
                      const SizedBox(height: 16),
                      _buildSearchBar(
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        secondaryText: secondaryText,
                        matchCount: filteredSections.length,
                        totalCount: _sections.length,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 14),
                      if (filteredSections.isEmpty)
                        _buildEmptyState(isDark: isDark, mutedText: mutedText)
                      else
                        ...filteredSections.map(
                          (section) => _buildSectionCard(
                            section: section,
                            isDark: isDark,
                            surface: surface,
                            border: border,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            isMobile: isMobile,
                          ),
                        ),
                      const SizedBox(height: 20),
                      _buildFooterNotice(
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        mutedText: mutedText,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBanner({required bool isDark, required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF312E81),
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: isMobile ? 14 : 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'LEGAL & GOVERNANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF34D399)),
                    SizedBox(width: 5),
                    Text(
                      'Active • Version 2.4',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Terms & Conditions',
            style: TextStyle(
              fontSize: isMobile ? 20 : 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Master Service Agreement, SaaS licensing rules, GST responsibility matrix, and data ownership commitments governing your enterprise workspace.',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13.5,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHighlights({required bool isDark, required double screenWidth}) {
    final highlights = [
      _HighlightItem(
        icon: Icons.cloud_done_rounded,
        title: '99.9% Uptime SLA',
        subtitle: 'Enterprise Cloud Guarantee',
        color: const Color(0xFF6366F1),
      ),
      _HighlightItem(
        icon: Icons.lock_person_rounded,
        title: '100% Data Ownership',
        subtitle: 'Unrestricted Portability',
        color: const Color(0xFF10B981),
      ),
      _HighlightItem(
        icon: Icons.account_balance_rounded,
        title: 'Statutory GST Ready',
        subtitle: 'Audited Invoice Formats',
        color: const Color(0xFFF59E0B),
      ),
    ];

    final isNarrow = screenWidth < 680;
    if (isNarrow) {
      return Column(
        children: highlights
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildHighlightCard(item, isDark),
              ),
            )
            .toList(),
      );
    }
    return Row(
      children: highlights
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildHighlightCard(item, isDark),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildHighlightCard(_HighlightItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, size: 19, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar({
    required bool isDark,
    required Color surface,
    required Color border,
    required Color secondaryText,
    required int matchCount,
    required int totalCount,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        decoration: InputDecoration(
          hintText: isMobile
              ? 'Search clauses, terms, SLAs...'
              : 'Search within terms, clauses, SLAs, GST policies...',
          hintStyle: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF6366F1),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isMobile ? '$matchCount/$totalCount' : '$matchCount / $totalCount clauses',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 17),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 12 : 15),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required _TermsSection section,
    required bool isDark,
    required Color surface,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
    required bool isMobile,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 12 : 16, 12, isMobile ? 12 : 16, 10),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    section.index,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14.5,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    section.tag,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Text(
              section.content,
              style: TextStyle(
                fontSize: isMobile ? 12.5 : 13.5,
                height: 1.55,
                color: secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required Color mutedText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: mutedText),
            const SizedBox(height: 12),
            Text(
              'No matching terms or clauses found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNotice({
    required bool isDark,
    required Color surface,
    required Color border,
    required Color mutedText,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enterprise Custom SLAs & Legal Questions',
                  style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  'Organizations requiring dedicated enterprise agreements, custom data retention policies, or offline BAA agreements can reach out to our legal compliance counsel at legal@platform.com.',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: mutedText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection {
  final String index;
  final String id;
  final String title;
  final IconData icon;
  final String tag;
  final String content;

  const _TermsSection({
    required this.index,
    required this.id,
    required this.title,
    required this.icon,
    required this.tag,
    required this.content,
  });
}

class _HighlightItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _HighlightItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
