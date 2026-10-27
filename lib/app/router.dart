import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/bootstrap/presentation/splash_screen.dart';
import '../features/home/presentation/home_screen.dart';

part 'router.g.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
