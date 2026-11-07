import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_floater/snap_floater.dart';

import 'helpers/drag_helpers.dart';
import 'helpers/test_helpers.dart';

/// [#14] Kept in its own file on purpose.
///
/// `SnapFloaterAnimation.blur` declares its parameters as
/// `(bool isNearest, bool isVisible, BuildContext context, ...)`, while
/// [PreviewBuilder] is `(BuildContext, Size, Offset, Offset, bool, bool, Widget)`.
/// Assigning it to a [PreviewBuilder] is therefore a compile-time error, and the
/// whole file will fail to load until the signature is fixed.
void main() {
  test('[#14] SnapFloaterAnimation.blur is assignable to PreviewBuilder', () {
    const PreviewBuilder builder = SnapFloaterAnimation.blur;
    expect(builder, isNotNull);
  });

  testWidgets('[#14] blur works end-to-end as previewBuilder', (tester) async {
    setSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => SnapFloaterScope.builder(
          builder: (_) => BasicSnapFloaterButton(() {}),
          previewBuilder: SnapFloaterAnimation.blur,
          settings: panSettings,
          child: child,
        ),
        home: const Scaffold(body: SizedBox.expand(key: contentKey)),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await startDrag(tester, FloaterDragMode.pan);
    await gesture.moveBy(const Offset(-60, -60));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BlurFloaterAnimation), findsNWidgets(fourCorners.length));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
