class DemoState {
  const DemoState({
    required this.incidentStatus,
    required this.taskStatus,
    required this.events,
  });

  final String incidentStatus;
  final String taskStatus;
  final List<String> events;

  static const initial = DemoState(
    incidentStatus: 'submitted',
    taskStatus: 'unassigned',
    events: ['Public report submitted locally'],
  );
}

class DemoFlow {
  const DemoFlow._();

  static DemoState advance(DemoState current, String action) {
    String incident = current.incidentStatus;
    String task = current.taskStatus;
    switch (action) {
      case 'verify':
        if (incident != 'submitted') {
          throw StateError('Verify the report first.');
        }
        incident = 'verified';
      case 'assign':
        if (incident != 'verified') {
          throw StateError('Verify before assigning.');
        }
        incident = 'assigned';
        task = 'assigned';
      case 'accept':
        if (task != 'assigned') {
          throw StateError('Assign first.');
        }
        task = 'acknowledged';
      case 'start':
        if (task != 'acknowledged') {
          throw StateError('Accept first.');
        }
        task = 'in_progress';
        incident = 'in_progress';
      case 'submit':
        if (task != 'in_progress') {
          throw StateError('Start work first.');
        }
        task = 'action_submitted';
        incident = 'verification_pending';
      case 'approve':
        if (task != 'action_submitted') {
          throw StateError('Submit evidence first.');
        }
        task = 'resolved';
        incident = 'resolved';
      default:
        throw StateError('Unknown demo action.');
    }
    return DemoState(
      incidentStatus: incident,
      taskStatus: task,
      events: [...current.events, action],
    );
  }
}
