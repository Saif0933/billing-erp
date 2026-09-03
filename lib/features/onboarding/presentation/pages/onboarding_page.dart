import 'package:flutter/material.dart';
import '../../../platform-admin/presentation/widgets/platform_onboarding_wizard.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: PlatformOnboardingWizard(),
        ),
      ),
    );
  }
}
