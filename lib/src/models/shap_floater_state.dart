import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// {@template snap_floater_state}
/// Immutable runtime state of a [SnapFloaterScope].
///
/// Managed internally by [SnapFloaterController] — do not construct manually.
///
/// All fields are value-comparable: two [SnapFloaterState] instances with
/// identical fields are considered equal, which prevents unnecessary rebuilds
/// in [ValueListenableBuilder].
/// {@endtemplate}
@immutable
class SnapFloaterState {
  /// {@macro snap_floater_state}
  const SnapFloaterState({
    required this.alignment,
    this.isVisible = true,
    this.isDragging = false,
    this.childSize = Size.zero,
  });

  /// Current snap alignment of the floater.
  final Alignment alignment;

  /// Whether the floater is currently visible.
  final bool isVisible;

  /// Whether the user is actively dragging the floater.
  final bool isDragging;

  /// Measured size of the floater button, reported by [SizeReporter].
  final Size childSize;

  /// Creates a new instance with specified fields replaced.
  ///
  /// Unspecified fields retain original values.
  SnapFloaterState copyWith({
    Alignment? alignment,
    bool? isVisible,
    bool? isDragging,
    Size? childSize,
  }) =>
      SnapFloaterState(
        alignment: alignment ?? this.alignment,
        isVisible: isVisible ?? this.isVisible,
        isDragging: isDragging ?? this.isDragging,
        childSize: childSize ?? this.childSize,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnapFloaterState &&
          alignment == other.alignment &&
          isVisible == other.isVisible &&
          isDragging == other.isDragging &&
          childSize == other.childSize;

  @override
  int get hashCode => Object.hash(alignment, isVisible, isDragging, childSize);

  @override
  String toString() => 'SnapFloaterState('
      'alignment: $alignment, '
      'isVisible: $isVisible, '
      'isDragging: $isDragging, '
      'childSize: $childSize'
      ')';
}
