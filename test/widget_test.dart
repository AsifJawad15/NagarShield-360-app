import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagar_shield_360/home_screen.dart';
import 'package:nagar_shield_360/main.dart';

void main() {
  testWidgets('shows the branded Bangla loading screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NagarShieldApp());

    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(find.text('Nagar Shield 360'), findsOneWidget);
    expect(find.text('অ্যাপ প্রস্তুত হচ্ছে...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('প্রতিটি রাস্তার'), findsOneWidget);
    expect(find.text('ধারণামূলক মানচিত্র'), findsOneWidget);
  });
}
