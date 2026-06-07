/// Defines how the user initiates dragging the floater.
///
/// Pass via [SnapFloaterSettings.dragMode].
///
/// - [longPress] — drag begins after a long-press gesture. Good for buttons
///   that also handle taps, since it avoids accidental drags.
/// - [pan] — drag begins immediately on finger down. More responsive,
///   but may conflict with tap or scroll gestures in the vicinity.
enum FloaterDragMode {
  /// Drag is initiated via a long-press gesture.
  longPress,

  /// Drag is initiated immediately on pan/finger-down.
  pan,
}
