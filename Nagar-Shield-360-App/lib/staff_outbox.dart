import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

typedef OutboxRow = Map<String, dynamic>;

class StaffOutbox {
  StaffOutbox(this.client, this.database);

  final SupabaseClient? client;
  final Database database;
  static const uuid = Uuid();
  Future<void>? _activeFlush;

  static Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff_action_outbox (
        request_id TEXT PRIMARY KEY,
        actor_uid TEXT NOT NULL,
        action TEXT NOT NULL,
        target_id TEXT,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        error TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_evidence_outbox (
        request_id TEXT PRIMARY KEY,
        actor_uid TEXT NOT NULL,
        task_id TEXT NOT NULL,
        note TEXT NOT NULL,
        media_path TEXT NOT NULL,
        media_key TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        status TEXT NOT NULL,
        error TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  String get _uid {
    final value = client?.auth.currentUser?.id;
    if (value == null) throw StateError('Official sign in required.');
    return value;
  }

  Future<bool> queueAction(
    String action, {
    String? target,
    Map<String, dynamic> payload = const {},
  }) async {
    final actor = _uid;
    final id = uuid.v4();
    await database.insert('staff_action_outbox', {
      'request_id': id,
      'actor_uid': actor,
      'action': action,
      'target_id': target,
      'payload': jsonEncode(payload),
      'status': 'queued',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await flush();
    final rows = await database.query(
      'staff_action_outbox',
      where: 'request_id=?',
      whereArgs: [id],
    );
    final row = rows.single;
    if (row['status'] == 'rejected') throw StateError(row['error'].toString());
    return row['status'] == 'sent';
  }

  Future<bool> queueEvidence({
    required String taskId,
    required String note,
    required String imagePath,
  }) async {
    final actor = _uid;
    final id = uuid.v4();
    final png = imagePath.toLowerCase().endsWith('.png');
    final extension = png ? 'png' : 'jpg';
    final mime = png ? 'image/png' : 'image/jpeg';
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory('${root.path}/task_media');
    await folder.create(recursive: true);
    final savedPath = '${folder.path}/$id.$extension';
    await File(imagePath).copy(savedPath);
    await database.insert('task_evidence_outbox', {
      'request_id': id,
      'actor_uid': actor,
      'task_id': taskId,
      'note': note,
      'media_path': savedPath,
      'media_key': 'task/$actor/$id.$extension',
      'mime_type': mime,
      'status': 'queued',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await flush();
    final rows = await database.query(
      'task_evidence_outbox',
      where: 'request_id=?',
      whereArgs: [id],
    );
    final row = rows.single;
    if (row['status'] == 'rejected') throw StateError(row['error'].toString());
    return row['status'] == 'sent';
  }

  Future<void> flush() => _activeFlush ??= _flush().whenComplete(() {
    _activeFlush = null;
  });

  Future<void> _flush() async {
    final api = client;
    final actor = api?.auth.currentUser?.id;
    if (api == null || actor == null) return;
    final actions = await database.query(
      'staff_action_outbox',
      where: "actor_uid=? AND status='queued'",
      whereArgs: [actor],
      orderBy: 'created_at ASC',
    );
    for (final row in actions) {
      try {
        await api
            .rpc(
              'perform_mobile_action',
              params: {
                'p_request_id': row['request_id'],
                'p_action': row['action'],
                'p_target': row['target_id'],
                'p_payload': jsonDecode(row['payload'] as String),
              },
            )
            .timeout(const Duration(seconds: 25));
        await _mark('staff_action_outbox', row, 'sent');
      } on PostgrestException catch (error) {
        await _mark('staff_action_outbox', row, 'rejected', error.message);
        break;
      } catch (error) {
        await _mark('staff_action_outbox', row, 'queued', error.toString());
        return;
      }
    }
    final evidence = await database.query(
      'task_evidence_outbox',
      where: "actor_uid=? AND status='queued'",
      whereArgs: [actor],
      orderBy: 'created_at ASC',
    );
    for (final row in evidence) {
      try {
        await api.storage
            .from('evidence')
            .upload(
              row['media_key'] as String,
              File(row['media_path'] as String),
              fileOptions: FileOptions(
                contentType: row['mime_type'] as String,
                upsert: true,
              ),
            )
            .timeout(const Duration(seconds: 30));
        await api
            .rpc(
              'submit_task_evidence',
              params: {
                'p_task_id': row['task_id'],
                'p_note': row['note'],
                'p_media_key': row['media_key'],
                'p_mime_type': row['mime_type'],
              },
            )
            .timeout(const Duration(seconds: 25));
        await _mark('task_evidence_outbox', row, 'sent');
      } on PostgrestException catch (error) {
        await _mark('task_evidence_outbox', row, 'rejected', error.message);
      } on StorageException catch (error) {
        final status = error.statusCode ?? '';
        if (['400', '401', '403', '404'].contains(status)) {
          await _mark('task_evidence_outbox', row, 'rejected', error.message);
        } else {
          await _mark('task_evidence_outbox', row, 'queued', error.message);
          return;
        }
      } catch (error) {
        await _mark('task_evidence_outbox', row, 'queued', error.toString());
        return;
      }
    }
  }

  Future<void> _mark(
    String table,
    OutboxRow row,
    String status, [
    String? error,
  ]) async {
    await database.update(
      table,
      {'status': status, 'error': error},
      where: 'request_id=?',
      whereArgs: [row['request_id']],
    );
  }

  Future<List<OutboxRow>> pending() async {
    final actor = _uid;
    final actions = await database.query(
      'staff_action_outbox',
      where: "actor_uid=? AND status<>'sent'",
      whereArgs: [actor],
    );
    final evidence = await database.query(
      'task_evidence_outbox',
      where: "actor_uid=? AND status<>'sent'",
      whereArgs: [actor],
    );
    return [
      for (final row in actions) {...row, 'kind': 'action'},
      for (final row in evidence) {...row, 'kind': 'evidence'},
    ]..sort(
      (a, b) =>
          (a['created_at'] as String).compareTo(b['created_at'] as String),
    );
  }

  Future<void> discard(String kind, String requestId) async {
    final table = kind == 'evidence'
        ? 'task_evidence_outbox'
        : 'staff_action_outbox';
    if (kind == 'evidence') {
      final rows = await database.query(
        table,
        columns: ['media_path'],
        where: 'request_id=? AND actor_uid=?',
        whereArgs: [requestId, _uid],
      );
      if (rows.isNotEmpty) {
        final file = File(rows.single['media_path'] as String);
        if (await file.exists()) await file.delete();
      }
    }
    await database.delete(
      table,
      where: 'request_id=? AND actor_uid=?',
      whereArgs: [requestId, _uid],
    );
  }

  Future<void> retry(String kind, String requestId) async {
    final table = kind == 'evidence'
        ? 'task_evidence_outbox'
        : 'staff_action_outbox';
    await database.update(
      table,
      {'status': 'queued', 'error': null},
      where: "request_id=? AND actor_uid=? AND status='rejected'",
      whereArgs: [requestId, _uid],
    );
    await flush();
  }
}
