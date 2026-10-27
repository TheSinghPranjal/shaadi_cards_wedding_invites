import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shaadi_cards_wedding_invites/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapError', () {
    test('passes AppExceptions through untouched', () {
      const e = InsufficientCreditsException();
      expect(mapError(e), same(e));
    });

    test('socket errors become NetworkException', () {
      expect(
        mapError(const SocketException('Failed host lookup')),
        isA<NetworkException>(),
      );
    });

    test('function error codes map to typed exceptions', () {
      expect(
        mapError(
          const FunctionException(
            status: 402,
            details: {'code': 'insufficient_credits', 'message': 'x'},
          ),
        ),
        isA<InsufficientCreditsException>(),
      );
      expect(
        mapError(
          const FunctionException(status: 429, details: {'code': 'rate_limited'}),
        ),
        isA<RateLimitedException>(),
      );
    });

    test('5xx function errors never leak server text', () {
      final mapped = mapError(
        const FunctionException(
          status: 500,
          details: {'message': 'TypeError: undefined at line 42'},
        ),
      );
      expect(mapped, isA<ServerException>());
      expect(mapped.message, isNot(contains('TypeError')));
    });

    test('unknown errors get a generic friendly message', () {
      final mapped = mapError(StateError('boom'));
      expect(mapped, isA<UnknownException>());
      expect(mapped.message, isNot(contains('boom')));
    });
  });
}
