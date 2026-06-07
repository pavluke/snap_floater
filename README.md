## Snap Floater

A draggable floating button for Flutter that snaps to predefined screen positions.
Controlled programmatically from anywhere in the widget tree via `SnapFloaterScope.of(context)`.

<p align="center">For better understanding how it works check <a href="https://pavluke.github.io/packages/?pkg=snap_floater">demo</a> page</p>

<div align="center">
  <a href="https://pavluke.github.io/packages/?pkg=snap_floater" 
     style="background: #10ac84; color: white; padding: 12px 24px; 
            text-decoration: none; border-radius: 6px; 
            font-weight: bold; display: inline-block;">
    Open Demo
  </a>
</div>

## Introduction

When building Flutter apps you often need a persistent floating action button that
stays out of the way, can be repositioned by the user, and can be shown or hidden
depending on app state. `SnapFloaterScope` wraps your app once and handles all of
that — drag, snap, visibility, persistence — without any boilerplate in your screens.

## Getting started

Add snap_floater to your `pubspec.yaml`:

```yaml
dependencies:
  snap_floater: ^0.2.0
```

Or using the command:

```bash
flutter pub add snap_floater
```

Import the package in your Dart file:

```dart
import 'package:snap_floater/snap_floater.dart';
```

## Usage

### Basic example

Wrap your `MaterialApp` with `SnapFloaterScope`. The floater hides itself while
`onPressed` runs and reappears when it completes:

```dart
MaterialApp(
  home: const HomePage(),
  builder: (context, child) => SnapFloaterScope(
    onPressed: () async {
      await someAction();
    },
    child: child!,
  ),
);
```

### Custom button and preview animation

```dart
MaterialApp(
  home: const HomePage(),
  builder: (context, child) => SnapFloaterScope.builder(
    buttonBuilder: (context) => FancyButton(
      onPressed: () => SnapFloaterScope.of(context).runHidden(
        () => someAction(),
      ),
    ),
    previewBuilder: SnapFloaterAnimation.blur,
    child: child!,
  ),
);
```

### Control from anywhere in the tree

```dart
final controller = SnapFloaterScope.of(context);

controller.show();
controller.hide();
controller.snapTo(Alignment.topRight);

// Hide while async work runs, show again when done — even if it throws
await controller.runHidden(() async {
  await Navigator.of(context).push(...);
});
```

## Settings

Configure via `SnapFloaterSettings`:

```dart
SnapFloaterScope(
  onPressed: () async {
    await someAction();
  },
  settings: const SnapFloaterSettings(
    initialAlignment: Alignment.bottomRight,
    snapAlignments: [
      Alignment.topRight,
      Alignment.bottomRight,
      Alignment.bottomLeft,
      Alignment.topLeft,
    ],
    isEnabled: true,
    showPreview: true,
    storage: MyStorage(),
  ),
  child: child!,
)
```

| Parameter          | Default         | Description                                                                                                              |
| ------------------ | --------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `snapAlignments`   | `[bottomRight]` | Available snap targets. Drag is disabled when fewer than two                                                             |
| `initialAlignment` | `bottomRight`   | Starting position before any interaction                                                                                 |
| `isEnabled`        | `true`          | When `false`, the floater is hidden and `show()` has no effect                                                           |
| `showPreview`      | `true`          | Show preview widgets at snap targets while dragging                                                                      |
| `storage`          | `null`          | Provide to persist position across app launches                                                                          |
| `dragMode`         | `longPress`     | How drag is initiated: `longPress` to avoid accidental drags on a tappable button, `pan` for immediate response on touch |

## Preview animations

Pass any static method from `SnapFloaterAnimation` as `previewBuilder`:

```dart
SnapFloaterScope.builder(
  previewBuilder: SnapFloaterAnimation.slide,
  ...
)
```

| Animation                    | Description                                 |
| ---------------------------- | ------------------------------------------- |
| `SnapFloaterAnimation.base`  | Instantly placed, no position animation     |
| `SnapFloaterAnimation.slide` | Slides from current drag position to target |
| `SnapFloaterAnimation.pop`   | Scale overshoot on appear: `0 → 1.15 → 1.0` |
| `SnapFloaterAnimation.blur`  | Transitions from blurred to sharp on appear |

### Custom preview animation

Any function matching `PreviewBuilder` works as a custom animation:

```dart
Widget CustomPreview(
  BuildContext context,
  Size floaterSize,
  Offset currentOffset,
  Offset targetOffset,
  bool isVisible,
  bool isNearest,
  Widget child,
) => Transform.translate(
  offset: targetOffset,
  child: AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: isVisible ? (isNearest ? 0.8 : 0.25) : 0.0,
    child: child,
  ),
);

SnapFloaterScope.builder(
  previewBuilder: CustomPreview.new,
  ...
)
```

## Persistent storage

Implement `SnapFloaterStorage` to persist the floater's position across app launches:

```dart
class SharedPrefsStorage implements SnapFloaterStorage {
  SharedPrefsStorage(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'snap_floater_data';

  @override
  Future<SnapFloaterStorageModel?> read() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return SnapFloaterStorageModel.fromJson(jsonDecode(raw));
  }

  @override
  Future<void> write(SnapFloaterStorageModel model) =>
      _prefs.setString(_key, jsonEncode(model.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}
```

Pass the implementation via `SnapFloaterSettings`:

```dart
SnapFloaterScope(
  onPressed: () async {
    await someAction();
  },
  settings: SnapFloaterSettings(
    storage: SharedPrefsStorage(await SharedPreferences.getInstance()),
  ),
  child: child!,
)
```

## Features

- Snaps to predefined alignments on drag release
- Show / hide programmatically from anywhere in the widget tree
- Auto-hide while an async action runs, restores automatically when done
- Custom button widget and custom preview animation via factory constructor
- Preview widgets shown at snap targets during drag
- Persists position across app launches via a pluggable storage interface
- Safe area and edge padding aware
- Architecturally impossible to have more than one floater per subtree

## API reference

### `SnapFloaterScope`

| Member                                                                  | Description                                                      |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `SnapFloaterScope({onPressed, child, ...})`                             | Default factory — renders `BasicSnapFloaterButton`               |
| `SnapFloaterScope.builder({buttonBuilder, previewBuilder, child, ...})` | Custom button and preview                                        |
| `SnapFloaterScope.of(context)`                                          | Returns the nearest `SnapFloaterController`. Throws if not found |
| `SnapFloaterScope.maybeOf(context)`                                     | Returns `null` if not found                                      |

### `SnapFloaterController`

| Member              | Description                                           |
| ------------------- | ----------------------------------------------------- |
| `alignment`         | Current snap alignment                                |
| `isVisible`         | Whether the floater is currently visible              |
| `isDragging`        | Whether the user is actively dragging                 |
| `show()`            | Shows the floater                                     |
| `hide()`            | Hides the floater                                     |
| `snapTo(alignment)` | Snaps to a specific alignment and persists the change |
| `runHidden(action)` | Hides while action runs, then shows again             |

## Changelog

The list of changes is available in the file [CHANGELOG.md](CHANGELOG.md)

## Contributions

Feel free to contribute to this project. If you find a bug or want to add a new
feature but don't know how to fix or implement it, please write in
[issues](https://github.com/pavluke/snap_floater/issues). If you fixed a bug or
implemented a feature, please make a
[pull request](https://github.com/pavluke/snap_floater/pulls).

## License

MIT License — see [LICENSE](LICENSE) file for details
