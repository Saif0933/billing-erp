import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  final _searchController = TextEditingController();

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
    final billingState = ref.watch(billingRepositoryProvider);

    final query = _searchController.text.toLowerCase();
    final filteredLogs = billingState.auditLogs.where((log) {
      return log.action.toLowerCase().contains(query) ||
          log.user.toLowerCase().contains(query) ||
          log.entity.toLowerCase().contains(query) ||
          log.entityId.toLowerCase().contains(query);
    }).toList();

    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final uniqueUsers = filteredLogs.map((e) => e.user).toSet().length;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(
                    context: context,
                    isDark: isDark,
                    secondaryText: secondaryText,
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 640;
                      final tiles = [
                        _MetricTile(
                          icon: Icons.history_rounded,
                          iconColor: const Color(0xFF0EA5E9),
                          label: 'Events',
                          value: '${filteredLogs.length}',
                          hint: 'Matching current search',
                          isDark: isDark,
                          surface: surface,
                          border: border,
                        ),
                        _MetricTile(
                          icon: Icons.people_alt_outlined,
                          iconColor: const Color(0xFF10B981),
                          label: 'Operators',
                          value: '$uniqueUsers',
                          hint: 'Unique users in trail',
                          isDark: isDark,
                          surface: surface,
                          border: border,
                        ),
                        _MetricTile(
                          icon: Icons.schedule_outlined,
                          iconColor: const Color(0xFFF59E0B),
                          label: 'Latest activity',
                          value: filteredLogs.isEmpty
                              ? '—'
                              : DateFormat('dd MMM, HH:mm')
                                  .format(filteredLogs.first.timestamp),
                          hint: 'Most recent change',
                          isDark: isDark,
                          surface: surface,
                          border: border,
                        ),
                      ];
                      if (narrow) {
                        return Column(
                          children: [
                            for (var i = 0; i < tiles.length; i++) ...[
                              tiles[i],
                              if (i < tiles.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (var i = 0; i < tiles.length; i++) ...[
                            Expanded(child: tiles[i]),
                            if (i < tiles.length - 1)
                              const SizedBox(width: 12),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style:
                          AppTypography.bodyMedium.copyWith(color: primaryText),
                      decoration: InputDecoration(
                        hintText: 'Search by user, action, or entity',
                        hintStyle: AppTypography.bodyMedium
                            .copyWith(color: mutedText),
                        prefixIcon: Icon(Icons.search_rounded, color: mutedText),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.close, color: mutedText, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ACTIVITY TRAIL',
                        style: AppTypography.labelLarge.copyWith(
                          color: mutedText,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${filteredLogs.length} records',
                        style: AppTypography.bodySmall.copyWith(color: mutedText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filteredLogs.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF064E3B)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              size: 28,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No matching activity',
                            style: AppTypography.titleMedium.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different user, action, or entity.',
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: [
                          for (var i = 0; i < filteredLogs.length; i++)
                            _AuditRow(
                              log: filteredLogs[i],
                              dateLabel:
                                  dateFormat.format(filteredLogs[i].timestamp),
                              primaryText: primaryText,
                              mutedText: mutedText,
                              isDark: isDark,
                              isLast: i == filteredLogs.length - 1,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required bool isDark,
    required Color secondaryText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
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
                'Security Audit Trail',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Review operator actions across invoices, ledger, and configuration',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String hint;
  final bool isDark;
  final Color surface;
  final Color border;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.hint,
    required this.isDark,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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

class _AuditRow extends StatelessWidget {
  final AuditLogEntry log;
  final String dateLabel;
  final Color primaryText;
  final Color mutedText;
  final bool isDark;
  final bool isLast;

  const _AuditRow({
    required this.log,
    required this.dateLabel,
    required this.primaryText,
    required this.mutedText,
    required this.isDark,
    required this.isLast,
  });

  Color get _accent {
    final a = log.action.toLowerCase();
    if (a.contains('delete') || a.contains('remove')) return AppColors.error;
    if (a.contains('create') || a.contains('add')) return AppColors.success;
    if (a.contains('update') || a.contains('edit') || a.contains('change')) {
      return AppColors.info;
    }
    return AppColors.accent;
  }

  IconData get _icon {
    final a = log.action.toLowerCase();
    if (a.contains('delete') || a.contains('remove')) {
      return Icons.delete_outline;
    }
    if (a.contains('create') || a.contains('add')) {
      return Icons.add_circle_outline;
    }
    if (a.contains('update') || a.contains('edit') || a.contains('change')) {
      return Icons.edit_outlined;
    }
    return Icons.history;
  }

  String get _chip {
    final a = log.action.toLowerCase();
    if (a.contains('delete') || a.contains('remove')) return 'DELETE';
    if (a.contains('create') || a.contains('add')) return 'CREATE';
    if (a.contains('update') || a.contains('edit') || a.contains('change')) {
      return 'UPDATE';
    }
    return 'EVENT';
  }

  @override
  Widget build(BuildContext context) {
    final initial = log.user.isNotEmpty ? log.user[0].toUpperCase() : '?';
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 8 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, size: 18, color: _accent),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDark
                          ? Colors.white12
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 4 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.action,
                            style: AppTypography.titleMedium.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _chip,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: _accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              log.user,
                              style: AppTypography.bodySmall.copyWith(
                                color: primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text('·', style: TextStyle(color: mutedText)),
                        Text(
                          '${log.entity}  ${log.entityId}',
                          style: AppTypography.bodySmall.copyWith(
                            color: mutedText,
                          ),
                        ),
                        Text('·', style: TextStyle(color: mutedText)),
                        Text(
                          dateLabel,
                          style: AppTypography.bodySmall.copyWith(
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    if (log.previousValue.isNotEmpty ||
                        log.newValue.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (log.previousValue.isNotEmpty)
                            _ValuePill(
                              label: 'Before',
                              value: log.previousValue,
                              isDark: isDark,
                            ),
                          if (log.previousValue.isNotEmpty &&
                              log.newValue.isNotEmpty)
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: mutedText,
                            ),
                          if (log.newValue.isNotEmpty)
                            _ValuePill(
                              label: 'After',
                              value: log.newValue,
                              isDark: isDark,
                              highlight: true,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _ValuePill({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? (isDark
                ? const Color(0xFF064E3B)
                : const Color(0xFFECFDF5))
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: highlight
                  ? AppColors.accent
                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
