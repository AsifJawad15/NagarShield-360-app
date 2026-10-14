import 'dart:io';

import 'package:flutter/material.dart';

class AnnotationBox {
  const AnnotationBox(this.rect, this.label);
  final Rect rect;
  final String label;

  List<double> toCoordinates() => [
    rect.left,
    rect.top,
    rect.width,
    rect.height,
  ];
}

class EditableAnnotations extends StatefulWidget {
  const EditableAnnotations({
    super.key,
    required this.file,
    required this.onChanged,
    this.initialBoxes = const [],
  });
  final File file;
  final ValueChanged<List<AnnotationBox>> onChanged;
  final List<AnnotationBox> initialBoxes;

  @override
  State<EditableAnnotations> createState() => _EditableAnnotationsState();
}

class _EditableAnnotationsState extends State<EditableAnnotations> {
  final boxes = <AnnotationBox>[];
  Offset? start;
  Offset? end;

  @override
  void initState() {
    super.initState();
    boxes.addAll(widget.initialBoxes);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      Offset normalized(Offset value) => Offset(
        (value.dx / constraints.maxWidth).clamp(0, 1),
        (value.dy / constraints.maxHeight).clamp(0, 1),
      );
      return GestureDetector(
        onPanStart: (details) =>
            setState(() => start = end = normalized(details.localPosition)),
        onPanUpdate: (details) =>
            setState(() => end = normalized(details.localPosition)),
        onPanEnd: (_) {
          if (start == null || end == null) return;
          final rect = Rect.fromPoints(start!, end!);
          if (rect.width > .01 && rect.height > .01) {
            boxes.add(AnnotationBox(rect, 'Manual observation'));
            widget.onChanged(List.of(boxes));
          }
          setState(() {
            start = null;
            end = null;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(widget.file, fit: BoxFit.fill),
            CustomPaint(
              painter: AnnotationPainter(
                boxes: [
                  ...boxes,
                  if (start != null && end != null)
                    AnnotationBox(Rect.fromPoints(start!, end!), 'Manual'),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class AnnotationPainter extends CustomPainter {
  const AnnotationPainter({required this.boxes, this.fill = false});
  final List<AnnotationBox> boxes;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in boxes) {
      final rect = Rect.fromLTWH(
        box.rect.left * size.width,
        box.rect.top * size.height,
        box.rect.width * size.width,
        box.rect.height * size.height,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = fill ? const Color(0x6637C8A2) : const Color(0xFF37C8A2)
          ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: box.label,
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: Color(0xFF174D3C),
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(rect.left, rect.top));
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) =>
      oldDelegate.boxes != boxes || oldDelegate.fill != fill;
}
