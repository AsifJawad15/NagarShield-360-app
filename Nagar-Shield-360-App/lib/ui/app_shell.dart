import 'package:flutter/material.dart';

import '../app_config.dart';
import '../nagar_repository.dart';
import 'landing_page.dart';
import 'local_demo_page.dart';
import 'official_pages.dart';
import 'public_page.dart';
import 'sign_in_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.repository});
  final NagarRepository repository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  bool bangla = true;
  String page = 'welcome';
  RowData? profile;
  String? publicSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  Future<void> _restore() async {
    profile = await widget.repository.officialProfile();
    publicSlot = await widget.repository.selectedPublicDemoSlot();
    if (!mounted) return;
    setState(() {
      if (profile != null) page = 'official';
    });
    if (profile == null) {
      await widget.repository.flushReports();
    } else {
      await widget.repository.flushStaffActions();
    }
  }

  Future<void> _openPublic() async {
    var slot = await widget.repository.selectedPublicDemoSlot();
    if (slot == null && AppConfig.hasMultiplePublicDemoIdentities) {
      if (!mounted) return;
      slot = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(
            bangla
                ? 'এই ফোনের ডেমো পরিচয় বেছে নিন'
                : 'Choose this phone’s demo identity',
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                bangla
                    ? 'একবার বেছে নিলে এই ফোনে শুধু সেই পরিচয়ের প্রতিবেদন দেখা যাবে। অন্য পরীক্ষার ফোনে আলাদা অক্ষর নিন।'
                    : 'Choose once for this installation. Use a different letter on another test phone.',
              ),
            ),
            for (final account in AppConfig.publicDemoAccounts)
              SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(context, account['slot'].toString()),
                child: Text(
                  '${account['slot']} · ${bangla ? 'পরীক্ষামূলক নাগরিক' : 'Demo citizen'}',
                ),
              ),
          ],
        ),
      );
      if (slot == null) return;
      await widget.repository.selectPublicDemoSlot(slot);
    }
    if (mounted) {
      setState(() {
        publicSlot = slot;
        page = 'public';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (profile == null) {
        widget.repository.flushReports();
      } else {
        widget.repository.flushStaffActions();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (page) {
      case 'public':
        return PublicPage(
          repository: widget.repository,
          bangla: bangla,
          demoSlot: publicSlot,
          onBack: () => setState(() => page = 'welcome'),
        );
      case 'signin':
        return SignInPage(
          repository: widget.repository,
          bangla: bangla,
          onBack: () => setState(() => page = 'welcome'),
          onSignedIn: (value) {
            setState(() {
              profile = value;
              page = 'official';
            });
            widget.repository.flushStaffActions();
          },
        );
      case 'official':
        return OfficialPages(
          repository: widget.repository,
          profile: profile!,
          bangla: bangla,
          onSignOut: () async {
            await widget.repository.signOut();
            if (!mounted) return;
            setState(() {
              profile = null;
              page = 'welcome';
            });
          },
        );
      case 'demo':
        return LocalDemoPage(
          repository: widget.repository,
          bangla: bangla,
          onBack: () => setState(() => page = 'welcome'),
        );
      default:
        return LandingPage(
          bangla: bangla,
          configured: widget.repository.configured,
          onLanguageChange: (value) => setState(() => bangla = value),
          onPublic: _openPublic,
          onOfficial: () => setState(() => page = 'signin'),
          onDemo: () => setState(() => page = 'demo'),
        );
    }
  }
}
