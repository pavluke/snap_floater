import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_floater/snap_floater.dart';

/// In-memory [SnapFloaterStorage] with hooks to simulate slow or failing I/O.
class FakeStorage implements SnapFloaterStorage {
  FakeStorage({this.stored, this.onRead, this.onWrite});

  SnapFloaterStorageModel? stored;
  final Future<SnapFloaterStorageModel?> Function()? onRead;
  final Future<void> Function(SnapFloaterStorageModel model)? onWrite;

  final List<SnapFloaterStorageModel> writes = <SnapFloaterStorageModel>[];
  int clearCalls = 0;

  @override
  Future<SnapFloaterStorageModel?> read() async =>
      onRead != null ? onRead!() : stored;

  @override
  Future<void> write(SnapFloaterStorageModel model) async {
    writes.add(model);
    await onWrite?.call(model);
    stored = model;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    stored = null;
  }
}

SnapFloaterStorageModel storageModelAt(Alignment alignment) =>
    SnapFloaterStorageModel(base: SnapFloaterSnapshot(alignment: alignment));

/// Lets pending microtasks / zero-delay timers (e.g. the controller's
/// fire-and-forget `_init`) run to completion.
Future<void> flushAsync() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Runs [body] in an error zone and returns every uncaught error, including
/// those raised by un-awaited futures.
Future<List<Object>> collectUncaughtErrors(
  Future<void> Function() body,
) async {
  final errors = <Object>[];
  await runZonedGuarded<Future<void>>(
    () async {
      try {
        await body();
      } catch (e) {
        errors.add(e);
      }
    },
    (error, stack) => errors.add(error),
  );
  return errors;
}

// ---------------------------------------------------------------------------
// Widget-test helpers
// ---------------------------------------------------------------------------

const Key contentKey = Key('snap_floater_test_content');

/// Default logical surface: 400 x 800, device pixel ratio 1.
const Size defaultSurface = Size(400, 800);

void setSurface(WidgetTester tester, [Size size = defaultSurface]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// App whose `builder` is wrapped by [SnapFloaterScope] — the pattern from the
/// README.
Widget buildScopeApp({
  SnapFloaterSettings settings = const SnapFloaterSettings(),
  FutureOr<void> Function()? onPressed,
}) =>
    MaterialApp(
      builder: (context, child) => SnapFloaterScope(
        onPressed: onPressed ?? () {},
        settings: settings,
        child: child,
      ),
      home: const Scaffold(body: SizedBox.expand(key: contentKey)),
    );

Future<void> pumpScope(
  WidgetTester tester, {
  SnapFloaterSettings settings = const SnapFloaterSettings(),
  FutureOr<void> Function()? onPressed,
  Size size = defaultSurface,
}) async {
  setSurface(tester, size);
  await tester.pumpWidget(
    buildScopeApp(settings: settings, onPressed: onPressed),
  );
  await tester.pumpAndSettle();
}

SnapFloaterController controllerOf(WidgetTester tester) =>
    SnapFloaterScope.of(tester.element(find.byKey(contentKey)));

/// The real (draggable) floater button — excludes snap previews.
Finder get floaterFinder => find.descendant(
      of: find.byType(SnapFloaterChild),
      matching: find.byType(BasicSnapFloaterButton),
    );
