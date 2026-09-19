import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/layouts/widgets/public_legal_top_header.dart';
import '../../../../shared/widgets/feedback.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  final List<_TermsSection> _sections = const [
    _TermsSection(
      index: '01',
      id: 'acceptance',
      category: 'General',
      title: 'Preamble, Acceptance of Terms & Multi-Tenant SaaS Scope',
      icon: Icons.gavel_rounded,
      tag: 'Mandatory',
      content:
          'Welcome to Tax Bunny ("Service", "Application", "Platform", "We", "Us", or "Our"). '
          'These Terms & Conditions ("Terms") constitute a legally binding agreement between your business entity, retail shop, firm, freelancer practice, or organization '
          '("User", "Merchant", "Organization", "Account Holder", or "You") and Tax Bunny. Tax Bunny is a commercial multi-tenant '
          'cloud billing, Point of Sale (POS), inventory management, customer ledger (Khata), and invoicing platform. '
          'By accessing, registering, or using Tax Bunny, you agree to comply with and be bound by these Terms.',
      bullets: [
        'Applicable to all mobile applications, web portals, APIs, platform admin dashboards, and thermal printing utilities.',
        'Supports both Non-GST businesses (small shops, retail counters, service providers) and GST-registered commercial enterprises.',
        'Software provides comprehensive cloud-backed multi-tenant billing, inventory tracking, and POS invoicing features.',
        'You confirm that you possess full legal authority to bind your organization or business practice to these Terms.',
      ],
    ),
    _TermsSection(
      index: '02',
      id: 'platform_org_login',
      category: 'Account',
      title:
          'Platform Admin Provisioning & Organization Login (Email & Password)',
      icon: Icons.admin_panel_settings_rounded,
      tag: 'Authentication',
      content:
          'Tax Bunny operates under a secure dual-tier multi-tenant authentication architecture. '
          'Both Platform Administrators and Organization Users log into the system using verified Email and Password credentials. '
          'Platform Administrators manage tenant onboarding, workspace provisioning, and issue authorized master Organization Login credentials (Email & Password) '
          'to registered merchants.',
      bullets: [
        'Platform Admin Role: Manages overall system infrastructure, workspace provisioning, and issues the official Organization Administrator login credentials (Email & Password).',
        'Organization Tenant Login: Registered merchants and organizations access their dedicated, logically isolated workspace using the Email and Password provisioned and authorized by the Platform.',
        'Staff & Team Management (RBAC): Organization Admins can create sub-accounts with role-based permissions (Store Manager, Cashier, Accountant) within their tenant workspace.',
        'Credential Safeguards: Users are strictly responsible for maintaining password confidentiality. Passwords should be changed upon first login and never shared with unauthorized third parties.',
        'Prompt Security Reporting: If you suspect any compromise of your Organization login credentials, immediately contact support at samsaif933@gmail.com or +91 9334804356.',
      ],
    ),
    /*
    _TermsSection(
      index: '03',
      id: 'saas_subscription_sales',
      category: 'Subscriptions',
      title: 'Commercial SaaS Subscription Model, Plans & Sales Terms',
      icon: Icons.card_membership_rounded,
      tag: 'Commercial Sales',
      content:
          'Tax Bunny is commercial business software provided on a paid Subscription basis. Subscribers can select from flexible tiers '
          '(such as Free Trial, Monthly, Quarterly, Annual, or Custom Enterprise packages) to access platform features, cloud synchronization, '
          'multi-device support, POS counter sales, and thermal printer integrations.',
      bullets: [
        'Subscription Sales & Activation: Access to premium modules, multi-store support, and unlimited invoice generation is activated upon purchase of an active SaaS subscription plan.',
        'Billing Cycles & Advance Payment: Subscriptions are billed in advance on a recurring or term basis. Invoices and payment receipts are issued automatically for every transaction.',
        'Payment Gateways: Payments are processed securely via certified RBI and PCI-DSS compliant payment gateways (UPI, Cards, Net Banking). Tax Bunny never stores raw credit card CVVs or banking PINs.',
        'Upgrades & Downgrades: Organizations may upgrade to higher tiers or add additional store counters at any time with pro-rated billing adjustments.',
        'Fair Refund Policy: Annual subscription purchases are eligible for a 7-day money-back satisfaction guarantee; monthly subscriptions can be cancelled at any time without long-term lock-in.',
      ],
    ),
    */
    _TermsSection(
      index: '03',
      id: 'license_usage',
      category: 'License',
      title: 'Software License Grant, Permitted Use & IP Rights',
      icon: Icons.vpn_key_rounded,
      tag: 'License',
      content:
          'Subject to these Terms, Tax Bunny grants your organization a non-exclusive, non-transferable, revocable, worldwide license '
          'to access and use the platform for your internal commercial business operations. All software architecture, design, code, logos, and '
          'trademarks remain the exclusive intellectual property of Tax Bunny.',
      bullets: [
        'Permitted for commercial retail sales, non-GST/GST billing, stock management, quotations, customer khata ledgers, and thermal printing.',
        'You may not reverse engineer, decompile, disassemble, or extract source code from the Tax Bunny application.',
        'You may not resell, rent, sublicense, or distribute the Tax Bunny platform to third parties as a standalone white-label service without written authorization.',
        'Automated scraping, bot crawling, or stress-testing of Tax Bunny backend APIs is strictly prohibited.',
      ],
    ),
    _TermsSection(
      index: '04',
      id: 'gst_non_gst_compliance',
      category: 'Compliance',
      title: 'Non-GST & GST Invoicing, Tax Disclaimer & User Responsibility',
      icon: Icons.receipt_long_rounded,
      tag: 'Tax Disclaimer',
      content:
          'Tax Bunny is an independent business utility software designed to generate both Non-GST (regular retail bills, estimates, cash memos, bills of supply) '
          'and GST-compliant tax invoices. Having a GSTIN registration is NOT mandatory to use Tax Bunny. Tax Bunny does NOT act as a government entity, '
          'tax authority, chartered accountant, or legal tax consultant.',
      bullets: [
        'Non-GST Businesses: Small shopkeepers, local retailers, and service providers without a GST registration can issue simple non-tax bills, estimates, receipts, and maintain customer khata without entering any GSTIN.',
        'GST-Registered Businesses: Users who have a valid GSTIN can optionally configure GST rates (CGST, SGST, IGST), HSN/SAC codes, and print tax invoices.',
        'User Responsibility: The User retains sole legal responsibility for verifying tax applicability, turnover thresholds, invoice amounts, customer details, and filing mandatory returns with government tax departments if legally required.',
        'Tax Bunny shall not be held liable for any statutory penalties, tax assessments, or disputes arising from merchant data entry or tax classification decisions.',
      ],
    ),
    _TermsSection(
      index: '05',
      id: 'hardware_offline',
      category: 'Hardware',
      title: 'Hardware Integrations, Thermal Printers & Offline Mode Sync',
      icon: Icons.print_rounded,
      tag: 'Hardware',
      content:
          'Tax Bunny supports seamless integration with third-party thermal receipt printers (ESC/POS via Bluetooth/USB/Network), barcode scanners, '
          'and camera-based QR code readers. The application also provides offline-resilient billing capabilities.',
      bullets: [
        'Hardware compatibility depends on standard ESC/POS printer protocols and mobile device Bluetooth/USB drivers.',
        'Tax Bunny is not liable for third-party hardware failures, printer mechanism jams, or Bluetooth connection drops outside the app\'s control.',
        'Invoices generated during offline mode are stored securely in local device storage and must be synced to the cloud once an active internet connection is restored to maintain ledger consistency.',
      ],
    ),
    _TermsSection(
      index: '06',
      id: 'data_ownership',
      category: 'Data',
      title: '100% User Data Ownership & Unrestricted Portability',
      icon: Icons.folder_shared_rounded,
      tag: 'Ownership',
      content:
          'You retain 100% complete and exclusive ownership of all business records, item catalogs, customer databases, sales invoices, purchase logs, '
          'and financial transactions entered into your Tax Bunny workspace. Tax Bunny claims zero ownership or proprietary rights over your business data.',
      bullets: [
        'Your business data belongs exclusively to your organization at all times.',
        'You may export complete historical sales, inventory, ledgers, and customer lists in standard formats (CSV, Excel, PDF, JSON) at any time.',
        'We will never sell, lease, or monetize your customer records or trade secrets to third parties, competitors, or marketing brokers.',
      ],
    ),
    /*
    _TermsSection(
      index: '08',
      id: 'subscription_lifecycle_grace',
      category: 'Subscriptions',
      title: 'Subscription Expiry, Renewal Grace Period & Tenant Lifecycle',
      icon: Icons.timer_outlined,
      tag: 'Lifecycle',
      content:
          'When an organization subscription reaches its expiration date without renewal, Tax Bunny ensures business continuity with clear '
          'lifecycle protection standards.',
      bullets: [
        'Renewal Reminders: Automated notifications are sent via email and in-app alerts prior to subscription expiration.',
        '30-Day Read-Only Grace Period: Upon subscription expiry, your account enters a 30-day read-only grace period allowing you to view and download full data exports (CSV, Excel, PDF).',
        'Reactivation: Organizations can reactivate full billing capabilities immediately by renewing their subscription during or after the grace period.',
        'Tenant Decommissioning: Unrenewed workspaces may be archived and securely decommissioned after the 30-day grace period in accordance with statutory data retention standards.',
      ],
    ),
    */
    _TermsSection(
      index: '07',
      id: 'fair_use_prohibitions',
      category: 'Compliance',
      title: 'Fair Usage Policy & Prohibited Business Activities',
      icon: Icons.shield_outlined,
      tag: 'Acceptable Use',
      content:
          'You agree to use Tax Bunny strictly for lawful commercial, retail, or professional business purposes. Any misuse of the platform to conduct '
          'fraudulent transactions, issue fictitious invoices, or violate local laws is strictly prohibited and constitutes grounds for immediate termination.',
      bullets: [
        'No generation of fake, counterfeit, or unlawful financial records.',
        'No uploading of malicious software, spyware, viruses, or attempts to disrupt backend infrastructure.',
        'No infringement of third-party copyrights, trademarks, or personal privacy.',
        'Tax Bunny reserves the right to cooperate fully with statutory law enforcement agencies upon receipt of valid legal court orders.',
      ],
    ),
    _TermsSection(
      index: '08',
      id: 'sla_availability',
      category: 'SLA',
      title: 'Service Availability, 99.9% Target SLA & Maintenance',
      icon: Icons.cloud_done_rounded,
      tag: 'Service SLA',
      content:
          'We endeavor to maintain a 99.9% uptime availability for all cloud synchronization, reporting, and database storage servers. Scheduled maintenance '
          'is performed during off-peak business hours with advance notifications provided to administrators.',
      bullets: [
        'Continuous automated cloud backups with geo-redundant database replication.',
        'Tax Bunny is not liable for temporary service delays caused by national ISP outages, cloud infrastructure disruptions, or force majeure events.',
        'Critical security patches and platform bug fixes are rolled out seamlessly without requiring data migration on your part.',
      ],
    ),
    _TermsSection(
      index: '09',
      id: 'liability_disclaimer',
      category: 'Legal',
      title: 'Limitation of Liability & Statutory Warranty Disclaimers',
      icon: Icons.balance_rounded,
      tag: 'Liability',
      content:
          'To the maximum extent permitted by applicable law, Tax Bunny is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, '
          'either express or implied. Tax Bunny does not guarantee that the software will be completely error-free or uninterrupted at all times.',
      bullets: [
        'In no event shall Tax Bunny, its developers, employees, or affiliates be liable for indirect, incidental, special, punitive, or consequential damages.',
        'This includes any loss of business profits, customer goodwill, commercial stoppage, or penalties resulting from merchant data entry mistakes.',
        'Our aggregate legal liability under any claim arising out of these Terms shall not exceed ₹1,000 or the maximum extent permissible under applicable law.',
      ],
    ),
    _TermsSection(
      index: '10',
      id: 'termination_export_contact',
      category: 'Legal',
      title:
          'Account Deletion, Dispute Resolution & Official Developer Support',
      icon: Icons.contact_mail_rounded,
      tag: 'Support & Legal',
      content:
          'You have the right to delete your Tax Bunny account at any time either through the app or by submitting a written request to our developer support desk. '
          'These Terms shall be governed by applicable statutory laws, and disputes shall be resolved through mutual discussion before competent legal forums.',
      bullets: [
        'Official Developer Email: samsaif933@gmail.com',
        'Official Support Helpline: +91 9334804356',
        'Self-Serve Account Deletion: Settings > Business Profile > Delete Account (or email samsaif933@gmail.com).',
        'Support SLA: All inquiries, technical issues, and customer support requests are addressed within 24 to 48 business hours.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark
        ? AppColors.textDarkPrimary
        : AppColors.textLightPrimary;
    final secondaryText = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textLightSecondary;
    final mutedText = isDark
        ? AppColors.textDarkMuted
        : AppColors.textLightMuted;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF8FAFC),
      appBar: const PublicLegalTopHeader(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isMobile = screenWidth < 600;
            final isTablet = screenWidth >= 600 && screenWidth < 960;
            final horizontalPadding = isMobile
                ? 12.0
                : (isTablet ? 16.0 : 24.0);

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
                      _buildQuickHighlights(
                        isDark: isDark,
                        screenWidth: screenWidth,
                      ),
                      const SizedBox(height: 16),
                      ..._sections.map(
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
                        context: context,
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
        borderRadius: BorderRadius.circular(isMobile ? 16 : 22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                        Icon(
                          Icons.verified_user_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'TAX BUNNY SAAS AGREEMENT',
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
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                      'Active • Version 3.2',
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
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Master Application Agreement, Platform & Organization login credentials matrix, Non-GST & GST support, and 100% data ownership commitments.',
            style: TextStyle(
              fontSize: isMobile ? 12.5 : 14,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          SizedBox(height: isMobile ? 10 : 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPillBadge(
                'Email/Password Auth',
                Icons.vpn_key_rounded,
                isMobile,
              ),
              _buildPillBadge(
                'Cloud Sync & Khata',
                Icons.cloud_done_rounded,
                isMobile,
              ),
              _buildPillBadge(
                '100% Data Ownership',
                Icons.folder_shared_rounded,
                isMobile,
              ),
              _buildPillBadge(
                'Non-GST & GST Ready',
                Icons.receipt_long_rounded,
                isMobile,
              ),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 11 : 12, color: const Color(0xFFA5B4FC)),
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

  Widget _buildQuickHighlights({
    required bool isDark,
    required double screenWidth,
  }) {
    final highlights = [
      _HighlightItem(
        icon: Icons.vpn_key_rounded,
        title: 'Platform & Org Login',
        subtitle: 'Secure Email & Password Access',
        color: const Color(0xFF6366F1),
      ),
      _HighlightItem(
        icon: Icons.cloud_done_rounded,
        title: 'Cloud Sync & Khata',
        subtitle: 'Real-Time Ledger & Invoices',
        color: const Color(0xFF10B981),
      ),
      _HighlightItem(
        icon: Icons.storefront_rounded,
        title: 'Non-GST & GST Ready',
        subtitle: 'Works For All Business Types',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
        borderRadius: BorderRadius.circular(16),
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
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 16,
              12,
              isMobile ? 12 : 16,
              10,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7.5,
                    vertical: 3.5,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
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
                                  color: Color(0xFF4F46E5),
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

  Widget _buildFooterNotice({
    required BuildContext context,
    required bool isDark,
    required Color surface,
    required Color border,
    required Color mutedText,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFC7D2FE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.contact_support_rounded,
              size: 20,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tax Bunny Developer & Support Helpline',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'For legal agreements, tenant onboarding, or platform technical assistance, contact our developer desk at samsaif933@gmail.com or call +91 9334804356.',
                  style: TextStyle(
                    fontSize: isMobile ? 11.5 : 12.5,
                    color: mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        AppFeedback.showSnackbar(
                          context,
                          message: 'Email: samsaif933@gmail.com',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'samsaif933@gmail.com',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        AppFeedback.showSnackbar(
                          context,
                          message: 'Helpline: +91 9334804356',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '+91 9334804356',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
  final String category;
  final String title;
  final IconData icon;
  final String tag;
  final String content;
  final List<String> bullets;

  const _TermsSection({
    required this.index,
    required this.id,
    required this.category,
    required this.title,
    required this.icon,
    required this.tag,
    required this.content,
    required this.bullets,
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
