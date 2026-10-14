import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../nagar_repository.dart';
import 'annotation_editor.dart';
import 'preset_media.dart';
import 'survey_annotation_editor.dart';

class MediaStudio extends StatefulWidget {
  const MediaStudio({
    super.key,
    required this.repository,
    required this.bangla,
  });
  final NagarRepository repository;
  final bool bangla;

  @override
  State<MediaStudio> createState() => _MediaStudioState();
}

class _MediaStudioState extends State<MediaStudio> {
  late Future<List<RowData>> scenarios;
  RowData? selected;
  File? imported;
  VideoPlayerController? video;
  String mode = 'detection';
  List<AnnotationBox> manual = [];
  List<ManualAnnotation> timed = [];
  List<RowData> savedImports = [];
  String? importId;
  Future<void> savePending = Future.value();

  @override
  void initState() {
    super.initState();
    scenarios = widget.repository.scenarios();
    _loadImports();
  }

  Future<void> _loadImports() async {
    final rows = await widget.repository.studioImports();
    if (mounted) setState(() => savedImports = rows);
  }

  Future<void> _selectImport(RowData row) async {
    await video?.dispose();
    video = null;
    final file = File(row['media_path'] as String);
    if (!await file.exists()) return;
    final entries = (jsonDecode(row['annotations'] as String) as List)
        .cast<Map>();
    final restoredBoxes = <AnnotationBox>[];
    final restoredTimed = <ManualAnnotation>[];
    for (final entry in entries) {
      final points = (entry['points'] as List)
          .map((value) => (value as num).toDouble())
          .toList();
      if (entry['from_ms'] == null) {
        restoredBoxes.add(
          AnnotationBox(
            Rect.fromLTWH(points[0], points[1], points[2], points[3]),
            entry['label'] as String,
          ),
        );
      } else {
        restoredTimed.add(
          ManualAnnotation.box(
            label: entry['label'] as String,
            coordinates: points,
            fromMs: entry['from_ms'] as int,
            toMs: entry['to_ms'] as int,
          ),
        );
      }
    }
    if (file.path.toLowerCase().endsWith('.mp4')) {
      video = VideoPlayerController.file(file);
      await video!.initialize();
      video!.addListener(() {
        if (mounted && video?.value.isPlaying == true) setState(() {});
      });
    }
    if (mounted) {
      setState(() {
        imported = file;
        importId = row['id'] as String;
        selected = null;
        manual = restoredBoxes;
        timed = restoredTimed;
        mode = 'raw';
      });
    }
  }

  Future<void> _saveAnnotations() {
    if (importId == null) return Future.value();
    final id = importId!;
    final snapshot = <RowData>[
      for (final box in manual)
        {'label': box.label, 'points': box.toCoordinates()},
      for (final item in timed)
        {
          'label': item.label,
          'points': item.points,
          'from_ms': item.fromMs,
          'to_ms': item.toMs,
        },
    ];
    savePending = savePending.then((_) async {
      await widget.repository.saveStudioAnnotations(id, snapshot);
      await _loadImports();
    });
    return savePending;
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    if (await file.length() > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum file size: 50 MB')),
        );
      }
      return;
    }
    final row = await widget.repository.importStudioMedia(file.path);
    await _loadImports();
    await _selectImport(row);
  }

  @override
  void dispose() {
    video?.dispose();
    super.dispose();
  }

  String t(String en, String bn) => widget.bangla ? bn : en;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<RowData>>(
    future: scenarios,
    builder: (context, snapshot) {
      final items = snapshot.data ?? [];
      final current =
          selected ??
          (imported == null && items.isNotEmpty ? items.first : null);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFFFFF2D8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                t(
                  'SIMULATED OVERLAY · Manual marks are not AI predictions.',
                  'নমুনা চিহ্ন · এখানে দেখানো দাগ হাতে দেওয়া, AI-এর ফল নয়।',
                ),
              ),
            ),
          ),
          Text(
            t('Demo Media Studio', 'ডেমো মিডিয়া স্টুডিও'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                ChoiceChip(
                  label: Text(item['title_bn'].toString()),
                  selected:
                      imported == null &&
                      (selected?['id'] ?? items.first['id']) == item['id'],
                  onSelected: (_) async {
                    await video?.dispose();
                    video = null;
                    setState(() {
                      imported = null;
                      importId = null;
                      selected = item;
                      manual = [];
                      timed = [];
                      mode = 'detection';
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _import,
            icon: const Icon(Icons.file_open),
            label: Text(t('Import image or MP4', 'ছবি বা MP4 ভিডিও নিন')),
          ),
          if (savedImports.isNotEmpty) ...[
            Text(
              t('Saved imports on this device', 'এই ডিভাইসে সংরক্ষিত মিডিয়া'),
            ),
            for (final row in savedImports)
              ListTile(
                title: Text(
                  (row['media_path'] as String)
                      .split(Platform.pathSeparator)
                      .last,
                ),
                subtitle: Text(row['created_at'].toString().split('T').first),
                selected: row['id'] == importId,
                onTap: () => _selectImport(row),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: t('Delete import', 'মিডিয়া মুছুন'),
                  onPressed: () async {
                    await widget.repository.deleteStudioImport(
                      row['id'] as String,
                    );
                    if (row['id'] == importId) {
                      await video?.dispose();
                      video = null;
                      if (mounted) {
                        setState(() {
                          imported = null;
                          importId = null;
                          manual = [];
                          timed = [];
                        });
                      }
                    }
                    await _loadImports();
                  },
                ),
              ),
          ],
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'raw', label: Text('Raw')),
              ButtonSegment(value: 'detection', label: Text('Boxes')),
              ButtonSegment(value: 'segmentation', label: Text('Masks')),
              ButtonSegment(value: 'incident', label: Text('Action')),
            ],
            selected: {mode},
            onSelectionChanged: (value) => setState(() => mode = value.first),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFFDBE7DA)),
                  if (imported != null &&
                      !imported!.path.toLowerCase().endsWith('.mp4'))
                    Image.file(imported!, fit: BoxFit.fill),
                  if (video != null && video!.value.isInitialized)
                    VideoPlayer(video!),
                  if (imported == null && current != null)
                    PresetMedia(
                      id: current['id'].toString(),
                      isVideo: current['kind'] == 'video',
                      bangla: widget.bangla,
                    ),
                  if (mode == 'detection' || mode == 'segmentation')
                    CustomPaint(
                      painter: AnnotationPainter(
                        boxes: imported != null
                            ? [...manual, ..._activeVideoBoxes()]
                            : _presetBoxes(current),
                        fill: mode == 'segmentation',
                      ),
                    ),
                  const Positioned(
                    left: 8,
                    top: 8,
                    child: Chip(label: Text('SIMULATED / MANUAL')),
                  ),
                ],
              ),
            ),
          ),
          if (video != null)
            TextButton.icon(
              onPressed: () {
                video!.value.isPlaying ? video!.pause() : video!.play();
                setState(() {});
              },
              icon: Icon(
                video!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(video!.value.isPlaying ? 'Pause' : 'Play'),
            ),
          if (imported != null && video == null) ...[
            Text(
              t('Drag to draw a manual box:', 'ম্যানুয়াল বক্স আঁকতে টানুন:'),
            ),
            SizedBox(
              height: 260,
              child: EditableAnnotations(
                key: ValueKey('${imported!.path}-${manual.length}'),
                file: imported!,
                initialBoxes: manual,
                onChanged: (boxes) {
                  setState(() => manual = boxes);
                  unawaited(_saveAnnotations());
                },
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => manual = []);
                unawaited(_saveAnnotations());
              },
              child: Text(t('Clear boxes', 'বক্স মুছুন')),
            ),
          ],
          if (imported != null && video != null) ...[
            Text(
              t(
                'Add manual boxes with normalized coordinates and a video time range.',
                'ভিডিওর সময়সীমা ও অনুপাতভিত্তিক স্থানাঙ্ক দিয়ে ম্যানুয়াল বক্স যোগ করুন।',
              ),
            ),
            TimedBoxEditor(
              key: ValueKey(imported!.path),
              file: imported!,
              bangla: widget.bangla,
              onAdd: (annotation) {
                setState(() => timed.add(annotation));
                unawaited(_saveAnnotations());
              },
            ),
            for (final annotation in timed)
              ListTile(
                title: Text(annotation.label),
                subtitle: Text(
                  '${annotation.fromMs}–${annotation.toMs} ms · ${annotation.points}',
                ),
              ),
          ],
          if (current != null) ...[
            const SizedBox(height: 12),
            Text(current['summary_bn'].toString()),
            Text('${t('Area', 'এলাকা')}: ${current['area_bn']}'),
            Text(
              t(
                'An authorised official decides whether this '
                    'observation becomes an incident.',
                'পর্যবেক্ষণটি ঘটনা হবে কি না, দায়িত্বপ্রাপ্ত কর্মকর্তা ঠিক করেন।',
              ),
            ),
            if (mode == 'incident')
              FilledButton(
                onPressed: () async {
                  try {
                    final sent = await widget.repository.workflow(
                      'create_observation',
                      payload: {'scenario_id': current['id']},
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            sent
                                ? t(
                                    'Sent to human review',
                                    'মানব যাচাইয়ে পাঠানো হয়েছে',
                                  )
                                : t(
                                    'Saved for sync when connected',
                                    'সংযোগ ফিরলে পাঠানো হবে',
                                  ),
                          ),
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
                child: Text(t('Create observation', 'পর্যবেক্ষণ তৈরি করুন')),
              ),
          ],
          if (imported != null)
            Text(
              t(
                'Imported media and manual annotations are saved on this device. Use Surveys to submit an observation for review.',
                'আমদানি করা মিডিয়া ও ম্যানুয়াল চিহ্ন এই ডিভাইসে সংরক্ষিত। যাচাইয়ের জন্য জরিপ থেকে পর্যবেক্ষণ জমা দিন।',
              ),
            ),
        ],
      );
    },
  );

  List<AnnotationBox> _presetBoxes(RowData? scenario) {
    if (scenario == null) return [];
    final detections = scenario['detections'];
    if (detections is! List) return [];
    return [
      for (final value in detections)
        if (value is Map &&
            value['box'] is List &&
            (value['box'] as List).length == 4)
          AnnotationBox(
            Rect.fromLTWH(
              ((value['box'] as List)[0] as num).toDouble() / 100,
              ((value['box'] as List)[1] as num).toDouble() / 100,
              ((value['box'] as List)[2] as num).toDouble() / 100,
              ((value['box'] as List)[3] as num).toDouble() / 100,
            ),
            value['label_bn']?.toString() ?? 'Detection',
          ),
    ];
  }

  List<AnnotationBox> _activeVideoBoxes() {
    final position = video?.value.position.inMilliseconds;
    if (position == null) return [];
    return [
      for (final item in timed)
        if (item.shape == 'box' &&
            position >= (item.fromMs ?? 0) &&
            position <= (item.toMs ?? 0))
          AnnotationBox(
            Rect.fromLTWH(
              (item.points as List<double>)[0],
              (item.points as List<double>)[1],
              (item.points as List<double>)[2],
              (item.points as List<double>)[3],
            ),
            item.label,
          ),
    ];
  }
}
