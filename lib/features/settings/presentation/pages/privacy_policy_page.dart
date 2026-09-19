import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/layouts/widgets/public_legal_top_header.dart';
import '../../../../shared/widgets/feedback.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final List<_PolicySection> _sections = const [
    _PolicySection(
      index: '01',
      id: 'overview',
      category: 'Overview',
      title: 'Privacy Commitment & Scope of Tax Bunny',
      icon: Icons.shield_rounded,
      highlight: 'Strict Zero-Monetization • DPDP 2023 & GDPR Aligned',
      content:
          'Tax Bunny ("We", "Our", "Us", or "Platform") is committed to safeguarding the privacy, financial records, and operational data '
          'of all our business users, small retail merchants, shopkeepers, service providers, freelancers, and enterprise organizations. '
          'This Privacy Policy explains how Tax Bunny collects, uses, stores, secures, and handles information across our multi-tenant SaaS '
          'billing, POS counter, inventory management, customer ledger (Khata), and accounting software on Android, iOS, and Web platforms.',
      bullets: [
        'Multi-Tenant Architecture: Designed for both Non-GST businesses (small shops, service providers) and GST-registered merchants.',
        'No GST Mandatory: Having a GST registration is NOT required to use Tax Bunny; non-GST users can freely issue non-tax bills, estimates, cash receipts, and manage stock.',
        'Multi-Tenant Data Privacy: Complete tenant data isolation, isolated organization vaults, and zero ad tracking.',
        'Strict Zero-Monetization: We NEVER sell, rent, trade, or monetize your personal, customer, or financial records to third parties.',
      ],
    ),
    _PolicySection(
      index: '02',
      id: 'auth_credentials',
      category: 'Authentication',
      title: 'Platform Admin & Organization Login (Email & Password)',
      icon: Icons.vpn_key_rounded,
      highlight: 'Bcrypt Hashing • JWT Bearer Tokens • Zero Plaintext Storage',
      content:
          'Tax Bunny utilizes secure Email and Password authentication for both Platform Administrators and Organization Users. '
          'Platform Administrators provision subscribed organizations and issue initial authorized Organization Login credentials (Email & Password).',
      bullets: [
        'Secure Password Hashing: All passwords are cryptographically salted and hashed using irreversible one-way hashing algorithms (such as bcrypt/Argon2). Plaintext passwords are NEVER stored or visible to Platform Admins or employees.',
        'Session Security: Authenticated sessions use industry-standard JSON Web Tokens (JWT) transmitted strictly over encrypted TLS 1.3 HTTPS channels with automated token expiry.',
        'Role-Based Staff Access (RBAC): Organization Admins can provision and control staff sub-logins (Cashiers, Accountants, Managers) within their isolated tenant space.',
        'Zero Cross-Tenant Leakage: Organization credentials grant access strictly to that specific organization\'s database vault; no tenant can access or view another organization\'s workspace.',
      ],
    ),
    _PolicySection(
      index: '03',
      id: 'collection_data',
      category: 'Data Types',
      title: 'Information We Collect & Ingestion Scope',
      icon: Icons.data_usage_rounded,
      highlight: 'Store Profile, Invoices, Customer Registries & Inventory',
      content:
          'To deliver billing, POS counter sales, invoicing, and accounting features, Tax Bunny processes business and transactional data provided '
          'directly by you as well as technical diagnostics necessary for cloud synchronization.',
      bullets: [
        'Store & Business Profile: Store/shop name, business name, owner name, login email, contact phone number, address, and optional GSTIN/PAN (only if entered).',
        'Customer & Vendor Directory: Customer name, phone number, billing/shipping address, customer ledger balances, and credit/debit records (Khata).',
        'Invoicing & Financial Data: Sales bills, quotations, purchase records, item catalogs, optional tax rates (for GST users) or zero-tax items (for Non-GST users), and payment modes (Cash, UPI ID reference, Cheque, Bank Transfer).',
        // 'Subscription & Payment Info: Optional transaction references generated via compliant gateways (Tax Bunny never stores raw credit/debit card numbers or banking PINs).',
        'Device & Diagnostic Data: Device model, operating system version, Firebase installation token (for push alerts), IP address, and crash reports.',
      ],
    ),
    _PolicySection(
      index: '04',
      id: 'permissions',
      category: 'Permissions',
      title: 'Android Device Permissions & Hardware Usage Disclosures',
      icon: Icons.phonelink_lock_rounded,
      highlight: 'Camera, Storage, Notifications & Hardware Integrations',
      content:
          'To deliver core point-of-sale, thermal printing, and barcode scanning features, Tax Bunny requests specific device permissions. '
          'Each permission is strictly utilized for functional business tasks as detailed below:',
      bullets: [
        'Camera (android.permission.CAMERA): Used strictly for scanning product barcodes/QR codes in the POS/Billing screen and capturing photos of physical receipts, invoices, or product images. No biometric, facial recognition, or unauthorized background capture is ever performed.',
        'Storage & Media Access (Photos/Files): Used to allow you to upload your business logo, save generated PDF invoices to your device, import/export CSV/Excel/JSON spreadsheets, and share invoice receipts.',
        'Push Notifications (android.permission.POST_NOTIFICATIONS): Used to deliver real-time operational alerts, such as low inventory stock warnings, invoice payment reminders, and security alerts via Firebase Cloud Messaging.',
        'Internet & Network State (INTERNET, ACCESS_NETWORK_STATE): Used to securely synchronize your billing data with cloud databases, verify active network connections, and enable multi-device sync.',
        'Vibration (android.permission.VIBRATE): Used solely to provide tactile haptic confirmation when a barcode or QR code is successfully scanned.',
      ],
    ),
    _PolicySection(
      index: '05',
      id: 'usage_processing',
      category: 'Processing',
      title: 'How We Use Your Data & Zero Ad-Targeting Guarantee',
      icon: Icons.settings_suggest_rounded,
      highlight:
          '100% Functional Billing Processing • Zero Advertising Trackers',
      content:
          'Your data is processed solely to operate the Tax Bunny platform, generate standard bills, maintain customer credit balances, '
          'and provide real-time business reports. We do not engage in behavioural advertising, ad retargeting, or commercial data selling.',
      bullets: [
        'Generating non-tax retail bills, estimates, cash memos, or GST-compliant tax invoices depending on user preference.',
        'Calculating real-time bill totals, discounts, customer outstanding balances (Khata), and inventory stock balances.',
        'Enforcing Role-Based Access Control (RBAC) across your staff (Admins, Cashiers, Accountants).',
        'Managing multi-device synchronization and offline-to-cloud data caching.',
        'Delivering critical product updates, system alerts, and customer support assistance.',
      ],
    ),
    _PolicySection(
      index: '06',
      id: 'security_encryption',
      category: 'Security',
      title: 'Cryptographic Security & Multi-Tenant Data Isolation',
      icon: Icons.enhanced_encryption_rounded,
      highlight:
          'AES-256 at Rest • TLS 1.3 in Transit • Row-Level Tenant Isolation',
      content:
          'We implement enterprise-grade security architectures to protect your financial and business data against unauthorized access, '
          'alteration, disclosure, or destruction.',
      bullets: [
        'Data Encryption: All sensitive data is encrypted at rest using AES-256 encryption and in transit using modern TLS 1.3 cryptographic protocols.',
        'Tenant Isolation: Logical row-level and organization-level database isolation guarantees that no other tenant or external organization can view or access your business records.',
        'Immutable Audit Trails: State-altering financial and ledger modifications are logged with user identity and timestamps to prevent fraudulent manipulation.',
        'Automated Cloud Backups: Geo-redundant continuous database backups to prevent accidental data loss.',
      ],
    ),
    _PolicySection(
      index: '07',
      id: 'third_party_processors',
      category: 'Third Party',
      title: 'Third-Party Service Providers & Cloud Hosting',
      icon: Icons.cloud_queue_rounded,
      highlight: 'Certified SOC 2 & ISO 27001 Cloud Infrastructure',
      content:
          'Tax Bunny partners with trusted, industry-standard third-party service providers to deliver cloud hosting and push notifications.',
      bullets: [
        'Google Firebase: Used for Firebase Cloud Messaging (push notifications) and crash reporting. Bound by Google\'s enterprise data privacy terms.',
        // 'Payment Gateways: Processed via certified secure channels. Tax Bunny never stores raw credit/debit card numbers, CVVs, or net-banking passwords.',
        'Data Processing Agreements (DPAs): All third parties are legally prohibited from utilizing your business records for any purpose other than providing contracted infrastructure services.',
      ],
    ),
    _PolicySection(
      index: '08',
      id: 'data_retention_deletion',
      category: 'Account & Deletion',
      title: 'Account Deletion, Data Portability & Retention Policy',
      icon: Icons.delete_forever_rounded,
      highlight: 'Self-Serve In-App Deletion & Direct Email Deletion Support',
      content:
          'In full compliance with Google Play Store policies and international data privacy regulations, Tax Bunny provides clear and '
          'accessible mechanisms for data export, account deletion, and permanent data erasure.',
      bullets: [
        'Full Data Portability: You may export your entire business transaction history, customer registers, inventory lists, and ledgers in CSV, Excel, PDF, or JSON formats at any time without fees.',
        'In-App Account Deletion: You can initiate account deletion directly from the mobile app by navigating to Settings > Business Profile > Delete Account.',
        'Direct Email Deletion Request: You can also request complete account and data deletion by emailing samsaif933@gmail.com or calling +91 9334804356 with the subject "Delete My Tax Bunny Account".',
        'Deletion Timeline & Purging: Upon verified deletion request, your account is immediately deactivated, and all associated tenant records, customer registries, and transaction logs are permanently purged from active production servers within 30 days.',
      ],
    ),
    _PolicySection(
      index: '09',
      id: 'user_rights',
      category: 'User Rights',
      title: 'Your Data Protection Rights (GDPR / DPDP 2023)',
      icon: Icons.verified_user_rounded,
      highlight: 'Right to Access, Rectify, Restrict, Port & Erase',
      content:
          'Regardless of your geographic location, Tax Bunny guarantees the following fundamental data privacy rights for all users:',
      bullets: [
        'Right to Access: Request a copy of all personal and business data associated with your user account.',
        'Right to Rectification: Modify or update inaccurate business names, tax details, or contact information directly in the App.',
        'Right to Erasure (Right to be Forgotten): Request permanent deletion of your account and records as outlined in Section 08.',
        'Right to Restriction & Objection: Restrict specific non-essential data processing activities or withdraw consent at any time.',
      ],
    ),
    _PolicySection(
      index: '10',
      id: 'children_privacy',
      category: 'Children',
      title: 'Children\'s Privacy Protection (COPPA Compliance)',
      icon: Icons.family_restroom_rounded,
      highlight: 'Business Commercial Software • Age 18+ Verification',
      content:
          'Tax Bunny is an enterprise billing, POS, and financial accounting platform designed strictly for commercial enterprises, '
          'registered businesses, shopkeepers, and adults aged 18 and above. We do NOT knowingly collect or solicit personal information from children '
          'under 13 (or under 16/18 where applicable by local law).',
      bullets: [
        'Our service is not directed to children under 13.',
        'If we become aware that personal information of a child under 13 has been collected without verified parental consent, we will take immediate steps to expunge such data from our databases.',
        'Parents or guardians who believe their child has provided data to Tax Bunny may contact samsaif933@gmail.com for immediate removal.',
      ],
    ),
    _PolicySection(
      index: '11',
      id: 'policy_updates_contact',
      category: 'Contact & DPO',
      title: 'Developer Contact, Grievance Officer & Help Desk',
      icon: Icons.contact_support_rounded,
      highlight: 'Official Developer Support • < 24-48 Hour Response SLA',
      content:
          'We may periodically update this Privacy Policy to reflect enhancements in our application or statutory regulatory requirements. '
          'Any updates will be posted on this screen with a revised effective date.',
      bullets: [
        'Official Developer & Support Email: samsaif933@gmail.com',
        'Official Support Helpline: +91 9334804356',
        'Grievance Redressal: Inquiries, data privacy requests, and compliance queries are resolved within 24 to 48 business hours.',
        'App Developer / Publisher: Tax Bunny (Contact: samsaif933@gmail.com).',
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
          ? const Color(0xFF070E1B)
          : const Color(0xFFF4F7FB),
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
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroBanner(isDark: isDark, isMobile: isMobile),
                      const SizedBox(height: 16),
                      _buildPrivacyPillars(
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
                      _buildUserRightsGrid(
                        isDark: isDark,
                        screenWidth: screenWidth,
                      ),
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
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0D9488)],
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
                          'TAX BUNNY PRIVACY POLICY',
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6EE7B7).withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 11,
                      color: Color(0xFF6EE7B7),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Google Play & DPDP 2023 Compliant',
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
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How Tax Bunny protects your organization credentials, store ledgers, customer registries, non-GST/GST bills, and business operational data with AES-256 cryptographic vaults and zero-monetization guarantees.',
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
                'Encrypted Credentials',
                Icons.vpn_key_rounded,
                isMobile,
              ),
              _buildPillBadge(
                'Zero Data Selling',
                Icons.block_rounded,
                isMobile,
              ),
              _buildPillBadge(
                'Tenant Isolation',
                Icons.domain_verification_rounded,
                isMobile,
              ),
              _buildPillBadge(
                'Instant Account Deletion',
                Icons.delete_sweep_rounded,
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

  Widget _buildPrivacyPillars({
    required bool isDark,
    required double screenWidth,
  }) {
    final pillars = [
      _PillarItem(
        icon: Icons.vpn_key_rounded,
        title: 'Encrypted Credentials',
        description:
            'Passwords hashed with one-way bcrypt; never stored in plaintext.',
        color: const Color(0xFF10B981),
      ),
      _PillarItem(
        icon: Icons.enhanced_encryption_rounded,
        title: 'AES-256 Vaults',
        description:
            'Military-grade encryption at rest with TLS 1.3 transport security.',
        color: const Color(0xFF0EA5E9),
      ),
      _PillarItem(
        icon: Icons.dns_rounded,
        title: 'Tenant Isolation',
        description:
            'Guaranteed database-level separation across multi-tenant domains.',
        color: const Color(0xFF8B5CF6),
      ),
      _PillarItem(
        icon: Icons.cloud_download_rounded,
        title: 'Full Export Freedom',
        description:
            'Download 100% of your business data in standard CSV/Excel/JSON anytime.',
        color: const Color(0xFFF59E0B),
      ),
    ];

    final isVeryNarrow = screenWidth < 460;
    final isTabletOrMobile = screenWidth < 740;
    final count = isVeryNarrow ? 1 : (isTabletOrMobile ? 2 : 4);
    final cardWidth =
        (screenWidth - (count - 1) * 10 - (screenWidth < 600 ? 24 : 48)) /
        count;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
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

  Widget _buildUserRightsGrid({
    required bool isDark,
    required double screenWidth,
  }) {
    final rights = [
      _RightItem(
        title: 'Right to Access',
        description:
            'Review all logged customer profiles, stock catalogs, and financial records.',
        icon: Icons.visibility_outlined,
      ),
      _RightItem(
        title: 'Right to Rectify',
        description:
            'Correct inaccuracies in ledgers, items, tax numbers, or user profiles.',
        icon: Icons.edit_note_rounded,
      ),
      _RightItem(
        title: 'Right to Portability',
        description:
            'Export complete datasets in JSON/CSV/PDF at any time without fees.',
        icon: Icons.file_download_outlined,
      ),
      _RightItem(
        title: 'Right to Erasure',
        description:
            'Permanently delete your account and wipe all tenant databases.',
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
              final width =
                  (constraints.maxWidth - (isNarrow ? 0 : 10)) /
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
                          Icon(
                            r.icon,
                            size: 18,
                            color: const Color(0xFF059669),
                          ),
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
          color: isDark ? Colors.white12 : const Color(0xFFBBF7D0),
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
              Icons.contact_support_rounded,
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
                  'Tax Bunny Privacy & Developer Support Desk',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'For compliance inquiries, data deletion requests, or questions regarding Google Play Data Safety, contact our official support desk at samsaif933@gmail.com or call +91 9334804356.',
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
                          message:
                              'Developer Support Email: samsaif933@gmail.com',
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
                          message: 'Developer Helpline: +91 9334804356',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857),
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
