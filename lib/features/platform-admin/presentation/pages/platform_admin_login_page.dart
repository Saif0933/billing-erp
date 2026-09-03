import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/platform_admin_provider.dart';

class PlatformAdminLoginPage extends ConsumerStatefulWidget {
  const PlatformAdminLoginPage({super.key});

  @override
  ConsumerState<PlatformAdminLoginPage> createState() => _PlatformAdminLoginPageState();
}

class _PlatformAdminLoginPageState extends ConsumerState<PlatformAdminLoginPage> {
  final _emailController = TextEditingController(text: 'admin@platform-billing.com');
  final _passwordController = TextEditingController(text: 'SuperAdmin@2026');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'Please enter both email and master password', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      final success = ref.read(platformAdminProvider.notifier).login(email, password);
      setState(() => _isLoading = false);

      if (success) {
        AppFeedback.showSnackbar(context, message: 'SuperAdmin Authentication Successful!');
        context.go('/platform-admin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Sleek deep slate
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  // Left Hero Banner (Desktop)
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF090D16),
                            Color(0xFF1E1B4B),
                            Color(0xFF311042),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Platform Logo
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'PLATFORM CONTROL PLANE',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),

                          // Center Headlines & Security Badges
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock, size: 12, color: Color(0xFF10B981)),
                                    SizedBox(width: 6),
                                    Text(
                                      'ZERO-TRUST SUPERADMIN ACCESS',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Centralized Multi-Tenant\nOperations & Governance',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Manage organization subscriptions, provision multi-tenant database clusters, review tenant analytics and supervise global billing infrastructure in real-time.',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),

                          // Bottom System Telemetry Pill
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _TelemetryItem(label: 'CLUSTER STATUS', value: 'Operational', color: Color(0xFF10B981)),
                                _TelemetryItem(label: 'ACTIVE TENANTS', value: '148 Orgs', color: Colors.white),
                                _TelemetryItem(label: 'LATENCY', value: '38 ms', color: Color(0xFF38BDF8)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Login Form (Desktop)
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _buildLoginForm(isDark),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _buildLoginForm(isDark),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // Dark zinc card
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo & Title
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.admin_panel_settings, size: 28, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Platform SuperAdmin',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in to access global platform administration',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFFA1A1AA),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Email Input
          const Text('SUPERADMIN EMAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF818CF8), size: 18),
              hintText: 'admin@platform-billing.com',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Password Input
          const Text('MASTER PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF818CF8), size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 18),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // Login Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Authenticate SuperAdmin',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Back to Tenant App Link
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF818CF8)),
              label: const Text(
                'Return to Tenant Billing App',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF818CF8), fontWeight: FontWeight.w600),
              ),
              onPressed: () => context.go('/dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
