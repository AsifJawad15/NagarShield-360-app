import 'package:flutter_test/flutter_test.dart';
import 'package:nagar_shield_360/ui/survey_annotation_editor.dart';

void main() {
  test('manual video boxes keep normalized coordinates and time', () {
    final annotation = ManualAnnotation.box(
      label: 'Visible obstruction',
      coordinates: [0.1, 0.2, 0.5, 0.3],
      fromMs: 250,
      toMs: 900,
    );
    expect(annotation.shape, 'box');
    expect(annotation.points, [0.1, 0.2, 0.5, 0.3]);
    expect(annotation.fromMs, 250);
    expect(annotation.toMs, 900);
  });

  test('invalid coordinates and time ranges are rejected', () {
    expect(
      () => ManualAnnotation.box(
        label: 'Too wide',
        coordinates: [0.8, 0.1, 0.4, 0.2],
      ),
      throwsArgumentError,
    );
    expect(
      () => ManualAnnotation.box(
        label: 'Bad time',
        coordinates: [0.1, 0.1, 0.3, 0.3],
        fromMs: 500,
        toMs: 200,
      ),
      throwsArgumentError,
    );
    expect(
      () => ManualAnnotation.polygon(
        label: 'Too few points',
        coordinates: [
          [0.1, 0.1],
          [0.8, 0.1],
        ],
      ),
      throwsArgumentError,
    );
  });
}
