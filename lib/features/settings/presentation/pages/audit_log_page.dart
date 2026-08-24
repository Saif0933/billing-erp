import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
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
    final billingState = ref.watch(billingRepositoryProvider);

    final query = _searchController.text.toLowerCase();
    final filteredLogs = billingState.auditLogs.where((log) {
      return log.action.toLowerCase().contains(query) ||
          log.user.toLowerCase().contains(query) ||
          log.entity.toLowerCase().contains(query) ||
          log.entityId.toLowerCase().contains(query);
    }).toList();

    // Sort audit logs descending by timestamp
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(title: const Text('Security & Operational Audit Trails')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Search logs by user, action, or target entity',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: AppTable<AuditLogEntry>(
                items: filteredLogs,
                emptyMessage: 'No audit logs matched search criteria.',
                columns: [
                  TableColumnSpec<AuditLogEntry>(
                    label: 'Timestamp',
                    cellBuilder: (log) => Text(
                      '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} '
                      '${log.timestamp.toLocal().toString().substring(11, 19)}',
                    ),
                  ),
                  TableColumnSpec<AuditLogEntry>(
                    label: 'Operator / User',
                    cellBuilder: (log) => Text(log.user, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  TableColumnSpec<AuditLogEntry>(
                    label: 'Action Performed',
                    flex: 2,
                    cellBuilder: (log) => Text(log.action),
                  ),
                  TableColumnSpec<AuditLogEntry>(
                    label: 'Target',
                    cellBuilder: (log) => Text('${log.entity} [${log.entityId}]'),
                  ),
                  TableColumnSpec<AuditLogEntry>(
                    label: 'Previous Value',
                    flex: 2,
                    cellBuilder: (log) => Text(
                      log.previousValue.isEmpty ? 'N/A' : log.previousValue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ),
                  TableColumnSpec<AuditLogEntry>(
                    label: 'New Mutated Value',
                    flex: 2,
                    cellBuilder: (log) => Text(
                      log.newValue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
