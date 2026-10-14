import 'package:flutter/material.dart';

import 'workflow_labels.dart';

class PublicStatusCard extends StatelessWidget {
  const PublicStatusCard({
    super.key,
    required this.report,
    required this.bangla,
  });
  final Map<String, dynamic> report;
  final bool bangla;

  String t(String en, String bn) => bangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    final status = report['status']?.toString() ?? 'queued';
    final code = report['code']?.toString();
    final progress = WorkflowLabels.stage(status);
    final stepBn = WorkflowLabels.number(progress + 1, bangla);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (code != null)
              Text(
                code,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF597767),
                ),
              ),
            Text(
              report['title']?.toString() ?? '',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            StatusPill(status: status, bangla: bangla),
            if (!const [
              'queued',
              'submitted',
              'failed',
              'dismissed',
            ].contains(status)) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (progress + 1) / 6,
                minHeight: 5,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 6),
              Text(
                t('Step ${progress + 1} of 6', '৬ ধাপের $stepBn নম্বর ধাপ'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (status == 'dismissed')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t(
                    'The official review did not accept this report.',
                    'কর্মকর্তার যাচাইয়ে প্রতিবেদনটি গ্রহণ করা হয়নি।',
                  ),
                ),
              ),
            if (status == 'queued' || status == 'failed')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t(
                    'Stored on this phone. Retry when connected.',
                    'এই ফোনে রাখা আছে। ইন্টারনেট এলে আবার পাঠান।',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
