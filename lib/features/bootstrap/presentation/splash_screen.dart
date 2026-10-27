import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/env/env.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/auth_bootstrap.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(authBootstrapProvider, (_, next) {
      if (next case AsyncData()) _continue();
    }, fireImmediately: true);
  }

  void _continue() {
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(authBootstrapProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.maroon,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Env.appName,
                  style: textTheme.displayMedium
                      ?.copyWith(color: AppColors.goldLight),
                  textAlign: TextAlign.center,
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 1800.ms,
                      color: AppColors.ivory.withValues(alpha: 0.6),
                    ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Wedding cards & pre-wedding shoots',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.ivory),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (bootstrap case AsyncError(:final error))
                  _BootstrapError(
                    message: mapError(error).message,
                    onRetry: () =>
                        ref.read(authBootstrapProvider.notifier).retry(),
                    onContinueOffline: _continue,
                  )
                else
                  const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.goldLight,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({
    required this.message,
    required this.onRetry,
    required this.onContinueOffline,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onContinueOffline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.ivory),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.charcoal,
          ),
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.ivory),
          onPressed: onContinueOffline,
          child: const Text('Continue offline (card maker only)'),
        ),
      ],
    );
  }
}
