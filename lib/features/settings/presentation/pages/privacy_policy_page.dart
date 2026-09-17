import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<_PolicySection> _sections = const [
    _PolicySection(
      index: '01',
      id: 'collection',
      category: 'Data Types',
      title: 'Information We Collect & Ingestion Scope',
      icon: Icons.data_usage_rounded,
      highlight: 'Business Profile, Ledgers, GSTIN/PAN & Invoicing Records',
      content:
          'We collect business profile data, contact details, user login credentials, client billing directories, '
          'tax identification numbers (GSTIN/PAN), and transaction logs required to operate our enterprise billing, '
          'inventory tracking, and financial accounting modules.',
      bullets: [
        'Business legal names, trade names, PAN, and active GSTIN registrations',
        'Customer & vendor directory records, phone numbers, and addresses',
        'Item catalogs, HSN/SAC codes, pricing lists, and stock balance levels',
        'System audit trails with timestamped user activity and IP logs',
      ],
    ),
    _PolicySection(
      index: '02',
      id: 'usage',
      category: 'Processing',
      title: 'Data Processing & Strict Zero-Monetization Rule',
      icon: Icons.settings_suggest_rounded,
      highlight: '100% Zero Data Monetization • Strictly Functional Processing',
      content:
          'Your data is processed strictly to provide platform functionalities, calculate invoice totals and tax liabilities, '
          'generate financial reports, facilitate automated recurring billing schedulers, and verify user permissions (RBAC). '
          'We never sell, rent, or monetize your proprietary business data or customer contact records.',
      bullets: [
        'Generating sales invoices, credit notes, receipts, and e-way bill payloads',
        'Real-time calculation of CGST, SGST, IGST, and statutory financial ledgers',
        'Enforcing Role-Based Access Control (RBAC) across team accounts',
        'No algorithmic ad profiling, third-party tracking, or commercial data selling',
      ],
    ),
    _PolicySection(
      index: '03',
      id: 'security_encryption',
      category: 'Security',
      title: 'Multi-Tenant Cryptographic Vault & AES-256 Isolation',
      icon: Icons.lock_rounded,
      highlight: 'AES-256 At Rest • TLS 1.3 In Transit • Row-Level Database Isolation',
      content:
          'We implement enterprise-grade security protocols including AES-256 encryption at rest and TLS 1.3 encryption in transit. '
          'Tenant data is logically isolated using database-level row and tenant key isolation architectures to prevent cross-tenant data leakage. '
          'Audit trails record every state-altering administrative action.',
      bullets: [
        'Isolated tenant encryption keys with automated hardware security modules',
        'Zero-trust network architecture with multi-factor authentication enforcement',
        'Granular immutable security audit trails recording all ledger edits',
        'Continuous automated vulnerability scanning and DDoS mitigation filters',
      ],
    ),
    _PolicySection(
      index: '04',
      id: 'third_party',
      category: 'Infrastructure',
      title: 'Third-Party Integrations & Tier-IV Cloud Hosting',
      icon: Icons.cloud_queue_rounded,
      highlight: 'ISO 27001 & SOC 2 Certified Cloud Data Centers',
      content:
          'We partner with tier-IV certified cloud service providers and compliant payment gateways for processing subscription payments. '
          'All third-party data processors are bound by strict Data Protection Agreements (DPAs) and confidentiality obligations.',
      bullets: [
        'Geographically redundant cloud backups with automated failover replication',
        'PCI-DSS compliant payment tokenization for SaaS recurring subscriptions',
        'Strict DPAs ensuring third parties cannot access unencrypted tenant ledgers',
      ],
    ),
    _PolicySection(
      index: '05',
      id: 'cookies_storage',
      category: 'Storage',
      title: 'Local Storage, Security Tokens & Preferences',
      icon: Icons.cookie_rounded,
      highlight: 'Secure HTTP-Only Tokens & Zero Ad Trackers',
      content:
          'The platform uses secure HTTP-only session cookies and local storage tokens strictly for user authentication, '
          'theme preferences, and caching frequently referenced master records to optimize performance.',
      bullets: [
        'JWT bearer authentication tokens with short expiration lifespans',
        'Local encrypted device cache for offline-resilient master data lookups',
        'Zero tracking pixels, ad cookies, or third-party behavioral analytics',
      ],
    ),
    _PolicySection(
      index: '06',
      id: 'data_rights',
      category: 'Portability',
      title: 'User Privacy Rights & Full Data Portability',
      icon: Icons.file_download_rounded,
      highlight: '1-Click Full Data Export • Permanent Deletion Safeguards',
      content:
          'Your organization maintains full control over its data. Administrators may export complete historical ledgers, '
          'sales invoices, customer records, and product inventory tables in JSON or CSV formats at any time via the Import/Export module. '
          'You may also request permanent data deletion upon termination of services.',
      bullets: [
        'Instant unrestricted export in standard spreadsheet (CSV) and JSON formats',
        'Right to rectify, correct, or anonymize past customer record profiles',
        '30-day post-cancellation grace period before cryptographic zero-wipe',
      ],
    ),
    _PolicySection(
      index: '07',
      id: 'retention',
      category: 'Compliance',
      title: 'Statutory Retention & Regulatory Audits',
      icon: Icons.history_toggle_off_rounded,
      highlight: '7-Year Statutory Tax Record Alignment',
      content:
          'Financial records are maintained in accordance with standard statutory tax audit requirements for a default period of 7 years '
          'unless you explicitly request earlier expungement following account closure. De-identified operational metrics may be retained for capacity planning.',
      bullets: [
        'Automated archival retention schedules aligned with GST & Income Tax laws',
        'Option for custom enterprise retention period policies upon request',
        'Secure cryptographic erasure upon verified end-of-lifecycle notices',
      ],
    ),
    _PolicySection(
      index: '08',
      id: 'dpo_contact',
      category: 'Grievance',
      title: 'Data Protection Officer (DPO) & Redressal',
      icon: Icons.contact_support_rounded,
      highlight: 'Dedicated Redressal Team • < 24 Hour Response SLA',
      content:
          'If you have questions about privacy rights, GDPR/DPDP compliance, or wish to report a security incident, '
          'please contact our Data Protection Officer at privacy@platform.com or through the in-app support channel.',
      bullets: [
        'Official email desk: privacy@platform.com',
        'Dedicated compliance officer assigned to enterprise accounts',
        'Formal incident response and grievance redressal within 24 business hours',
      ],
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
      final matchesCategory = _selectedCategory == 'All' ||
          section.category == _selectedCategory;

      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return section.title.toLowerCase().contains(query) ||
          section.content.toLowerCase().contains(query) ||
          section.category.toLowerCase().contains(query) ||
          section.highlight.toLowerCase().contains(query) ||
          section.bullets.any((b) => b.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF070E1B) : const Color(0xFFF4F7FB),
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
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroBanner(isDark: isDark, isMobile: isMobile),
                      const SizedBox(height: 16),
                      _buildPrivacyPillars(isDark: isDark, screenWidth: screenWidth),
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
                      const SizedBox(height: 12),
                      _buildCategoryChips(isDark: isDark),
                      const SizedBox(height: 16),
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
                      _buildUserRightsGrid(isDark: isDark, screenWidth: screenWidth),
                      const SizedBox(height: 16),
                      _buildSecurityGuaranteeCard(
                        context: context,
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        primaryText: primaryText,
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
        borderRadius: BorderRadius.circular(isMobile ? 16 : 22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B),
            Color(0xFF047857),
            Color(0xFF0D9488),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.35),
            blurRadius: isMobile ? 16 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 18 : 24,
      ),
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
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'ZERO-TRUST PRIVACY FRAMEWORK',
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6EE7B7).withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 11, color: Color(0xFF6EE7B7)),
                    SizedBox(width: 5),
                    Text(
                      'DPDP 2023 & GDPR Aligned',
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
            'Privacy & Data Security Policy',
            style: TextStyle(
              fontSize: isMobile ? 20 : 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'How we safeguard your business financial records, customer registries, tax ledgers, and transaction vaults with cryptographic isolation and zero-monetization guarantees.',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13.5,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          SizedBox(height: isMobile ? 10 : 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPillBadge('AES-256 In-Rest', Icons.lock_outline, isMobile),
              _buildPillBadge('Cryptographic Multi-Tenancy', Icons.domain_verification_rounded, isMobile),
              _buildPillBadge('No Commercial Data Sale', Icons.block_rounded, isMobile),
              _buildPillBadge('100% Export Freedom', Icons.file_download_outlined, isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String label, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 7 : 9,
        vertical: isMobile ? 2.5 : 3.5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 11 : 12, color: const Color(0xFF6EE7B7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPillars({required bool isDark, required double screenWidth}) {
    final pillars = [
      _PillarItem(
        icon: Icons.shield_rounded,
        title: 'Zero Data Sale',
        description: 'Your business ledgers & clients are never monetized or shared.',
        color: const Color(0xFF10B981),
      ),
      _PillarItem(
        icon: Icons.enhanced_encryption_rounded,
        title: 'AES-256 Vaults',
        description: 'Military-grade encryption at rest with TLS 1.3 transport security.',
        color: const Color(0xFF0EA5E9),
      ),
      _PillarItem(
        icon: Icons.dns_rounded,
        title: 'Row Isolation',
        description: 'Guaranteed database-level separation across multi-tenant domains.',
        color: const Color(0xFF8B5CF6),
      ),
      _PillarItem(
        icon: Icons.cloud_download_rounded,
        title: 'Full Export Portability',
        description: 'Download 100% of your business data in standard CSV/JSON anytime.',
        color: const Color(0xFFF59E0B),
      ),
    ];

    final isVeryNarrow = screenWidth < 460;
    final isTabletOrMobile = screenWidth < 740;
    final count = isVeryNarrow ? 1 : (isTabletOrMobile ? 2 : 4);
    final cardWidth = (screenWidth - (count - 1) * 10 - (screenWidth < 600 ? 24 : 48)) / count;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pillars
          .map(
            (p) => SizedBox(
              width: cardWidth.clamp(140.0, 500.0),
              child: _buildPillarCard(p, isDark),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPillarCard(_PillarItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
              ? 'Search encryption, GST, privacy...'
              : 'Search privacy practices, data isolation, encryption, GST records...',
          hintStyle: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF059669),
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isMobile ? '$matchCount/$totalCount' : '$matchCount / $totalCount matched',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
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

  Widget _buildCategoryChips({required bool isDark}) {
    final categories = [
      'All',
      'Data Types',
      'Processing',
      'Security',
      'Infrastructure',
      'Storage',
      'Portability',
      'Compliance',
      'Grievance',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF059669)
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF059669)
                        : (isDark ? Colors.white10 : Colors.transparent),
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionCard({
    required _PolicySection section,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
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
                      const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF0D9488)],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: isMobile ? 13.5 : 15,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        section.highlight,
                        style: TextStyle(
                          fontSize: isMobile ? 10.5 : 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    section.category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.content,
                  style: TextStyle(
                    fontSize: isMobile ? 12.5 : 13.5,
                    height: 1.55,
                    color: secondaryText,
                  ),
                ),
                if (section.bullets.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: section.bullets.map((bullet) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: TextStyle(
                                    fontSize: isMobile ? 11.5 : 12.5,
                                    height: 1.4,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRightsGrid({required bool isDark, required double screenWidth}) {
    final rights = [
      _RightItem(
        title: 'Right to Access',
        description: 'Examine all logged customer and financial records.',
        icon: Icons.visibility_outlined,
      ),
      _RightItem(
        title: 'Right to Rectify',
        description: 'Correct inaccuracies in ledgers, items, or user profiles.',
        icon: Icons.edit_note_rounded,
      ),
      _RightItem(
        title: 'Right to Portability',
        description: 'Export complete datasets in JSON/CSV at any time.',
        icon: Icons.file_download_outlined,
      ),
      _RightItem(
        title: 'Right to Erasure',
        description: 'Request permanent tenant cryptographic deletion.',
        icon: Icons.delete_outline_rounded,
      ),
    ];

    final isNarrow = screenWidth < 640;

    return Container(
      padding: EdgeInsets.all(isNarrow ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  size: 18,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Fundamental Data Subject Rights',
                  style: TextStyle(
                    fontSize: isNarrow ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - (isNarrow ? 0 : 10)) /
                  (isNarrow ? 1 : 2);
              return Wrap(
                spacing: 10,
                runSpacing: 8,
                children: rights.map((r) {
                  return SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0B1220)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(r.icon, size: 18, color: const Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 1.5),
                                Text(
                                  r.description,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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
              'No matching privacy clauses found',
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

  Widget _buildSecurityGuaranteeCard({
    required BuildContext context,
    required bool isDark,
    required Color surface,
    required Color border,
    required Color primaryText,
    required Color mutedText,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 20,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Official Privacy & DPO Redressal Desk',
                  style: TextStyle(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  'Our certified Data Protection Officers continuously audit platform security. For compliance queries, statutory reports, or grievance redressal, email privacy@platform.com.',
                  style: TextStyle(
                    fontSize: isMobile ? 11.5 : 12.5,
                    color: mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    AppFeedback.showSnackbar(
                      context,
                      message: 'Data Protection Officer email: privacy@platform.com',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail_outline_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isMobile ? 'Email DPO (privacy@platform.com)' : 'Contact DPO Desk (privacy@platform.com)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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

class _PolicySection {
  final String index;
  final String id;
  final String category;
  final String title;
  final IconData icon;
  final String highlight;
  final String content;
  final List<String> bullets;

  const _PolicySection({
    required this.index,
    required this.id,
    required this.category,
    required this.title,
    required this.icon,
    required this.highlight,
    required this.content,
    required this.bullets,
  });
}

class _PillarItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _PillarItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _RightItem {
  final String title;
  final String description;
  final IconData icon;

  _RightItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
