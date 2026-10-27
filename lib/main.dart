import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/env/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Without keys the app still runs: the card maker is fully offline.
  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseKey,
    );
  }

  runApp(
    ProviderScope(
      // No automatic retries: the UI offers explicit retry, and paid
      // generation calls must never be silently re-sent.
      retry: (retryCount, error) => null,
      child: const ShaadiCardsApp(),
    ),
  );
}
