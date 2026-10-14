import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ManualAnnotation {
  const ManualAnnotation({
    required this.shape,
    required this.label,
    required this.points,
    this.fromMs,
    this.toMs,
  });

  final String shape;
  final String label;
  final Object points;
  final int? fromMs;
  final int? toMs;

  static ManualAnnotation box({
    required String label,
    required List<double> coordinates,
    int? fromMs,
    int? toMs,
  }) {
    if (label.trim().length < 2 ||
        coordinates.length != 4 ||
        coordinates.any((value) => value < 0 || value > 1) ||
        coordinates[2] <= 0 ||
        coordinates[3] <= 0 ||
        coordinates[0] + coordinates[2] > 1 ||
        coordinates[1] + coordinates[3] > 1 ||
        (fromMs != null && (fromMs < 0 || toMs == null || toMs <= fromMs)) ||
        (fromMs == null && toMs != null)) {
      throw ArgumentError('Invalid normalized box or time range.');
    }
    return ManualAnnotation(
      shape: 'box',
      label: label.trim(),
      points: coordinates,
      fromMs: fromMs,
      toMs: toMs,
    );
  }

  static ManualAnnotation polygon({
    required String label,
    required List<List<double>> coordinates,
  }) {
    if (label.trim().length < 2 ||
        coordinates.length < 3 ||
        coordinates.any(
          (point) =>
              point.length != 2 || point.any((value) => value < 0 || value > 1),
        )) {
      throw ArgumentError('Invalid normalized polygon.');
    }
    return ManualAnnotation(
      shape: 'polygon',
      label: label.trim(),
      points: coordinates,
    );
  }
}

class PolygonAnnotationEditor extends StatefulWidget {
  const PolygonAnnotationEditor({
    super.key,
    required this.file,
    required this.bangla,
    required this.onAdd,
  });
  final File file;
  final bool bangla;
  final ValueChanged<ManualAnnotation> onAdd;

  @override
  State<PolygonAnnotationEditor> createState() =>
      _PolygonAnnotationEditorState();
}

class _PolygonAnnotationEditorState extends State<PolygonAnnotationEditor> {
  final points = <Offset>[];
  final label = TextEditingController(text: 'Manual polygon');

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 250,
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onTapDown: (details) {
              setState(
                () => points.add(
                  Offset(
                    (details.localPosition.dx / constraints.maxWidth).clamp(
                      0,
                      1,
                    ),
                    (details.localPosition.dy / constraints.maxHeight).clamp(
                      0,
                      1,
                    ),
                  ),
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(widget.file, fit: BoxFit.fill),
                CustomPaint(painter: _PolygonPainter(points)),
              ],
            ),
          ),
        ),
      ),
      TextField(
        controller: label,
        decoration: InputDecoration(
          labelText: widget.bangla ? 'পলিগনের লেবেল' : 'Polygon label',
        ),
      ),
      Row(
        children: [
          TextButton(
            onPressed: () => setState(points.clear),
            child: Text(widget.bangla ? 'পয়েন্ট মুছুন' : 'Clear points'),
          ),
          FilledButton(
            onPressed: points.length < 3
                ? null
                : () {
                    widget.onAdd(
                      ManualAnnotation.polygon(
                        label: label.text,
                        coordinates: points
                            .map((point) => [point.dx, point.dy])
                            .toList(),
                      ),
                    );
                    setState(points.clear);
                  },
            child: Text(
              widget.bangla
                  ? 'পলিগন যোগ করুন (${points.length})'
                  : 'Add polygon (${points.length})',
            ),
          ),
        ],
      ),
    ],
  );
}

class _PolygonPainter extends CustomPainter {
  const _PolygonPainter(this.points);
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF37C8A2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    if (points.isEmpty) return;
    final path = Path();
    path.moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    canvas.drawPath(path, paint);
    for (final point in points) {
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        5,
        Paint()..color = const Color(0xFF174D3C),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PolygonPainter oldDelegate) =>
      oldDelegate.points != points;
}

class TimedBoxEditor extends StatefulWidget {
  const TimedBoxEditor({
    super.key,
    required this.file,
    required this.bangla,
    required this.onAdd,
  });
  final File file;
  final bool bangla;
  final ValueChanged<ManualAnnotation> onAdd;

  @override
  State<TimedBoxEditor> createState() => _TimedBoxEditorState();
}

class _TimedBoxEditorState extends State<TimedBoxEditor> {
  late final VideoPlayerController video;
  final label = TextEditingController(text: 'Manual video box');
  final x = TextEditingController(text: '0.1');
  final y = TextEditingController(text: '0.1');
  final width = TextEditingController(text: '0.5');
  final height = TextEditingController(text: '0.5');
  final fromMs = TextEditingController(text: '0');
  final toMs = TextEditingController(text: '1000');
  String? error;

  @override
  void initState() {
    super.initState();
    video = VideoPlayerController.file(widget.file)
      ..initialize()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((Object value) {
            if (mounted) setState(() => error = value.toString());
          });
  }

  @override
  void dispose() {
    video.dispose();
    for (final controller in [label, x, y, width, height, fromMs, toMs]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _add() {
    try {
      final values = [
        x,
        y,
        width,
        height,
      ].map((controller) => double.parse(controller.text.trim())).toList();
      final annotation = ManualAnnotation.box(
        label: label.text,
        coordinates: values,
        fromMs: int.parse(fromMs.text.trim()),
        toMs: int.parse(toMs.text.trim()),
      );
      widget.onAdd(annotation);
      setState(() => error = null);
    } catch (value) {
      setState(() => error = value.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (video.value.isInitialized) ...[
        AspectRatio(
          aspectRatio: video.value.aspectRatio,
          child: VideoPlayer(video),
        ),
        TextButton.icon(
          onPressed: () {
            video.value.isPlaying ? video.pause() : video.play();
            setState(() {});
          },
          icon: Icon(video.value.isPlaying ? Icons.pause : Icons.play_arrow),
          label: Text(video.value.isPlaying ? 'Pause' : 'Play'),
        ),
      ] else if (error == null)
        const CircularProgressIndicator(),
      TextField(
        controller: label,
        decoration: const InputDecoration(labelText: 'Label'),
      ),
      Wrap(
        spacing: 8,
        children: [
          for (final pair in [
            ('x', x),
            ('y', y),
            ('width', width),
            ('height', height),
            ('from ms', fromMs),
            ('to ms', toMs),
          ])
            SizedBox(
              width: 120,
              child: TextField(
                controller: pair.$2,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: pair.$1),
              ),
            ),
        ],
      ),
      if (error != null)
        Text(error!, style: const TextStyle(color: Colors.red)),
      FilledButton(
        onPressed: _add,
        child: Text(
          widget.bangla ? 'সময় চিহ্নিত বক্স যোগ করুন' : 'Add timed box',
        ),
      ),
    ],
  );
}
