import 'package:flutter/material.dart';

class WorkflowLabels {
  static String number(num value, bool bangla) {
    final text = value.toString();
    if (!bangla) return text;
    const digits = '০১২৩৪৫৬৭৮৯';
    return text.replaceAllMapped(
      RegExp(r'\d'),
      (match) => digits[int.parse(match.group(0)!)],
    );
  }

  static String status(String value, bool bangla) {
    final labels = <String, (String, String)>{
      'needs_review': ('Awaiting official review', 'কর্মকর্তার যাচাই বাকি'),
      'dismissed': ('Not accepted', 'যাচাইয়ে গ্রহণ করা হয়নি'),
      'verified': ('Verified', 'যাচাই হয়েছে'),
      'assigned': ('Assigned', 'কাজ দেওয়া হয়েছে'),
      'acknowledged': ('Accepted by worker', 'কর্মী কাজটি নিয়েছেন'),
      'in_progress': ('Work in progress', 'কাজ চলছে'),
      'action_submitted': ('Awaiting completion review', 'কাজ শেষে যাচাই বাকি'),
      'verification_pending': (
        'Awaiting completion review',
        'কাজ শেষে যাচাই বাকি',
      ),
      'resolved': ('Completed and approved', 'কাজ শেষ, অনুমোদিত'),
      'queued': ('Waiting to sync', 'পাঠানোর অপেক্ষায়'),
      'submitted': ('Submitted', 'জমা হয়েছে'),
      'failed': ('Retry needed', 'আবার পাঠাতে হবে'),
    };
    final label = labels[value];
    return label == null ? value : (bangla ? label.$2 : label.$1);
  }

  static String role(String value, bool bangla) {
    final labels = <String, (String, String)>{
      'executive': ('Executive', 'নির্বাহী কর্মকর্তা'),
      'department_head': ('Department head', 'বিভাগীয় প্রধান'),
      'supervisor': ('Supervisor', 'তদারককারী'),
      'field_employee': ('Field employee', 'মাঠকর্মী'),
      'survey_operator': ('Survey operator', 'জরিপকর্মী'),
    };
    final label = labels[value];
    return label == null ? value : (bangla ? label.$2 : label.$1);
  }

  static String department(String value, bool bangla) {
    final labels = <String, (String, String)>{
      'drainage': ('Drainage', 'পানিনিষ্কাশন'),
      'waste': ('Waste', 'বর্জ্য ব্যবস্থাপনা'),
      'health': ('Public health', 'জনস্বাস্থ্য'),
      'footpath': ('Footpath', 'ফুটপাত'),
      'inspection': ('Inspection', 'পরিদর্শন'),
    };
    final label = labels[value];
    return label == null ? value : (bangla ? label.$2 : label.$1);
  }

  static String source(String value, bool bangla) {
    final labels = <String, (String, String)>{
      'public': ('Public report', 'নাগরিকের প্রতিবেদন'),
      'drone': ('Drone survey', 'ড্রোন জরিপ'),
      'gapscan': ('Narrow-space survey', 'সংকীর্ণ স্থান জরিপ'),
      'scenario': ('Preset demo', 'নমুনা দৃশ্য'),
    };
    final label = labels[value];
    return label == null ? value : (bangla ? label.$2 : label.$1);
  }

  static String priority(String value, bool bangla) {
    final labels = <String, (String, String)>{
      'critical': ('Critical · simulated', 'অতি জরুরি · নমুনা'),
      'high': ('High · simulated', 'জরুরি · নমুনা'),
      'moderate': ('Moderate · simulated', 'মাঝারি · নমুনা'),
      'low': ('Low · simulated', 'কম · নমুনা'),
    };
    final label = labels[value];
    return label == null ? value : (bangla ? label.$2 : label.$1);
  }

  static String event(String value, bool bangla) {
    final labels = <String, (String, String)>{
      'seeded': ('Demo incident prepared', 'নমুনা ঘটনা তৈরি'),
      'verified_observation': ('Report verified', 'প্রতিবেদন যাচাই'),
      'assigned': ('Worker assigned', 'কর্মীকে কাজ দেওয়া হয়েছে'),
      'acknowledge_task': ('Worker accepted the task', 'কর্মী কাজটি নিয়েছেন'),
      'start_task': ('Work started', 'কাজ শুরু হয়েছে'),
      'submit_task': ('After-work evidence submitted', 'কাজের পরের প্রমাণ জমা'),
      'approve_task': ('Completion approved', 'কাজ শেষ হয়েছে বলে অনুমোদন'),
      'rework_task': ('Sent back for more work', 'আরও কাজের জন্য ফেরত'),
      'reopen_task': ('Task reopened', 'কাজ আবার খোলা হয়েছে'),
      'escalation_changed': (
        'Urgency flag changed',
        'জরুরি চিহ্ন বদলানো হয়েছে',
      ),
    };
    final label = labels[value];
    return label == null ? value : (bangla ? label.$2 : label.$1);
  }

  static int stage(String value) => switch (value) {
    'needs_review' => 0,
    'verified' => 1,
    'assigned' || 'acknowledged' => 2,
    'in_progress' => 3,
    'action_submitted' || 'verification_pending' => 4,
    'resolved' => 5,
    _ => 0,
  };

  static Color color(String value) => switch (value) {
    'resolved' || 'submitted' => const Color(0xFF287456),
    'dismissed' || 'failed' => const Color(0xFFAA4C40),
    'action_submitted' || 'verification_pending' => const Color(0xFFAA7024),
    'in_progress' => const Color(0xFF286C93),
    _ => const Color(0xFF5A6D61),
  };
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, required this.bangla});
  final String status;
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    final color = WorkflowLabels.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        WorkflowLabels.status(status, bangla),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
