import 'package:flutter/material.dart';

import '../nagar_repository.dart';
import 'workflow_labels.dart';

class OfficialReportView extends StatefulWidget {
  const OfficialReportView({
    super.key,
    required this.repository,
    required this.bangla,
    required this.onOpenIncident,
  });
  final NagarRepository repository;
  final bool bangla;
  final ValueChanged<String> onOpenIncident;

  @override
  State<OfficialReportView> createState() => _OfficialReportViewState();
}

class _OfficialReportViewState extends State<OfficialReportView> {
  late final Future<List<RowData>> incidents;
  String t(String en, String bn) => widget.bangla ? bn : en;

  @override
  void initState() {
    super.initState();
    incidents = widget.repository.incidents();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<RowData>>(
    future: incidents,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final rows = snapshot.data!;
      final resolved = rows.where((row) => row['status'] == 'resolved').length;
      final pending = rows
          .where((row) => row['status'] == 'verification_pending')
          .length;
      final escalated = rows.where((row) => row['escalated'] == true).length;
      final byDepartment = <String, int>{};
      final byStatus = <String, int>{};
      for (final row in rows) {
        final dept = row['department_id'].toString();
        final status = row['status'].toString();
        byDepartment[dept] = (byDepartment[dept] ?? 0) + 1;
        byStatus[status] = (byStatus[status] ?? 0) + 1;
      }
      final completion = rows.isEmpty ? 0.0 : resolved / rows.length;
      String n(int value) => WorkflowLabels.number(value, widget.bangla);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t('City work report', 'নগরের কাজের হিসাব'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            t(
              'Counts reflect incidents visible to your role in the shared system.',
              'আপনার দায়িত্ব অনুযায়ী যে ঘটনাগুলো দেখা যায়, শুধু সেগুলোর হিসাব এখানে আছে।',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Completion', 'কাজ শেষ হওয়ার হার'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${n(resolved)} / ${n(rows.length)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: completion,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      '$pending awaiting approval · $escalated escalated',
                      '${n(pending)}টি অনুমোদনের অপেক্ষায় · ${n(escalated)}টি জরুরি চিহ্নিত',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t('By department', 'বিভাগভিত্তিক ঘটনা'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final entry in byDepartment.entries)
            _CountRow(
              WorkflowLabels.department(entry.key, widget.bangla),
              entry.value,
              rows.length,
              widget.bangla,
            ),
          const SizedBox(height: 18),
          Text(
            t('By work stage', 'কাজের ধাপ অনুযায়ী'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final entry in byStatus.entries)
            _CountRow(
              WorkflowLabels.status(entry.key, widget.bangla),
              entry.value,
              rows.length,
              widget.bangla,
            ),
          const SizedBox(height: 18),
          Text(
            t('Recently completed', 'সম্প্রতি শেষ হওয়া কাজ'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final row
              in rows.where((item) => item['status'] == 'resolved').take(5))
            Card(
              child: ListTile(
                title: Text('${row['code']} · ${row['title_bn']}'),
                subtitle: Text(row['area_bn']?.toString() ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onOpenIncident(row['id'].toString()),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            t(
              'Priority scores and detection overlays are simulated demo values.',
              'অগ্রাধিকারের স্কোর ও ছবির চিহ্নগুলো ডেমোর নমুনা তথ্য।',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    },
  );
}

class _CountRow extends StatelessWidget {
  const _CountRow(this.label, this.value, this.total, this.bangla);
  final String label;
  final int value;
  final int total;
  final bool bangla;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(WorkflowLabels.number(value, bangla)),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: total == 0 ? 0 : value / total,
          minHeight: 5,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    ),
  );
}
