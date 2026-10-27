import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shaadi_cards_wedding_invites/core/errors/app_exception.dart';
import 'package:shaadi_cards_wedding_invites/core/supabase/auth_bootstrap.dart';
import 'package:shaadi_cards_wedding_invites/core/supabase/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

User fakeUser(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-10-27T00:00:00Z',
    );

void main() {
  group('AuthRepository', () {
    late MockGoTrueClient auth;
    late AuthRepository repo;

    setUp(() {
      auth = MockGoTrueClient();
      repo = AuthRepository(auth);
    });

    test('reuses the persisted user without a network call', () async {
      when(() => auth.currentUser).thenReturn(fakeUser('existing'));

      expect(await repo.ensureSignedIn(), 'existing');
      verifyNever(
        () => auth.signInAnonymously(captchaToken: any(named: 'captchaToken')),
      );
    });

    test('signs in anonymously on first launch', () async {
      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.signInAnonymously(captchaToken: null))
          .thenAnswer((_) async => AuthResponse(user: fakeUser('new-user')));

      expect(await repo.ensureSignedIn(), 'new-user');
    });

    test('maps auth errors to a friendly AuthFailure', () async {
      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.signInAnonymously(captchaToken: null))
          .thenThrow(const AuthException('Anonymous sign-ins are disabled'));

      await expectLater(repo.ensureSignedIn(), throwsA(isA<AuthFailure>()));
    });

    test('maps retryable fetch errors to NetworkException', () async {
      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.signInAnonymously(captchaToken: null))
          .thenThrow(AuthRetryableFetchException());

      await expectLater(repo.ensureSignedIn(), throwsA(isA<NetworkException>()));
    });
  });

  group('AuthBootstrap', () {
    late MockAuthRepository repo;

    ProviderContainer makeContainer() {
      final container = ProviderContainer.test(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        retry: (_, _) => null,
      );
      return container;
    }

    setUp(() => repo = MockAuthRepository());

    test('resolves to the anonymous user id', () async {
      when(() => repo.ensureSignedIn()).thenAnswer((_) async => 'uid-1');
      final container = makeContainer();

      expect(await container.read(authBootstrapProvider.future), 'uid-1');
    });

    test('retry recovers after a failure', () async {
      var calls = 0;
      when(() => repo.ensureSignedIn()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw const NetworkException();
        return 'uid-2';
      });
      final container = makeContainer();
      container.listen(authBootstrapProvider, (_, _) {});

      await expectLater(
        container.read(authBootstrapProvider.future),
        throwsA(isA<NetworkException>()),
      );

      await container.read(authBootstrapProvider.notifier).retry();
      expect(container.read(authBootstrapProvider).value, 'uid-2');
    });
  });
}
