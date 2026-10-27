import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_repository.dart';

part 'auth_bootstrap.g.dart';

/// Runs once per app launch: ensures an anonymous Supabase session exists.
///
/// Resolves to the Supabase user id. RevenueCat configuration and the free
/// trial claim are chained here in the credits phase.
@Riverpod(keepAlive: true)
class AuthBootstrap extends _$AuthBootstrap {
  @override
  Future<String> build() async {
    final auth = ref.watch(authRepositoryProvider);
    return auth.ensureSignedIn();
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).ensureSignedIn(),
    );
  }
}
