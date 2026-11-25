import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:snap_floater/snap_floater.dart';

void main() {
  group('SnapFloaterState', () {
    test('value equality and hashCode', () {
      const a = SnapFloaterState(alignment: .topLeft);
      const b = SnapFloaterState(alignment: .topLeft);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(isDragging: true), isFalse);
    });

    test('defaults', () {
      const s = SnapFloaterState(alignment: .center);
      expect(s.isVisible, isTrue);
      expect(s.isDragging, isFalse);
      expect(s.childSize, Size.zero);
    });

    test('copyWith replaces only given fields', () {
      const s = SnapFloaterState(
        alignment: .topLeft,
        isVisible: false,
        isDragging: true,
        childSize: Size(1, 2),
      );
      expect(s.copyWith(), s);
      expect(
        s.copyWith(alignment: .center).alignment,
        Alignment.center,
      );
      expect(s.copyWith(alignment: .center).isVisible, isFalse);
      expect(s.copyWith(isVisible: true).isVisible, isTrue);
      expect(s.copyWith(isDragging: false).isDragging, isFalse);
      expect(
        s.copyWith(childSize: const Size(3, 4)).childSize,
        const Size(3, 4),
      );
    });

    test('toString mentions every field', () {
      const s = SnapFloaterState(alignment: .topLeft);
      final text = s.toString();
      expect(text, contains('alignment'));
      expect(text, contains('isVisible'));
      expect(text, contains('isDragging'));
      expect(text, contains('childSize'));
    });
  });

  group('SnapFloaterSnapshot', () {
    test('JSON round trip', () {
      const s = SnapFloaterSnapshot(alignment: Alignment(-0.5, 0.25));
      expect(SnapFloaterSnapshot.fromJson(s.toJson()), s);
    });

    test('accepts integer JSON numbers', () {
      final s = SnapFloaterSnapshot.fromJson(const {'x': 1, 'y': -1});
      expect(s.alignment, Alignment.topRight);
    });

    test('equality, hashCode, copyWith', () {
      const a = SnapFloaterSnapshot(alignment: .topLeft);
      const b = SnapFloaterSnapshot(alignment: .topLeft);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a.copyWith(alignment: .center).alignment,
        Alignment.center,
      );
      expect(a.copyWith(), a);
    });

    test('missing key -> throws (documents contract for storage impls)', () {
      expect(
        () => SnapFloaterSnapshot.fromJson(const {'x': 1}),
        throwsA(anything),
      );
    });
  });

  group('SnapFloaterStorageModel', () {
    test('JSON round trip through nested snapshot', () {
      const m = SnapFloaterStorageModel(
        base: SnapFloaterSnapshot(alignment: .bottomLeft),
      );
      expect(m.toJson(), {
        'base': {'x': -1.0, 'y': 1.0},
      });
      expect(SnapFloaterStorageModel.fromJson(m.toJson()), m);
    });

    test('equality, hashCode, copyWith', () {
      const a = SnapFloaterStorageModel(
        base: SnapFloaterSnapshot(alignment: .topLeft),
      );
      const b = SnapFloaterStorageModel(
        base: SnapFloaterSnapshot(alignment: .topLeft),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a.copyWith(
          base: const SnapFloaterSnapshot(alignment: .center),
        ),
        isNot(a),
      );
    });
  });

  group('SnapFloaterSettings', () {
    test('defaults', () {
      const s = SnapFloaterSettings();
      expect(s.snapAlignments, const [Alignment.bottomRight]);
      expect(s.dragMode, FloaterDragMode.longPress);
      expect(s.isEnabled, isTrue);
      expect(s.showPreview, isTrue);
      expect(s.storage, isNull);
    });

    test('[misc] two non-const instances with equal content are equal', () {
      // Not const on purpose: const would canonicalize and hide the missing ==.
      const a = SnapFloaterSettings(
        snapAlignments: [.topLeft, .bottomRight],
      );
      const b = SnapFloaterSettings(
        snapAlignments: [.topLeft, .bottomRight],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
