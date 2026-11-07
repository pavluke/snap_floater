// NOTE: SnapFloaterAnimation.blur is deliberately NOT referenced here — its
// signature does not match PreviewBuilder (#14) and referencing it as a
// PreviewBuilder is a compile error that would take this whole file down.
// See blur_signature_test.dart.

import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_floater/snap_floater.dart';

const _child = SizedBox(width: 20, height: 20, key: Key('preview_child'));

Widget _host(Widget preview) => Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [preview]),
    );

/// Painted width — `getSize` returns the layout size and ignores Transform.
double _paintedWidth(WidgetTester tester, Finder f) =>
    tester.getBottomRight(f).dx - tester.getTopLeft(f).dx;

double _opacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity;

void main() {
  group('PreviewBuilder signature', () {
    test('base / slide / pop are assignable to PreviewBuilder', () {
      const PreviewBuilder a = SnapFloaterAnimation.base;
      const PreviewBuilder b = SnapFloaterAnimation.slide;
      const PreviewBuilder c = SnapFloaterAnimation.pop;
      expect([a, b, c], hasLength(3));
    });
  });

  group('BaseAnimation', () {
    testWidgets('places child at targetOffset', (tester) async {
      await tester.pumpWidget(
        _host(
          const BaseAnimation(
            targetOffset: Offset(30, 40),
            isVisible: true,
            isNearest: true,
            child: _child,
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(_child.key!)), const Offset(30, 40));
    });

    testWidgets('opacity: hidden 0, nearest 0.8, others 0.25', (tester) async {
      Future<double> opacityFor(bool visible, bool nearest) async {
        await tester.pumpWidget(
          _host(
            BaseAnimation(
              targetOffset: Offset.zero,
              isVisible: visible,
              isNearest: nearest,
              child: _child,
            ),
          ),
        );
        await tester.pumpAndSettle();
        return _opacity(tester);
      }

      expect(await opacityFor(false, true), 0.0);
      expect(await opacityFor(true, true), 0.8);
      expect(await opacityFor(true, false), 0.25);
    });

    testWidgets('non-nearest preview is scaled down to 0.85', (tester) async {
      await tester.pumpWidget(
        _host(
          const BaseAnimation(
            targetOffset: Offset.zero,
            isVisible: true,
            isNearest: false,
            child: _child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.85);
    });
  });

  group('SlideFloaterAnimation', () {
    testWidgets('visible: ends at targetOffset', (tester) async {
      await tester.pumpWidget(
        _host(
          const SlideFloaterAnimation(
            currentOffset: Offset(300, 600),
            targetOffset: Offset(10, 10),
            isVisible: true,
            isNearest: true,
            child: _child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(_child.key!)), const Offset(10, 10));
    });

    testWidgets('hidden: stays at currentOffset', (tester) async {
      await tester.pumpWidget(
        _host(
          const SlideFloaterAnimation(
            currentOffset: Offset(300, 600),
            targetOffset: Offset(10, 10),
            isVisible: false,
            isNearest: true, // nearest => scale 1.0, so offsets are exact
            child: _child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(_child.key!)), const Offset(300, 600));
    });
  });

  group('PopFloaterAnimation', () {
    testWidgets('visible: settles at scale 1.0 (nearest)', (tester) async {
      await tester.pumpWidget(
        _host(
          const PopFloaterAnimation(
            targetOffset: Offset(5, 5),
            isVisible: true,
            isNearest: true,
            child: _child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_paintedWidth(tester, find.byKey(_child.key!)), closeTo(20, 0.01));
    });

    testWidgets('overshoots above 1.0 mid-animation', (tester) async {
      await tester.pumpWidget(
        _host(
          const PopFloaterAnimation(
            targetOffset: Offset.zero,
            isVisible: true,
            isNearest: true,
            popOvershoot: 1.5,
            child: _child,
          ),
        ),
      );
      var maxWidth = 0.0;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        final w = _paintedWidth(tester, find.byKey(_child.key!));
        if (w > maxWidth) maxWidth = w;
      }
      expect(maxWidth, greaterThan(20));
    });

    testWidgets('toggling isVisible does not throw / leak the ticker',
        (tester) async {
      Widget build(bool v) => _host(
            PopFloaterAnimation(
              targetOffset: Offset.zero,
              isVisible: v,
              isNearest: true,
              child: _child,
            ),
          );
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  });

  group('BlurFloaterAnimation (widget directly)', () {
    testWidgets('visible: ends fully sharp, hidden: ends fully blurred',
        (tester) async {
      Future<double> sigmaFor(bool visible) async {
        await tester.pumpWidget(
          _host(
            BlurFloaterAnimation(
              targetOffset: Offset.zero,
              isVisible: visible,
              isNearest: true,
              child: _child,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final filtered = tester.widgetList<ImageFiltered>(
          find.byType(ImageFiltered),
        );
        if (filtered.isEmpty) return 0;
        // ImageFilter has no public sigma getter; compare via toString.
        final s = filtered.first.imageFilter.toString();
        final m = RegExp(r'blur\(([\d.]+)').firstMatch(s);
        return m == null ? double.nan : double.parse(m.group(1)!);
      }

      expect(await sigmaFor(true), 0.0);
      expect(await sigmaFor(false), 12.0);
    });

    testWidgets('[#15] sigma == 0 should not leave an ImageFiltered layer',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const BlurFloaterAnimation(
            targetOffset: Offset.zero,
            isVisible: true,
            isNearest: true,
            child: _child,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(ImageFiltered),
        findsNothing,
        reason: 'a zero-sigma blur still allocates an offscreen layer for '
            'every preview on every frame',
      );
    });

    // Keeps the import used even if the regex above changes.
    test('ImageFilter.blur is constructible', () {
      expect(ImageFilter.blur(sigmaX: 1, sigmaY: 1), isNotNull);
    });
  });
}
