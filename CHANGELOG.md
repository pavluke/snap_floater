## 0.4.0

- Fix: storage errors (`read`/`write`) no longer surface as uncaught errors;
  a failed read keeps the default position.
- Fix: no more `used after being disposed` when the scope is removed while
  storage is still being read.
- Fix: a slow `storage.read()` no longer overwrites a position the user has
  already chosen.
- Fix: a saved alignment that is not in `snapAlignments` is ignored.
- Fix: `SnapFloaterSettings` changes (`storage`, `isEnabled`, `snapAlignments`)
  are now applied by an existing scope.
- Fix: `SnapFloaterAnimation.blur` had a wrong parameter order and could not be
  used as a `PreviewBuilder`.
- Fix: a cancelled gesture no longer leaves `isDragging == true`.
- Fix: releasing in the same frame as the last move snaps to the latest position.
- Fix: positions are computed inside the scope's own bounds instead of the
  whole screen; no `ArgumentError` on very small areas.
- Change: alignment now maps linearly onto the padded area like Flutter's
  `Alignment` (`0.5` is halfway between centre and edge); previously values
  near the edge saturated and `0` ignored asymmetric padding / safe area.
- Fix: nested `SnapFloaterScope` now fails with the intended assert message.
- Fix: `runHidden` also hides the floater for synchronous actions.
- Fix: `controller.isVisible` is `false` while `isEnabled` is `false`.
- Fix: default button icon color uses `ColorScheme.onPrimary`.
- Add: `==`/`hashCode` for `SnapFloaterSettings`; assert on duplicate
  `snapAlignments`.
- Perf: `BlurFloaterAnimation` skips the blur layer when fully sharp.
- Docs: README `builder` parameter name and version; minimum Flutter 3.28.0.

## 0.3.1

- Fix: 0.3.0 was published with an incomplete change and does not compile.
  The first element of `snapAlignments` is now correctly used as the initial position.

## 0.3.0

- **BREAKING:** `SnapFloaterSettings.initialAlignment` is deprecated and now ignored.
  The first element of `snapAlignments` is used as the initial position.
- **BREAKING:** `snapAlignments` must not be empty (checked by an assert in `SnapFloaterController`).

## 0.2.0

- Add `FloaterDragMode` enum with `longPress` and `pan` modes.

## 0.1.9

- Make `child` is nullable.

## 0.1.8

- Add border on base SnapFloater button.
- Add IgnorePointer to avoid clicks when the button is not visible.
- Add [pavluke_lints](https://pub.dev/packages/pavluke_lints).

## 0.1.0

- initial release.
