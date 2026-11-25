import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:snap_floater/snap_floater.dart';

import 'helpers/test_helpers.dart';

const _twoTargets = <Alignment>[.bottomRight, .topLeft];

void main() {
  group('lookup', () {
    testWidgets('of() and maybeOf() return the scope controller', (
      tester,
    ) async {
      await pumpScope(tester);
      final ctx = tester.element(find.byKey(contentKey));
      expect(SnapFloaterScope.maybeOf(ctx), isNotNull);
      expect(SnapFloaterScope.of(ctx), same(SnapFloaterScope.maybeOf(ctx)));
    });

    testWidgets('without a scope: maybeOf is null, of asserts', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      );
      expect(SnapFloaterScope.maybeOf(ctx), isNull);
      expect(() => SnapFloaterScope.of(ctx), throwsAssertionError);
    });

    testWidgets(
      '[#4] nested scope fails with the intended message',
      (tester) async {
        setSurface(tester);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => SnapFloaterScope(
              onPressed: () {},
              child: SnapFloaterScope(onPressed: () {}, child: child),
            ),
            home: const Scaffold(body: SizedBox.expand()),
          ),
        );

        final error = tester.takeException();
        expect(error, isNotNull, reason: 'nested scope must be rejected');
        expect(
          error.toString(),
          contains('SnapFloaterScope already defined in context'),
          reason:
              'maybeOf() -> dependOnInheritedWidgetOfExactType() inside '
              'initState() throws a different FlutterError ("called before '
              'initState() completed") and hides the intended assert message',
        );
      },
    );
  });

  group('button', () {
    testWidgets('default floater is rendered once', (tester) async {
      await pumpScope(tester);
      expect(floaterFinder, findsOneWidget);
    });

    testWidgets('tap calls onPressed; floater hidden while the Future runs', (
      tester,
    ) async {
      final gate = Completer<void>();
      var calls = 0;
      await pumpScope(
        tester,
        onPressed: () {
          calls++;
          return gate.future;
        },
      );

      await tester.tap(floaterFinder);
      await tester.pump();
      expect(calls, 1);
      expect(controllerOf(tester).isVisible, isFalse);

      gate.complete();
      await tester.pumpAndSettle();
      expect(controllerOf(tester).isVisible, isTrue);
    });

    testWidgets('hidden floater does not receive taps', (tester) async {
      var calls = 0;
      await pumpScope(tester, onPressed: () => calls++);
      final center = tester.getCenter(floaterFinder);

      controllerOf(tester).hide();
      await tester.pumpAndSettle();
      await tester.tapAt(center);
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('isEnabled: false hides the floater, toggling restores it', (
      tester,
    ) async {
      await pumpScope(
        tester,
        settings: const SnapFloaterSettings(isEnabled: false),
      );
      expect(
        tester
            .widget<SnapFloaterChild>(find.byType(SnapFloaterChild))
            .isVisible,
        isFalse,
      );

      await tester.pumpWidget(buildScopeApp());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SnapFloaterChild>(find.byType(SnapFloaterChild))
            .isVisible,
        isTrue,
      );
    });

    testWidgets('childSize in the controller matches the rendered button', (
      tester,
    ) async {
      await pumpScope(tester);
      expect(
        controllerOf(tester).value.childSize,
        tester.getSize(floaterFinder),
      );
      expect(controllerOf(tester).value.childSize, isNot(Size.zero));
    });
  });

  group('settings changes', () {
    testWidgets(
      '[#3] replacing settings.storage routes writes to the new storage',
      (tester) async {
        final first = FakeStorage();
        final second = FakeStorage();
        await pumpScope(
          tester,
          settings: SnapFloaterSettings(
            snapAlignments: _twoTargets,
            storage: first,
          ),
        );

        await tester.pumpWidget(
          buildScopeApp(
            settings: SnapFloaterSettings(
              snapAlignments: _twoTargets,
              storage: second,
            ),
          ),
        );
        await tester.pumpAndSettle();

        controllerOf(tester).snapTo(.topLeft);
        await tester.pump();

        expect(
          second.writes,
          isNotEmpty,
          reason: 'controller keeps the first SnapFloaterSettings forever',
        );
        expect(first.writes, isEmpty);
      },
    );

    testWidgets(
      '[#5/#6] changing snapAlignments (new list instance) takes effect',
      (tester) async {
        await pumpScope(
          tester,
          settings: const SnapFloaterSettings(
            dragMode: .pan,
            snapAlignments: [.bottomRight, .bottomLeft],
          ),
        );

        await tester.pumpWidget(
          buildScopeApp(
            settings: const SnapFloaterSettings(
              dragMode: .pan,
              snapAlignments: [.bottomRight, .topRight],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(
          tester.getCenter(floaterFinder),
        );
        await gesture.moveBy(const Offset(0, -60));
        await tester.pump();
        await gesture.moveBy(const Offset(0, -600));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(controllerOf(tester).alignment, Alignment.topRight);
      },
    );

    testWidgets(
      '[#6] rebuilding with an equal-content list instance does not break '
      'anything',
      (tester) async {
        await pumpScope(
          tester,
          settings: const SnapFloaterSettings(snapAlignments: [..._twoTargets]),
        );
        await tester.pumpWidget(
          buildScopeApp(
            settings: const SnapFloaterSettings(
              snapAlignments: [..._twoTargets],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(floaterFinder, findsOneWidget);
      },
    );
  });

  group('lifecycle', () {
    testWidgets(
      '[#1] scope removed while storage.read() is pending: no error later',
      (tester) async {
        final completer = Completer<SnapFloaterStorageModel?>();
        await pumpScope(
          tester,
          settings: SnapFloaterSettings(
            snapAlignments: _twoTargets,
            storage: FakeStorage(onRead: () => completer.future),
          ),
        );

        await tester.pumpWidget(const SizedBox());
        completer.complete(storageModelAt(.topLeft));
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('layout', () {
    testWidgets(
      '[#19] scope inside a small container keeps the floater inside it',
      (tester) async {
        setSurface(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: SnapFloaterScope(
                    onPressed: () {},
                    child: const SizedBox.expand(key: contentKey),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final container = tester.getRect(find.byKey(contentKey));
        final floater = tester.getRect(floaterFinder);
        expect(
          container.contains(floater.topLeft) &&
              container.contains(floater.bottomRight),
          isTrue,
          reason:
              'positions are computed from MediaQuery.sizeOf (screen), '
              "not from the scope's own constraints: container=$container "
              'floater=$floater',
        );
      },
    );
  });
}
