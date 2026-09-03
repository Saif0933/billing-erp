import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../widgets/product_scanner_card.dart';
import '../widgets/recent_scans_card.dart';
import '../widgets/product_table_section.dart';

class ProductListingPage extends ConsumerWidget {
  const ProductListingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.products)) {
      return const LockedFeaturePage(featureName: 'Product Catalogue');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 900;

              // Left Panel (Scanner Card + Recent Scans Card)
              final leftPanel = Column(
                children: const [
                  ProductScannerCard(),
                  SizedBox(height: 16),
                  RecentScansCard(),
                ],
              );

              // Right Main Panel (Product List & Data Table)
              const rightPanel = ProductTableSection();

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leftPanel,
                    const SizedBox(height: 16),
                    rightPanel,
                    const SizedBox(height: 24),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: leftPanel,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: rightPanel,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
