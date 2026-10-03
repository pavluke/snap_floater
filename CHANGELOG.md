## 0.3.0

* **BREAKING:** `SnapFloaterSettings.initialAlignment` is deprecated and now ignored.
  The first element of `snapAlignments` is used as the initial position.
* **BREAKING:** `snapAlignments` must not be empty (checked by an assert in `SnapFloaterController`).

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
