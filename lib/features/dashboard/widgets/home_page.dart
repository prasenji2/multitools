import 'package:flutter/material.dart';
import 'package:multi_utility_tools/core/providers/tools_provider.dart';
import 'package:multi_utility_tools/features/dashboard/dashboard_screen.dart';
import 'package:multi_utility_tools/features/dashboard/widgets/favorites_section.dart';
import 'package:multi_utility_tools/features/dashboard/widgets/featured_tools.dart';
import 'package:multi_utility_tools/features/dashboard/widgets/quick_access.dart';
import 'package:multi_utility_tools/features/dashboard/widgets/recent_tools_section.dart';
import 'package:multi_utility_tools/features/dashboard/widgets/welcome_banner.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            const WelcomeBanner(),
            const SizedBox(height: 24),

            // Quick Access Section
            const QuickAccess(),
            const SizedBox(height: 24),

            // Featured Tools Section
            const FeaturedTools(),
            const SizedBox(height: 24),

            // Favorites Section
            if (toolsProvider.favoriteTools.isNotEmpty) ...[
              const FavoritesSection(),
              const SizedBox(height: 24),
            ],

            // Recent Tools Section
            if (toolsProvider.recentTools.isNotEmpty) ...[
              const RecentToolsSection(),
              const SizedBox(height: 24),
            ],

            // Removed Categories Preview

            // App Info Section
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Multi-Utility Tools',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app provides a collection of useful tools for everyday tasks. From text manipulation to unit conversion, we\'ve got you covered.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Version 1.0.0',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '© 2025 Multi-Utility Tools',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
