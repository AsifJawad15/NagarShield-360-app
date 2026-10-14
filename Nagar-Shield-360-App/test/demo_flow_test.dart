import 'package:flutter_test/flutter_test.dart';
import 'package:nagar_shield_360/demo_flow.dart';

void main() {
  test('local presentation follows the complete verified workflow', () {
    var state = DemoState.initial;
    for (final action in [
      'verify',
      'assign',
      'accept',
      'start',
      'submit',
      'approve',
    ]) {
      state = DemoFlow.advance(state, action);
    }
    expect(state.incidentStatus, 'resolved');
    expect(state.taskStatus, 'resolved');
    expect(state.events.length, 7);
  });

  test('cannot resolve a task before assignment and evidence', () {
    expect(
      () => DemoFlow.advance(DemoState.initial, 'approve'),
      throwsStateError,
    );
    final verified = DemoFlow.advance(DemoState.initial, 'verify');
    expect(() => DemoFlow.advance(verified, 'start'), throwsStateError);
  });
}
