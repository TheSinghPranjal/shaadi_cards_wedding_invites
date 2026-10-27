import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/env.dart';
import '../errors/app_exception.dart';

part 'supabase_providers.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  if (!Env.hasSupabase) {
    throw const ConfigException(
      'Online features are not configured in this build.',
    );
  }
  return Supabase.instance.client;
}
