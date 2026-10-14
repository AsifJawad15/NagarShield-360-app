import 'package:flutter/material.dart';

import '../nagar_repository.dart';
import 'notice.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    required this.repository,
    required this.bangla,
    required this.onBack,
    required this.onSignedIn,
  });

  final NagarRepository repository;
  final bool bangla;
  final VoidCallback onBack;
  final ValueChanged<RowData> onSignedIn;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool busy = false;

  Future<void> _signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.signIn(email.text, password.text);
      final profile = await widget.repository.officialProfile();
      if (profile == null) throw StateError('Official profile unavailable.');
      widget.onSignedIn(profile);
    } catch (value) {
      if (mounted) setState(() => error = value.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.bangla ? 'কর্মকর্তা সাইন ইন' : 'Official sign in'),
      leading: BackButton(onPressed: widget.onBack),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 54,
              color: Color(0xFF287456),
            ),
            const SizedBox(height: 14),
            Text(
              widget.bangla
                  ? 'কাজের তথ্য দেখতে আপনার অফিসিয়াল অ্যাকাউন্টে ঢুকুন।'
                  : 'Sign in with your official account to review and manage work.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 22),
            if (error != null) Notice(error!),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: widget.bangla ? 'ইমেইল ঠিকানা' : 'Email address',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.bangla ? 'পাসওয়ার্ড' : 'Password',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: busy ? null : _signIn,
              child: Text(widget.bangla ? 'সাইন ইন' : 'Sign in'),
            ),
          ],
        ),
      ),
    ),
  );
}
