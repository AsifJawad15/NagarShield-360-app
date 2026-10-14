import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../nagar_repository.dart';
import 'annotation_editor.dart';
import 'survey_annotation_editor.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key, required this.repository, required this.bangla});
  final NagarRepository repository;
  final bool bangla;

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final area = TextEditingController();
  final site = TextEditingController();
  final permission = TextEditingController();
  final notes = TextEditingController();
  final title = TextEditingController();
  final description = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  String kind = 'drone';
  String captureSource = 'imported';
  String category = 'DRAIN_OBSTRUCTION';
  File? media;
  List<AnnotationBox> boxes = [];
  List<ManualAnnotation> extraAnnotations = [];
  bool polygonMode = false;
  bool busy = false;
  String? result;

  static const categories = [
    'DRAIN_OBSTRUCTION',
    'STANDING_WATER',
    'WASTE',
    'FOOTPATH_OBSTRUCTION',
    'ACCESS_OBSTRUCTION',
    'WATER_CONTAINER',
  ];

  String t(String en, String bn) => widget.bangla ? bn : en;

  Future<void> _pick() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4'],
    );
    if (picked == null || picked.files.single.path == null) return;
    final file = File(picked.files.single.path!);
    if (await file.length() > 50 * 1024 * 1024) {
      setState(
        () => result = t(
          'Maximum file size is 50 MB.',
          'সর্বোচ্চ ফাইলের আকার ৫০ MB।',
        ),
      );
      return;
    }
    setState(() {
      media = file;
      boxes = [];
      extraAnnotations = [];
      result = null;
    });
  }

  Future<void> _gps() async {
    try {
      var status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        status = await Geolocator.requestPermission();
      }
      if (status == LocationPermission.denied ||
          status == LocationPermission.deniedForever) {
        throw StateError('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition();
      latitude.text = position.latitude.toStringAsFixed(6);
      longitude.text = position.longitude.toStringAsFixed(6);
      setState(() => result = null);
    } catch (error) {
      setState(() => result = error.toString());
    }
  }

  Future<void> _submit() async {
    final client = widget.repository.client;
    final user = widget.repository.user;
    final lat = double.tryParse(latitude.text.trim());
    final lng = double.tryParse(longitude.text.trim());
    if (client == null ||
        user == null ||
        media == null ||
        lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180 ||
        title.text.trim().length < 4 ||
        area.text.trim().length < 3 ||
        (kind == 'gapscan' && site.text.trim().length < 3) ||
        (captureSource == 'drone' && permission.text.trim().length < 3)) {
      setState(
        () => result = t(
          'Complete the required survey fields.',
          'জরিপের প্রয়োজনীয় তথ্য পূরণ করুন।',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      result = null;
    });
    try {
      final extension = media!.path.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'mp4' => 'video/mp4',
        _ => 'image/jpeg',
      };
      final requestId = const Uuid().v4();
      final key = 'survey/${user.id}/$requestId.$extension';
      await client.storage
          .from('evidence')
          .upload(key, media!, fileOptions: FileOptions(contentType: mime));
      final missionId = await client.rpc(
        'create_survey_mission',
        params: {
          'p_kind': kind,
          'p_area': area.text.trim(),
          'p_site': site.text.trim(),
          'p_capture_source': captureSource,
          'p_captured_at': DateTime.now().toUtc().toIso8601String(),
          'p_permission_ref': permission.text.trim(),
          'p_notes': notes.text.trim(),
        },
      );
      final observationId = await client.rpc(
        'submit_survey_observation',
        params: {
          'p_request_id': requestId,
          'p_mission_id': missionId,
          'p_title': title.text.trim(),
          'p_description': description.text.trim(),
          'p_category': category,
          'p_lat': lat,
          'p_lng': lng,
          'p_media_key': key,
          'p_mime_type': mime,
        },
      );
      if (boxes.isNotEmpty || extraAnnotations.isNotEmpty) {
        final asset = await client
            .from('media_assets')
            .select('id')
            .eq('observation_id', observationId)
            .single();
        for (final box in boxes) {
          await client.rpc(
            'save_media_annotation',
            params: {
              'p_media_id': asset['id'],
              'p_label': box.label,
              'p_shape': 'box',
              'p_points': box.toCoordinates(),
              'p_from_ms': null,
              'p_to_ms': null,
            },
          );
        }
        for (final annotation in extraAnnotations) {
          await client.rpc(
            'save_media_annotation',
            params: {
              'p_media_id': asset['id'],
              'p_label': annotation.label,
              'p_shape': annotation.shape,
              'p_points': annotation.points,
              'p_from_ms': annotation.fromMs,
              'p_to_ms': annotation.toMs,
            },
          );
        }
      }
      if (mounted) {
        setState(
          () => result = t(
            'Observation sent for human review.',
            'পর্যবেক্ষণটি মানব যাচাইয়ের জন্য পাঠানো হয়েছে।',
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => result = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      area,
      site,
      permission,
      notes,
      title,
      description,
      latitude,
      longitude,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        color: const Color(0xFFFFF2D8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            t(
              'Survey observations are reviewed by an official. This demo does not fly a drone or run live AI detection.',
              'জরিপে পাওয়া সমস্যাও কর্মকর্তা যাচাই করেন। এই ডেমো দিয়ে ড্রোন চালানো বা সরাসরি AI শনাক্তকরণ হয় না।',
            ),
          ),
        ),
      ),
      if (result != null)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(result!),
          ),
        ),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'drone', label: Text('Drone')),
          ButtonSegment(value: 'gapscan', label: Text('GapScan')),
        ],
        selected: {kind},
        onSelectionChanged: (value) => setState(() => kind = value.first),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: area,
        decoration: InputDecoration(
          labelText: t('Survey area', 'জরিপ এলাকা'),
          border: const OutlineInputBorder(),
        ),
      ),
      if (kind == 'gapscan') ...[
        const SizedBox(height: 10),
        TextField(
          controller: site,
          decoration: InputDecoration(
            labelText: t('Gap site label', 'গলির স্থান চিহ্ন'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: captureSource,
        decoration: InputDecoration(
          labelText: t('Capture source', 'ছবির উৎস'),
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'drone', child: Text('Drone')),
          DropdownMenuItem(value: 'phone', child: Text('Phone')),
          DropdownMenuItem(value: '360', child: Text('360 camera')),
          DropdownMenuItem(value: 'imported', child: Text('Imported')),
        ],
        onChanged: (value) => setState(() => captureSource = value!),
      ),
      if (captureSource == 'drone') ...[
        const SizedBox(height: 10),
        TextField(
          controller: permission,
          decoration: InputDecoration(
            labelText: t(
              'Flight permission reference',
              'উড়ানের অনুমতির রেফারেন্স',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 10),
      TextField(
        controller: notes,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: t('Mission notes', 'জরিপ নোট'),
          border: const OutlineInputBorder(),
        ),
      ),
      const Divider(height: 28),
      TextField(
        controller: title,
        decoration: InputDecoration(
          labelText: t('Observation title', 'পর্যবেক্ষণের শিরোনাম'),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: description,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: t('Visible condition', 'দৃশ্যমান অবস্থা'),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: category,
        items: [
          for (final value in categories)
            DropdownMenuItem(value: value, child: Text(value)),
        ],
        onChanged: (value) => setState(() => category = value!),
      ),
      OutlinedButton.icon(
        onPressed: _gps,
        icon: const Icon(Icons.my_location),
        label: Text(t('Use current location', 'বর্তমান অবস্থান নিন')),
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: latitude,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: longitude,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.file_open),
        label: Text(
          media == null
              ? t('Attach image or MP4', 'ছবি বা MP4 যোগ করুন')
              : media!.path.split(Platform.pathSeparator).last,
        ),
      ),
      if (media != null && !media!.path.toLowerCase().endsWith('.mp4')) ...[
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(t('Boxes', 'বক্স'))),
            ButtonSegment(value: true, label: Text(t('Polygon', 'পলিগন'))),
          ],
          selected: {polygonMode},
          onSelectionChanged: (value) =>
              setState(() => polygonMode = value.first),
        ),
        Text(
          t(
            polygonMode
                ? 'Tap at least three points around a visible concern.'
                : 'Drag on the image to mark visible concerns.',
            polygonMode
                ? 'দৃশ্যমান সমস্যার চারপাশে অন্তত তিনটি পয়েন্টে চাপুন।'
                : 'দৃশ্যমান সমস্যা চিহ্নিত করতে ছবিতে টানুন।',
          ),
        ),
        if (polygonMode)
          PolygonAnnotationEditor(
            key: ValueKey('polygon-${media!.path}'),
            file: media!,
            bangla: widget.bangla,
            onAdd: (value) => setState(() => extraAnnotations.add(value)),
          )
        else
          SizedBox(
            height: 250,
            child: EditableAnnotations(
              key: ValueKey(media!.path),
              file: media!,
              onChanged: (value) => boxes = value,
            ),
          ),
      ],
      if (media != null && media!.path.toLowerCase().endsWith('.mp4'))
        TimedBoxEditor(
          key: ValueKey('video-${media!.path}'),
          file: media!,
          bangla: widget.bangla,
          onAdd: (value) => setState(() => extraAnnotations.add(value)),
        ),
      if (boxes.isNotEmpty || extraAnnotations.isNotEmpty)
        Text(
          t(
            '${boxes.length + extraAnnotations.length} manual annotations ready',
            '${boxes.length + extraAnnotations.length}টি ম্যানুয়াল চিহ্ন প্রস্তুত',
          ),
        ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: busy ? null : _submit,
        child: Text(
          busy
              ? t('Submitting…', 'জমা হচ্ছে…')
              : t('Send for review', 'যাচাইয়ের জন্য পাঠান'),
        ),
      ),
    ],
  );
}
