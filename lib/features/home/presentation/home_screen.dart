import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/env/env.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(Env.appName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('What would you like to create?', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          const FeatureCard(
            title: 'Wedding Cards',
            subtitle: 'Invitations & Save the Dates',
            badge: 'Free',
            icon: Icons.style_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          const FeatureCard(
            title: 'AI Pre-Wedding Shoot',
            subtitle: 'Palace, beach, snow & more',
            icon: Icons.auto_awesome_rounded,
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.maroon, AppColors.maroonDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.cardBorder,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, size: 40, color: AppColors.goldLight),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleLarge
                            ?.copyWith(color: AppColors.ivory),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.ivoryDeep),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(badge!, style: textTheme.labelMedium),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
