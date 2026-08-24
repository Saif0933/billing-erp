import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'salesUser';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showInviteUserDialog() {
    _nameController.clear();
    _emailController.clear();
    _selectedRole = 'salesUser';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Invite Team Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Full Name *',
                controller: _nameController,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email Address *',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<String>(
                label: 'Default Access Role *',
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(
                      value: 'owner', child: Text('Owner (Full Admin Access)')),
                  DropdownMenuItem(
                      value: 'admin', child: Text('Manager / Administrator')),
                  DropdownMenuItem(
                      value: 'accountant',
                      child: Text('Accountant (Finance & GST)')),
                  DropdownMenuItem(
                      value: 'salesUser',
                      child: Text('Sales Billing Operator')),
                  DropdownMenuItem(
                      value: 'inventoryUser',
                      child: Text('Inventory Stock Keeper')),
                ],
                onChanged: (role) {
                  if (role != null) setState(() => _selectedRole = role);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Send Invitation',
              onPressed: () async {
                if (_nameController.text.isEmpty ||
                    _emailController.text.isEmpty) {
                  AppFeedback.showSnackbar(context,
                      message: 'Please fill in all fields!', isError: true);
                  return;
                }

                final user = {
                  'name': _nameController.text,
                  'email': _emailController.text,
                  'role': _selectedRole,
                  'permissions': {
                    'view': true,
                    'create': true,
                    'edit': _selectedRole != 'inventoryUser',
                    'delete': _selectedRole == 'owner',
                    'print': true,
                    'export': _selectedRole == 'owner' ||
                        _selectedRole == 'accountant',
                    'cancel': false,
                    'approve': false,
                  }
                };

                await ref
                    .read(billingRepositoryProvider.notifier)
                    .inviteUser(user);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(ctx,
                      message: 'Invitation email dispatched successfully!');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionsMatrixDialog(Map<String, dynamic> user) {
    Map<String, dynamic> perms = Map.from(user['permissions'] ?? {});

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Custom Permissions Matrix: ${user['name']}'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: perms.keys.map((key) {
                    return CheckboxListTile(
                      title: Text('Allow ${key.toUpperCase()} actions'),
                      value: perms[key] ?? false,
                      onChanged: (val) {
                        setDialogState(() {
                          perms[key] = val ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Apply Permissions',
                  onPressed: () async {
                    await ref
                        .read(billingRepositoryProvider.notifier)
                        .updateUserPermissions(
                          user['email'],
                          user['role'],
                          Map<String, bool>.from(perms),
                        );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      AppFeedback.showSnackbar(ctx,
                          message: 'Role permissions matrix updated!');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(
      BuildContext context, Map<String, dynamic> user, bool isDark) {
    final name = user['name'] ?? 'Unknown User';
    final email = user['email'] ?? '';
    final role = user['role'] as String? ?? 'salesUser';
    final Map<String, dynamic> matrix = user['permissions'] ?? {};
    final allowedActions =
        matrix.keys.where((k) => matrix[k] == true).toList();

    // Generate initials for avatar
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    // Map role color
    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'owner':
        roleColor = const Color(0xFFD32F2F); // Red
        roleLabel = 'Owner';
        break;
      case 'admin':
        roleColor = const Color(0xFF673AB7); // Purple
        roleLabel = 'Manager';
        break;
      case 'accountant':
        roleColor = const Color(0xFF1976D2); // Blue
        roleLabel = 'Accountant';
        break;
      case 'salesUser':
        roleColor = const Color(0xFF2E7D32); // Green
        roleLabel = 'Sales Billing';
        break;
      case 'inventoryUser':
        roleColor = const Color(0xFFFF9800); // Orange
        roleLabel = 'Inventory';
        break;
      default:
        roleColor = Colors.grey;
        roleLabel = role.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              // Role Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: roleColor.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Policy tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Access Matrix Policies',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    allowedActions.isEmpty
                        ? const Text('No active policy matrix',
                            style: TextStyle(fontSize: 11, color: Colors.grey))
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: allowedActions.map((act) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2E2E2E)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  act.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action Button
              IconButton(
                icon:
                    const Icon(Icons.shield_outlined, color: Color(0xFF2E7D32)),
                tooltip: 'Edit Permission Matrix',
                onPressed: () => _showPermissionsMatrixDialog(user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Team Members & Access Control')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.people_outline, color: Color(0xFF2E7D32), size: 22),
                    SizedBox(width: 8),
                    Text('Active Team Directory',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                AppButton(
                  label: 'Add Member',
                  icon: Icons.person_add,
                  onPressed: _showInviteUserDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (billingState.customUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : Colors.grey.shade100),
                ),
                child: const Center(
                  child: Text('No team members added yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: billingState.customUsers.length,
                itemBuilder: (context, idx) {
                  final user = billingState.customUsers[idx];
                  return _buildUserCard(context, user, isDark);
                },
              ),
          ],
        ),
      ),
    );
  }
}
