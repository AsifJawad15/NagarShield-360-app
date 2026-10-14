import 'dart:convert';

class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const publicDemoEmail = String.fromEnvironment('PUBLIC_DEMO_EMAIL');
  static const publicDemoPassword = String.fromEnvironment(
    'PUBLIC_DEMO_PASSWORD',
  );
  static const publicDemoSlot = String.fromEnvironment('PUBLIC_DEMO_SLOT');
  static const _publicDemoAccountsJson = String.fromEnvironment(
    'PUBLIC_DEMO_ACCOUNTS',
  );

  static final List<Map<String, dynamic>> publicDemoAccounts =
      _publicDemoAccountsJson.isEmpty
      ? []
      : (jsonDecode(_publicDemoAccountsJson) as List)
            .map((item) => (item as Map).cast<String, dynamic>())
            .toList();

  static bool get hasPublicDemoIdentity =>
      publicDemoAccounts.isNotEmpty ||
      (publicDemoEmail.isNotEmpty && publicDemoPassword.isNotEmpty);

  static bool get hasMultiplePublicDemoIdentities =>
      publicDemoAccounts.length > 1;

  static Map<String, dynamic>? publicDemoAccount(String? slot) {
    if (publicDemoAccounts.isNotEmpty) {
      for (final account in publicDemoAccounts) {
        if (account['slot'] == slot) return account;
      }
      return null;
    }
    if (publicDemoEmail.isNotEmpty && publicDemoPassword.isNotEmpty) {
      return {
        'slot': publicDemoSlot,
        'email': publicDemoEmail,
        'password': publicDemoPassword,
      };
    }
    return null;
  }
}
