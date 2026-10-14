import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagar_shield_360/nagar_repository.dart';
import 'package:nagar_shield_360/ui/official_overview.dart';
import 'package:nagar_shield_360/ui/official_task_list.dart';

class _ShowcaseRepository implements NagarRepository {
  static final incident = <String, dynamic>{
    'id': 'incident-1',
    'code': 'NS-TEST-1',
    'title_bn': 'বাজার সড়কে পানি জমেছে',
    'area_bn': 'মিরপুর বাজার সড়ক',
    'status': 'verification_pending',
  };

  @override
  Future<List<RowData>> incidents() async => [incident];

  @override
  Future<List<RowData>> tasks() async => [
    {
      'id': 'task-1',
      'incident_id': 'incident-1',
      'department_id': 'drainage',
      'team_id': 'drainage-a',
      'assignee_id': 'worker-1',
      'status': 'action_submitted',
      'note': 'ড্রেন পরিষ্কার করে কাজের ছবি জমা দিন।',
      'incidents': incident,
    },
  ];

  @override
  Future<List<RowData>> staffDirectory() async => [
    {'id': 'worker-1', 'display_name': 'ড্রেনেজ মাঠকর্মী'},
  ];

  @override
  Future<List<RowData>> reviewQueue() async => [
    {
      'id': 'observation-1',
      'title_bn': 'নতুন অভিযোগ',
      'status': 'needs_review',
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final repository = _ShowcaseRepository();
  final profile = <String, dynamic>{
    'id': 'executive-1',
    'display_name': 'নির্বাহী কর্মকর্তা',
    'role': 'executive',
  };

  testWidgets(
    'official overview shows live review and approval steps on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficialOverview(
              repository: repository,
              profile: profile,
              bangla: true,
              onNavigate: (_) {},
              onOpenIncident: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('১টি নতুন প্রতিবেদন যাচাই বাকি'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('১টি নতুন প্রতিবেদন যাচাই বাকি'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('১টি কাজের ফল যাচাই বাকি'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('১টি কাজের ফল যাচাই বাকি'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('task list shows the named worker and completion review status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfficialTaskList(
            repository: repository,
            profile: profile,
            bangla: true,
            onOpenIncident: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('ড্রেনেজ মাঠকর্মী'), findsOneWidget);
    expect(find.text('কাজ শেষে যাচাই বাকি'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
