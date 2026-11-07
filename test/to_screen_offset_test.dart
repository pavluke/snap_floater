import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_floater/snap_floater.dart';

/// Pumps a [MediaQuery] of [screen] size and returns a context below it.
Future<BuildContext> contextWithScreen(WidgetTester tester, Size screen) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: screen),
      child: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  const button = Size(60, 60);
  const padding = EdgeInsets.all(10);
  const screen = Size(400, 800);

  group('AlignmentToScreenOffsetX.toScreenOffset', () {
    testWidgets('corners respect padding', (tester) async {
      final ctx = await contextWithScreen(tester, screen);

      Offset at(Alignment a) =>
          a.toScreenOffset(ctx, targetSize: button, padding: padding);

      expect(at(Alignment.topLeft), const Offset(10, 10));
      expect(at(Alignment.topRight), const Offset(400 - 60 - 10, 10));
      expect(at(Alignment.bottomLeft), const Offset(10, 800 - 60 - 10));
      expect(
        at(Alignment.bottomRight),
        const Offset(400 - 60 - 10, 800 - 60 - 10),
      );
    });

    testWidgets('center places the widget in the middle of the screen', (
      tester,
    ) async {
      final ctx = await contextWithScreen(tester, screen);
      final o = Alignment.center.toScreenOffset(
        ctx,
        targetSize: button,
        padding: padding,
      );
      expect(o, const Offset(200 - 30, 400 - 30));
    });

    testWidgets('out-of-range alignment is clamped', (tester) async {
      final ctx = await contextWithScreen(tester, screen);
      final o = const Alignment(
        5,
        -5,
      ).toScreenOffset(ctx, targetSize: button, padding: padding);
      expect(o, const Offset(400 - 60 - 10, 10));
    });

    testWidgets('zero target size (first frame) does not throw', (
      tester,
    ) async {
      final ctx = await contextWithScreen(tester, screen);
      expect(
        () => Alignment.bottomRight.toScreenOffset(
          ctx,
          targetSize: Size.zero,
          padding: padding,
        ),
        returnsNormally,
      );
    });

    testWidgets('[#17] screen smaller than button + padding does not throw', (
      tester,
    ) async {
      final ctx = await contextWithScreen(tester, const Size(50, 50));
      expect(
        () => Alignment.center.toScreenOffset(
          ctx,
          targetSize: button,
          padding: padding,
        ),
        returnsNormally,
        reason:
            'num.clamp throws ArgumentError when min > max '
            '(split-screen / tiny window)',
      );
    });

    testWidgets('[#17] result stays finite on a degenerate screen', (
      tester,
    ) async {
      final ctx = await contextWithScreen(tester, Size.zero);
      final o = Alignment.center.toScreenOffset(
        ctx,
        targetSize: button,
        padding: padding,
      );
      expect(o.dx.isFinite && o.dy.isFinite, isTrue);
    });

    testWidgets(
      '[#18] alignment is relative to the padded area (center of the area '
      'below the inset, not of the full screen)',
      (tester) async {
        final ctx = await contextWithScreen(tester, screen);
        const asymmetric = EdgeInsets.only(top: 200);
        final o = Alignment.center.toScreenOffset(
          ctx,
          targetSize: button,
          padding: asymmetric,
        );
        // free height = 800 - 60 - 200 = 540 -> top = 200 + 270.
        expect(o.dy, 470);
      },
    );

    testWidgets('[visual] intermediate alignments are linear', (tester) async {
      final ctx = await contextWithScreen(tester, screen);
      Offset at(double x, double y) => Alignment(
        x,
        y,
      ).toScreenOffset(ctx, targetSize: button, padding: padding);

      // free width = 400 - 60 - 20 = 320, free height = 800 - 60 - 20 = 720.
      expect(
        at(-0.75, -0.75),
        const Offset(10 + 320 * 0.125, 10 + 720 * 0.125),
      );
      expect(at(0.75, 0.75), const Offset(10 + 320 * 0.875, 10 + 720 * 0.875));
      expect(at(0.5, 0), const Offset(10 + 320 * 0.75, 370));
    });

    testWidgets('[visual] values near the edge are not saturated', (
      tester,
    ) async {
      final ctx = await contextWithScreen(tester, screen);
      Offset at(double x) => Alignment(
        x,
        0,
      ).toScreenOffset(ctx, targetSize: button, padding: padding);

      expect(at(0.9).dx, lessThan(at(1).dx));
      expect(at(0.95).dx, greaterThan(at(0.9).dx));
    });
  });
}
