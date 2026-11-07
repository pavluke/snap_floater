import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_floater/snap_floater.dart';

import 'helpers/drag_helpers.dart';
import 'helpers/test_helpers.dart';

void main() {
  for (final mode in FloaterDragMode.values) {
    final settings = mode == FloaterDragMode.pan ? panSettings : longPressSettings;

    group('drag [$mode]', () {
      testWidgets('starts at the first snap alignment, not dragging',
          (tester) async {
        await pumpScope(tester, settings: settings);
        expect(controllerOf(tester).alignment, Alignment.bottomRight);
        expect(controllerOf(tester).isDragging, isFalse);
      });

      testWidgets('isDragging is true while the finger is down and moving',
          (tester) async {
        await pumpScope(tester, settings: settings);
        final gesture = await startDrag(tester, mode);
        await gesture.moveBy(const Offset(-60, -60));
        await tester.pump();

        expect(controllerOf(tester).isDragging, isTrue);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(controllerOf(tester).isDragging, isFalse);
      });

      testWidgets('[visual] button follows the finger 1:1 while dragging',
          (tester) async {
        await pumpScope(tester, settings: settings);
        final gesture = await startDrag(tester, mode);
        await gesture.moveBy(const Offset(-60, -60));
        await tester.pump();
        final before = tester.getCenter(floaterFinder);

        await gesture.moveBy(const Offset(-100, -150));
        await tester.pump();
        final after = tester.getCenter(floaterFinder);

        expect(after.dx - before.dx, closeTo(-100, 0.5));
        expect(after.dy - before.dy, closeTo(-150, 0.5));
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('release near top-left snaps to topLeft', (tester) async {
        await pumpScope(tester, settings: settings);
        final gesture = await startDrag(tester, mode);
        await gesture.moveBy(const Offset(-60, -60));
        await tester.pump();
        await gesture.moveBy(const Offset(-600, -900));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(controllerOf(tester).alignment, Alignment.topLeft);
      });

      testWidgets('release near bottom-left snaps to bottomLeft',
          (tester) async {
        await pumpScope(tester, settings: settings);
        final gesture = await startDrag(tester, mode);
        await gesture.moveBy(const Offset(-60, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(-600, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(controllerOf(tester).alignment, Alignment.bottomLeft);
      });

      testWidgets('short drag returns to the starting corner', (tester) async {
        await pumpScope(tester, settings: settings);
        final gesture = await startDrag(tester, mode);
        await gesture.moveBy(const Offset(-30, -30));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(controllerOf(tester).alignment, Alignment.bottomRight);
      });

      testWidgets('final position is persisted to storage', (tester) async {
        final storage = FakeStorage();
        await pumpScope(
          tester,
          settings: SnapFloaterSettings(
            dragMode: mode,
            snapAlignments: fourCorners,
            storage: storage,
          ),
        );
        final gesture = await startDrag(tester, mode);
        await gesture.moveBy(const Offset(-60, -60));
        await tester.pump();
        await gesture.moveBy(const Offset(-600, -900));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(storage.writes.last.base.alignment, Alignment.topLeft);
      });

      testWidgets('single snap alignment: drag is disabled', (tester) async {
        await pumpScope(
          tester,
          settings: SnapFloaterSettings(
            dragMode: mode,
          ),
        );
        final gesture = await startDrag(tester, mode);
        await gesture.moveBy(const Offset(-200, -200));
        await tester.pump();
        expect(controllerOf(tester).isDragging, isFalse);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(controllerOf(tester).alignment, Alignment.bottomRight);
      });

      testWidgets(
        '[#7] gesture cancelled mid-drag (system gesture, route push, ...) '
        'must not leave isDragging == true',
        (tester) async {
          await pumpScope(tester, settings: settings);
          final gesture = await startDrag(tester, mode);
          await gesture.moveBy(const Offset(-80, -80));
          await tester.pump();
          expect(controllerOf(tester).isDragging, isTrue);

          await gesture.cancel();
          await tester.pumpAndSettle();

          expect(
            controllerOf(tester).isDragging,
            isFalse,
            reason: 'only onPanEnd / onLongPressEnd are wired; the *Cancel '
                'callbacks are not, so _dragEnd() is never called',
          );
        },
      );

      testWidgets(
        '[#7] after a cancelled drag the next drag still works',
        (tester) async {
          await pumpScope(tester, settings: settings);
          var gesture = await startDrag(tester, mode);
          await gesture.moveBy(const Offset(-80, -80));
          await tester.pump();
          await gesture.cancel();
          await tester.pumpAndSettle();

          gesture = await startDrag(tester, mode);
          await gesture.moveBy(const Offset(-60, 0));
          await tester.pump();
          await gesture.moveBy(const Offset(-600, 0));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(controllerOf(tester).isDragging, isFalse);
          expect(controllerOf(tester).alignment, Alignment.bottomLeft);
        },
      );

      testWidgets(
        '[#8] release in the same frame as the last move uses the latest '
        'position, not the position at the start of the drag',
        (tester) async {
          await pumpScope(tester, settings: settings);
          final gesture = await startDrag(tester, mode);
          await gesture.moveBy(const Offset(-60, 0));
          await tester.pump();

          // Move and release with NO frame in between: the widget has not been
          // rebuilt, so the closures captured at build time are still the
          // ones created for the *previous* position.
          await gesture.moveBy(const Offset(-600, 0));
          await gesture.up();
          await tester.pumpAndSettle();

          expect(controllerOf(tester).alignment, Alignment.bottomLeft);
        },
      );
    });
  }

  group('drag mode semantics', () {
    testWidgets('longPress mode: a quick swipe does not drag', (tester) async {
      await pumpScope(tester, settings: longPressSettings);
      final gesture = await tester.startGesture(tester.getCenter(floaterFinder));
      await gesture.moveBy(const Offset(-200, -200));
      await tester.pump();
      expect(controllerOf(tester).isDragging, isFalse);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controllerOf(tester).alignment, Alignment.bottomRight);
    });

    testWidgets('longPress mode: tap still triggers onPressed', (tester) async {
      var calls = 0;
      await pumpScope(
        tester,
        settings: longPressSettings,
        onPressed: () => calls++,
      );
      await tester.tap(floaterFinder);
      await tester.pumpAndSettle();
      expect(calls, 1);
    });

    testWidgets('pan mode: tap still triggers onPressed', (tester) async {
      var calls = 0;
      await pumpScope(tester, settings: panSettings, onPressed: () => calls++);
      await tester.tap(floaterFinder);
      await tester.pumpAndSettle();
      expect(calls, 1);
    });

    testWidgets('longPress held without moving does not change alignment',
        (tester) async {
      await pumpScope(tester, settings: longPressSettings);
      final gesture = await tester.startGesture(tester.getCenter(floaterFinder));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controllerOf(tester).alignment, Alignment.bottomRight);
      expect(controllerOf(tester).isDragging, isFalse);
    });
  });

  group('previews while dragging', () {
    testWidgets('previews are hidden at rest and visible during drag',
        (tester) async {
      final recorder = PreviewRecorder();
      await pumpRecordingScope(tester, recorder: recorder);

      expect(recorder.calls, isNotEmpty);
      expect(recorder.calls.every((c) => !c.isVisible), isTrue);

      final gesture = await startDrag(tester, FloaterDragMode.pan);
      await gesture.moveBy(const Offset(-60, -60));
      await tester.pump();

      expect(recorder.calls.last.isVisible, isTrue);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(recorder.calls.last.isVisible, isFalse);
    });

    testWidgets('one call per snap target, exactly one is nearest',
        (tester) async {
      final recorder = PreviewRecorder();
      await pumpRecordingScope(tester, recorder: recorder);

      final gesture = await startDrag(tester, FloaterDragMode.pan);
      await gesture.moveBy(const Offset(-60, -60));
      await tester.pump();
      recorder.calls.clear();
      await gesture.moveBy(const Offset(-10, -10));
      await tester.pump();

      final batch = recorder.calls.reversed.take(fourCorners.length).toList();
      expect(batch, hasLength(fourCorners.length));
      expect(batch.where((c) => c.isNearest), hasLength(1));
      expect(
        batch.map((c) => c.targetOffset).toSet(),
        hasLength(fourCorners.length),
        reason: 'each snap target gets a distinct offset',
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('nearest preview follows the finger', (tester) async {
      final recorder = PreviewRecorder();
      await pumpRecordingScope(tester, recorder: recorder);

      final gesture = await startDrag(tester, FloaterDragMode.pan);
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-600, 0));
      await tester.pump();

      final batch = recorder.calls.reversed.take(fourCorners.length).toList();
      final nearest = batch.singleWhere((c) => c.isNearest);
      // bottom-left target: x == padding (10), y near the bottom.
      expect(nearest.targetOffset.dx, lessThan(defaultSurface.width / 2));
      expect(nearest.targetOffset.dy, greaterThan(defaultSurface.height / 2));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('showPreview: false -> previewBuilder is never called',
        (tester) async {
      final recorder = PreviewRecorder();
      await pumpRecordingScope(
        tester,
        recorder: recorder,
        settings: const SnapFloaterSettings(
          dragMode: FloaterDragMode.pan,
          snapAlignments: fourCorners,
          showPreview: false,
        ),
      );
      final gesture = await startDrag(tester, FloaterDragMode.pan);
      await gesture.moveBy(const Offset(-60, -60));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(recorder.calls, isEmpty);
    });

    testWidgets('single snap alignment -> no previews', (tester) async {
      final recorder = PreviewRecorder();
      await pumpRecordingScope(
        tester,
        recorder: recorder,
        settings: const SnapFloaterSettings(
          dragMode: FloaterDragMode.pan,
        ),
      );
      expect(recorder.calls, isEmpty);
    });
  });
}
