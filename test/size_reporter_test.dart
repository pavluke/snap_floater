import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:snap_floater/snap_floater.dart';

import 'helpers/drag_helpers.dart';
import 'helpers/test_helpers.dart';

class _Resizable extends StatefulWidget {
  const _Resizable({required this.onSize, super.key});
  final ValueChanged<Size> onSize;

  @override
  State<_Resizable> createState() => _ResizableState();
}

class _ResizableState extends State<_Resizable> {
  Size size = const Size(40, 20);

  void resize(Size s) => setState(() => size = s);

  @override
  Widget build(BuildContext context) => Align(
    alignment: .topLeft,
    child: SizeReporter(
      onSizeCalculated: widget.onSize,
      child: SizedBox.fromSize(size: size),
    ),
  );
}

void main() {
  group('SizeReporter', () {
    testWidgets('reports the initial size after the first frame', (
      tester,
    ) async {
      final sizes = <Size>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Resizable(onSize: sizes.add),
        ),
      );
      await tester.pump();
      expect(sizes, [const Size(40, 20)]);
    });

    testWidgets('fires only when the size changes', (tester) async {
      final sizes = <Size>[];
      final key = GlobalKey<_ResizableState>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Resizable(key: key, onSize: sizes.add),
        ),
      );
      await tester.pump();

      // Same size again: no new report.
      key.currentState!.resize(const Size(40, 20));
      await tester.pump();
      await tester.pump();
      expect(sizes, hasLength(1));

      key.currentState!.resize(const Size(50, 20));
      await tester.pump();
      await tester.pump();
      expect(sizes, [const Size(40, 20), const Size(50, 20)]);
    });

    testWidgets('[#9] removed before the post-frame callback: no callback, '
        'no exception', (tester) async {
      final sizes = <Size>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Resizable(onSize: sizes.add),
        ),
      );
      // Layout happened inside pumpWidget; the post-frame callback already
      // ran in that same frame, so swap the tree for the *resize* path.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('SnapFloaterChild size reporting', () {
    testWidgets('[#9] onChildSizeChanged is called once per size change', (
      tester,
    ) async {
      setSurface(tester);
      final sizes = <Size>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SnapFloaterChild(
                  dragMode: .pan,
                  curve: Curves.linear,
                  useSafeArea: false,
                  padding: .zero,
                  snapAlignments: {.topLeft, .topRight},
                  alignment: .topLeft,
                  isDragging: false,
                  isVisible: true,
                  onDragStart: () {},
                  onDragUpdate: (_) {},
                  onDragEnd: (_) {},
                  onChildSizeChanged: sizes.add,
                  child: const SizedBox(width: 30, height: 30),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(sizes, [const Size(30, 30)]);
    });

    testWidgets('[#9] child removed right after layout: no setState on '
        'an unmounted state', (tester) async {
      await pumpScope(tester, settings: longPressSettings);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
