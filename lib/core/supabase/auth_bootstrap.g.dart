// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_bootstrap.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs once per app launch: ensures an anonymous Supabase session exists.
///
/// Resolves to the Supabase user id. RevenueCat configuration and the free
/// trial claim are chained here in the credits phase.

@ProviderFor(AuthBootstrap)
final authBootstrapProvider = AuthBootstrapProvider._();

/// Runs once per app launch: ensures an anonymous Supabase session exists.
///
/// Resolves to the Supabase user id. RevenueCat configuration and the free
/// trial claim are chained here in the credits phase.
final class AuthBootstrapProvider
    extends $AsyncNotifierProvider<AuthBootstrap, String> {
  /// Runs once per app launch: ensures an anonymous Supabase session exists.
  ///
  /// Resolves to the Supabase user id. RevenueCat configuration and the free
  /// trial claim are chained here in the credits phase.
  AuthBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authBootstrapHash();

  @$internal
  @override
  AuthBootstrap create() => AuthBootstrap();
}

String _$authBootstrapHash() => r'dc6a99c4bb812a8e6c771ce0129861689ab57071';

/// Runs once per app launch: ensures an anonymous Supabase session exists.
///
/// Resolves to the Supabase user id. RevenueCat configuration and the free
/// trial claim are chained here in the credits phase.

abstract class _$AuthBootstrap extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
