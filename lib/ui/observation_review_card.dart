import 'package:flutter/material.dart';

import '../nagar_repository.dart';
import 'private_evidence_preview.dart';
import 'workflow_labels.dart';

class ObservationReviewCard extends StatefulWidget {
  const ObservationReviewCard({
    super.key,
    required this.repository,
    required this.observation,
    required this.bangla,
    required this.onReview,
  });
  final NagarRepository repository;
  final RowData observation;
  final bool bangla;
  final Future<void> Function(bool approve) onReview;

  @override
  State<ObservationReviewCard> createState() => _ObservationReviewCardState();
}

class _ObservationReviewCardState extends State<ObservationReviewCard> {
  bool busy = false;
  String t(String en, String bn) => widget.bangla ? bn : en;

  Future<void> _review(bool approve) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.onReview(approve);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.observation;
    final source = item['source']?.toString() ?? 'scenario';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title_bn'].toString(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              '${WorkflowLabels.source(source, widget.bangla)} · ${item['area_bn']}',
            ),
            if (item['report_code'] != null)
              Text(
                item['report_code'].toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (item['description_bn'] != null &&
                item['description_bn'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(item['description_bn'].toString()),
              ),
            if (item['media_key'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PrivateEvidencePreview(
                  repository: widget.repository,
                  storageKey: item['media_key'].toString(),
                  label: t('Submitted evidence', 'জমা দেওয়া ছবি বা ভিডিও'),
                  bangla: widget.bangla,
                ),
              ),
            if (source == 'scenario')
              Text(
                t(
                  'Simulated preset; an official still decides.',
                  'এটি নমুনা দৃশ্য। সিদ্ধান্ত কর্মকর্তা নেবেন।',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : () => _review(true),
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(
                    t('Verify and open incident', 'যাচাই করে ঘটনা খুলুন'),
                  ),
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => _review(false),
                  child: Text(t('Do not accept', 'গ্রহণ করবেন না')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
