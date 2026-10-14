import 'package:flutter/material.dart';

import '../nagar_repository.dart';

class StaffQueuePage extends StatefulWidget {
  const StaffQueuePage({
    super.key,
    required this.repository,
    required this.bangla,
  });
  final NagarRepository repository;
  final bool bangla;

  @override
  State<StaffQueuePage> createState() => _StaffQueuePageState();
}

class _StaffQueuePageState extends State<StaffQueuePage> {
  late Future<List<RowData>> items;

  @override
  void initState() {
    super.initState();
    items = widget.repository.pendingStaffActions();
  }

  String t(String en, String bn) => widget.bangla ? bn : en;
  void _load() =>
      setState(() => items = widget.repository.pendingStaffActions());

  Future<void> _work(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<RowData>>(
    future: items,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t('Pending staff work', 'অপেক্ষমাণ কাজ'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Queued actions retry after reconnect. Rejected actions need review because the task may have changed.',
              'সংযোগ ফিরলে অপেক্ষমাণ কাজ পাঠানো হবে। বাতিল হওয়া কাজ পর্যালোচনা করুন; এর মধ্যে কাজের অবস্থা বদলে যেতে পারে।',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _work(widget.repository.flushStaffActions),
            icon: const Icon(Icons.sync),
            label: Text(t('Sync now', 'এখন পাঠান')),
          ),
          if (snapshot.data!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(t('Nothing pending.', 'অপেক্ষমাণ কিছু নেই।')),
            ),
          for (final row in snapshot.data!)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['kind'] == 'evidence'
                          ? t('After evidence', 'কাজ শেষে প্রমাণ')
                          : row['action'].toString(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${row['status']} · ${row['created_at']}'),
                    if (row['error'] != null) Text(row['error'].toString()),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (row['status'] == 'rejected')
                          TextButton(
                            onPressed: () => _work(
                              () => widget.repository.retryStaffAction(
                                row['kind'].toString(),
                                row['request_id'].toString(),
                              ),
                            ),
                            child: Text(t('Retry', 'আবার চেষ্টা')),
                          ),
                        TextButton(
                          onPressed: () => _work(
                            () => widget.repository.discardStaffAction(
                              row['kind'].toString(),
                              row['request_id'].toString(),
                            ),
                          ),
                          child: Text(t('Discard', 'মুছুন')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
