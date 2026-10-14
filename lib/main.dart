import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';
import 'nagar_repository.dart';
import 'ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseClient? client;
  if (AppConfig.supabaseUrl.isNotEmpty &&
      AppConfig.supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
    client = Supabase.instance.client;
  }
  final repository = await NagarRepository.open(client);
  runApp(NagarShieldApp(repository: repository));
}

class NagarShieldApp extends StatelessWidget {
  const NagarShieldApp({super.key, required this.repository});

  final NagarRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nagar Shield 360',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF287456)),
      scaffoldBackgroundColor: const Color(0xFFF5F8F3),
    ),
    home: AppShell(repository: repository),
  );
}
