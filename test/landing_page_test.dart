import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagar_shield_360/ui/landing_page.dart';

void main() {
  testWidgets('landing fits a narrow phone without layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: LandingPage(
          bangla: true,
          configured: true,
          onLanguageChange: (_) {},
          onPublic: () {},
          onOfficial: () {},
          onDemo: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('landing explains the system and offers both entry paths', (
    tester,
  ) async {
    var publicTaps = 0;
    var officialTaps = 0;
    var english = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => LandingPage(
            bangla: !english,
            configured: true,
            onLanguageChange: (bangla) => setState(() => english = !bangla),
            onPublic: () => publicTaps++,
            onOfficial: () => officialTaps++,
            onDemo: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('সমস্যা চোখে পড়েছে? জানান, তারপর কী হলো দেখুন।'),
      findsOneWidget,
    );
    await tester.tap(find.text('সমস্যা জানান').first);
    await tester.tap(find.text('কর্মকর্তা হিসেবে সাইন ইন'));
    expect(publicTaps, 1);
    expect(officialTaps, 1);

    await tester.tap(find.text('EN'));
    await tester.pump();
    expect(find.text('See a problem? Help get it fixed.'), findsOneWidget);
  });
}
