/// Build-time configuration, injected with
/// `flutter run --dart-define-from-file=env.json`.
///
/// Only public client keys belong here. Service-role keys, AI provider keys
/// and webhook secrets live exclusively in Supabase Edge Function secrets.
abstract final class Env {
  static const appName = 'Shaadi Cards';

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The Supabase anon / publishable key (safe to ship; RLS protects data).
  static const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const revenueCatAndroidKey =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const revenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

  /// Cloudflare Turnstile site key. When set, anonymous sign-in sends a
  /// captcha token (Supabase "Attack Protection" must be enabled to match).
  static const turnstileSiteKey = String.fromEnvironment('TURNSTILE_SITE_KEY');

  /// Hidden "link phone number to recover credits" flow.
  static const enablePhoneLink = bool.fromEnvironment('ENABLE_PHONE_LINK');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
