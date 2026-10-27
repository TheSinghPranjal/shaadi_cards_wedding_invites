import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shaadi_cards_wedding_invites/app/app.dart';
import 'package:shaadi_cards_wedding_invites/core/errors/app_exception.dart';
import 'package:shaadi_cards_wedding_invites/core/supabase/auth_repository.dart';
import 'package:shaadi_cards_wedding_invites/features/home/presentation/home_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() => repo = MockAuthRepository());

  Future<void> pumpApp(WidgetTester t) => t.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
          retry: (_, _) => null,
          child: const ShaadiCardsApp(),
        ),
      );

  testWidgets('goes to home once the anonymous session is ready', (t) async {
    when(() => repo.ensureSignedIn()).thenAnswer((_) async => 'uid');

    await pumpApp(t);
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('offline: shows a friendly error with retry and offline mode',
      (t) async {
    when(() => repo.ensureSignedIn())
        .thenAnswer((_) async => throw const NetworkException());

    await pumpApp(t);
    await t.pump();
    await t.pump();

    expect(find.textContaining('No internet connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await t.tap(find.text('Continue offline (card maker only)'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
