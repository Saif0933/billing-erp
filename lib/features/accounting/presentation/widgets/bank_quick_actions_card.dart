import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_bank_account_dialog.dart';

class BankQuickActionsCard extends ConsumerWidget {
  const BankQuickActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Action Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              final tileWidth = isSmall
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 32) / 5;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 1. Add Bank Account
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.add_circle,
                      iconColor: const Color(0xFF16A34A),
                      title: 'Add Bank Account',
                      subtitle: 'Create new account',
                      onTap: () => AddBankAccountDialog.show(context),
                      isDark: isDark,
                    ),
                  ),

                  // 2. Bank Reconciliation
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFF9333EA),
                      title: 'Bank Reconciliation',
                      subtitle: 'Reconcile statements',
                      onTap: () {},
                      isDark: isDark,
                    ),
                  ),

                  // 3. Import Statement
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.file_upload_outlined,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Import Statement',
                      subtitle: 'Upload bank statement',
                      onTap: () {},
                      isDark: isDark,
                    ),
                  ),

                  // 4. Cheque Register
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.credit_card_outlined,
                      iconColor: const Color(0xFFEA580C),
                      title: 'Cheque Register',
                      subtitle: 'Manage cheques',
                      onTap: () {},
                      isDark: isDark,
                    ),
                  ),

                  // 5. Account Reports
                  SizedBox(
                    width: tileWidth,
                    child: _buildActionTile(
                      icon: Icons.assessment_outlined,
                      iconColor: const Color(0xFF0D9488),
                      title: 'Account Reports',
                      subtitle: 'View reports',
                      onTap: () {},
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
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
