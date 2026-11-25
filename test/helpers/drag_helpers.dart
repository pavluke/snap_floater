import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:snap_floater/snap_floater.dart';

import 'test_helpers.dart';

const List<Alignment> fourCorners = [
  .bottomRight, // initial
  .bottomLeft,
  .topRight,
  .topLeft,
];

const SnapFloaterSettings panSettings = SnapFloaterSettings(
  dragMode: FloaterDragMode.pan,
  snapAlignments: fourCorners,
);

const SnapFloaterSettings longPressSettings = SnapFloaterSettings(
  snapAlignments: fourCorners,
);

/// Puts a finger on the floater. In long-press mode also waits until the
/// long-press is recognized. In pan mode the drag starts on the first move.
Future<TestGesture> startDrag(WidgetTester tester, FloaterDragMode mode) async {
  final gesture = await tester.startGesture(tester.getCenter(floaterFinder));
  if (mode == .longPress) {
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  }
  return gesture;
}

class PreviewCall {
  const PreviewCall({
    required this.floaterSize,
    required this.currentOffset,
    required this.targetOffset,
    required this.isVisible,
    required this.isNearest,
  });

  final Size floaterSize;
  final Offset currentOffset;
  final Offset targetOffset;
  final bool isVisible;
  final bool isNearest;
}

/// A [PreviewBuilder] that records its arguments and renders nothing.
class PreviewRecorder {
  final List<PreviewCall> calls = <PreviewCall>[];

  Widget call(
    BuildContext context,
    Size floaterSize,
    Offset currentOffset,
    Offset targetOffset,
    bool isVisible,
    bool isNearest,
    Widget child,
  ) {
    calls.add(
      PreviewCall(
        floaterSize: floaterSize,
        currentOffset: currentOffset,
        targetOffset: targetOffset,
        isVisible: isVisible,
        isNearest: isNearest,
      ),
    );
    return const SizedBox.shrink();
  }
}

/// Scope built through `SnapFloaterScope.builder` with a recording preview.
Future<void> pumpRecordingScope(
  WidgetTester tester, {
  required PreviewRecorder recorder,
  SnapFloaterSettings settings = panSettings,
  Size size = defaultSurface,
}) async {
  setSurface(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => SnapFloaterScope.builder(
        builder: (_) => BasicSnapFloaterButton(() {}),
        previewBuilder: recorder.call,
        settings: settings,
        child: child,
      ),
      home: const Scaffold(body: SizedBox.expand(key: contentKey)),
    ),
  );
  await tester.pumpAndSettle();
}
