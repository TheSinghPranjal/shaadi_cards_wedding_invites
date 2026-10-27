import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_exception.dart';
import 'supabase_providers.dart';

part 'auth_repository.g.dart';

/// Silent, login-free identity backed by Supabase Anonymous Auth.
class AuthRepository {
  AuthRepository(this._auth);

  final GoTrueClient _auth;

  String? get currentUserId => _auth.currentUser?.id;

  /// Returns the persisted anonymous user, creating one on first launch.
  Future<String> ensureSignedIn({String? captchaToken}) async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.id;

    try {
      final response = await _auth.signInAnonymously(captchaToken: captchaToken);
      final user = response.user;
      if (user == null) throw const AuthFailure();
      return user.id;
    } catch (e) {
      throw mapError(e);
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(supabaseClientProvider).auth);
