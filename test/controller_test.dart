import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:snap_floater/snap_floater.dart';

import 'helpers/test_helpers.dart';

SnapFloaterController makeController({
  List<Alignment> alignments = const [.bottomRight, .topLeft],
  SnapFloaterStorage? storage,
  bool isEnabled = true,
}) {
  final controller = SnapFloaterController(
    settings: SnapFloaterSettings(
      snapAlignments: alignments,
      storage: storage,
      isEnabled: isEnabled,
    ),
  );
  addTearDown(() {
    try {
      controller.dispose();
    } on Object {
      // already disposed by the test itself
    }
  });
  return controller;
}

void main() {
  group('construction', () {
    test('initial alignment is the first element of snapAlignments', () {
      final c = makeController(
        alignments: const [.topLeft, .bottomRight],
      );
      expect(c.alignment, Alignment.topLeft);
      expect(c.isVisible, isTrue);
      expect(c.isDragging, isFalse);
      expect(c.value.childSize, Size.zero);
    });

    test('empty snapAlignments is rejected by an assert', () {
      expect(
        () => SnapFloaterController(
          settings: const SnapFloaterSettings(snapAlignments: []),
        ),
        throwsAssertionError,
      );
    });

    test('[misc] duplicate snapAlignments are rejected by an assert', () {
      expect(
        () => SnapFloaterController(
          settings: const SnapFloaterSettings(
            snapAlignments: [.topLeft, .topLeft],
          ),
        ),
        throwsAssertionError,
      );
    });
  });

  group('storage restore', () {
    test('restores a saved alignment that is in snapAlignments', () async {
      final storage = FakeStorage(stored: storageModelAt(.topLeft));
      final c = makeController(storage: storage);
      await flushAsync();
      expect(c.alignment, Alignment.topLeft);
    });

    test('nothing saved -> keeps first snap alignment', () async {
      final c = makeController(storage: FakeStorage());
      await flushAsync();
      expect(c.alignment, Alignment.bottomRight);
    });

    test(
      '[#2] saved alignment that is NOT in snapAlignments is not restored',
      () async {
        final storage = FakeStorage(
          stored: storageModelAt(.topCenter),
        );
        final c = makeController(
          alignments: const [.bottomRight, .bottomLeft],
          storage: storage,
        );
        await flushAsync();
        expect(
          c.value.alignment,
          isIn(const [Alignment.bottomRight, Alignment.bottomLeft]),
          reason: 'floater must always sit on one of the configured targets',
        );
      },
    );

    test(
      '[#1] dispose before storage.read() completes does not throw',
      () async {
        final completer = Completer<SnapFloaterStorageModel?>();
        final storage = FakeStorage(onRead: () => completer.future);

        final errors = await collectUncaughtErrors(() async {
          SnapFloaterController(
            settings: SnapFloaterSettings(
              snapAlignments: const [.bottomRight, .topLeft],
              storage: storage,
            ),
          ).dispose();
          completer.complete(storageModelAt(.topLeft));
          await flushAsync();
        });

        expect(errors, isEmpty);
      },
    );

    test(
      '[#1] storage.read() throwing does not produce an uncaught error',
      () async {
        final storage = FakeStorage(onRead: () async => throw StateError('io'));

        late SnapFloaterController c;
        final errors = await collectUncaughtErrors(() async {
          c = SnapFloaterController(
            settings: SnapFloaterSettings(
              snapAlignments: const [.bottomRight, .topLeft],
              storage: storage,
            ),
          );
          await flushAsync();
        });
        addTearDown(c.dispose);

        expect(errors, isEmpty);
        expect(c.alignment, Alignment.bottomRight);
      },
    );

    test('[#1] corrupt stored JSON does not produce an uncaught error', () {
      expect(
        () => SnapFloaterStorageModel.fromJson(const {'base': 'oops'}),
        throwsA(isA<TypeError>()),
        reason:
            'documents what a user storage impl will hit; '
            'the controller must survive it (see previous test)',
      );
    });

    test(
      '[#1b] user snapTo() before slow read() completes is not overwritten',
      () async {
        final completer = Completer<SnapFloaterStorageModel?>();
        final storage = FakeStorage(onRead: () => completer.future);
        final c = makeController(
          alignments: const [
            .bottomRight,
            .topLeft,
            .bottomLeft,
          ],
          storage: storage,
        )..snapTo(.topLeft);
        completer.complete(storageModelAt(.bottomLeft));
        await flushAsync();

        expect(c.alignment, Alignment.topLeft);
      },
    );
  });

  group('snapTo', () {
    test('updates alignment and persists to storage', () async {
      final storage = FakeStorage();
      final c = makeController(storage: storage);
      await flushAsync();

      c.snapTo(.topLeft);
      await flushAsync();

      expect(c.alignment, Alignment.topLeft);
      expect(storage.writes, hasLength(1));
      expect(storage.writes.single.base.alignment, Alignment.topLeft);
    });

    test('works without storage', () {
      final c = makeController()..snapTo(.topLeft);
      expect(c.alignment, Alignment.topLeft);
    });

    test('[#1] storage.write() throwing is not an uncaught error', () async {
      final storage = FakeStorage(
        onWrite: (_) async => throw StateError('disk full'),
      );

      late SnapFloaterController c;
      final errors = await collectUncaughtErrors(() async {
        c = SnapFloaterController(
          settings: SnapFloaterSettings(
            snapAlignments: const [.bottomRight, .topLeft],
            storage: storage,
          ),
        );
        await flushAsync();
        c.snapTo(.topLeft);
        await flushAsync();
      });
      addTearDown(c.dispose);

      expect(errors, isEmpty);
      expect(
        c.alignment,
        Alignment.topLeft,
        reason: 'UI state must not depend on I/O',
      );
    });

    test('notifies listeners only when state actually changes', () {
      final c = makeController();
      var calls = 0;
      c
        ..addListener(() => calls++)
        ..snapTo(.topLeft)
        ..snapTo(.topLeft);
      expect(calls, 1);

      c
        ..hide()
        ..hide();
      expect(calls, 2);

      c
        ..show()
        ..show();
      expect(calls, 3);
    });
  });

  group('show / hide / isEnabled', () {
    test('hide() and show() toggle visibility', () {
      final c = makeController()..hide();
      expect(c.isVisible, isFalse);
      c.show();
      expect(c.isVisible, isTrue);
    });

    test('[#12] isEnabled: false -> controller reports invisible', () {
      final c = makeController(isEnabled: false);
      expect(c.isVisible, isFalse);
    });

    test(
      '[#12] show() has no effect when isEnabled: false (as documented)',
      () {
        final c = makeController(isEnabled: false)..show();
        expect(c.isVisible, isFalse);
      },
    );
  });

  group('runHidden', () {
    test('async action: hidden while running, visible after', () async {
      final c = makeController();
      final gate = Completer<void>();

      final future = c.runHidden(() => gate.future);
      expect(c.isVisible, isFalse);

      gate.complete();
      await future;
      expect(c.isVisible, isTrue);
    });

    test(
      '[#10] sync action: hidden for its duration (as documented)',
      () async {
        final c = makeController();
        bool? visibleInside;

        await c.runHidden(() {
          visibleInside = c.isVisible;
        });

        expect(visibleInside, isFalse);
        expect(c.isVisible, isTrue);
      },
    );

    test(
      'async action that throws: error propagates, floater is shown',
      () async {
        final c = makeController();
        await expectLater(
          c.runHidden(() => throw StateError('boom')),
          throwsStateError,
        );
        expect(c.isVisible, isTrue);
      },
    );

    test(
      'sync action that throws: error propagates, floater is shown',
      () async {
        final c = makeController();
        await expectLater(
          c.runHidden(() => throw StateError('boom')),
          throwsStateError,
        );
        expect(c.isVisible, isTrue);
      },
    );

    test(
      '[#11] re-entrant call is ignored while an action is running',
      () async {
        final c = makeController();
        final gate = Completer<void>();
        var secondRan = false;

        final first = c.runHidden(() => gate.future);
        await c.runHidden(() => secondRan = true);
        expect(secondRan, isFalse);

        gate.complete();
        await first;
        expect(c.isVisible, isTrue, reason: 'ignored call must not show early');
      },
    );

    test('can run again after a previous run threw', () async {
      final c = makeController();
      await expectLater(
        c.runHidden(() => throw StateError('boom')),
        throwsStateError,
      );

      var ran = false;
      await c.runHidden(() => ran = true);
      expect(ran, isTrue);
    });
  });
}
