import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

part 'base_animation.dart';
part 'blur_floater_animation.dart';
part 'pop_floater_animation.dart';
part 'slide_floater_animation.dart';

/// Built-in preview animations for [SnapFloaterScope.builder].
///
/// Pass any static method as the `previewBuilder` argument:
/// ```dart
/// SnapFloaterScope.builder(
///   previewBuilder: SnapFloaterAnimation.blur,
///   ...
/// )
/// ```
///
/// All methods conform to [PreviewBuilder].
abstract final class SnapFloaterAnimation {
  static double _opacity({required bool isVisible, required bool isNearest}) =>
      isVisible ? (isNearest ? 0.8 : 0.25) : 0.0;

  static double _scale({required bool isNearest}) => isNearest ? 1.0 : 0.85;

  static Widget _opacityScale({
    required bool isVisible,
    required bool isNearest,
    required Widget child,
  }) => AnimatedOpacity(
    duration: const Duration(milliseconds: 100),
    opacity: _opacity(isVisible: isVisible, isNearest: isNearest),
    child: AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: _scale(isNearest: isNearest),
      child: child,
    ),
  );

  /// Instantly places the preview at [targetOffset] with no position animation.
  /// Opacity and scale animate based on visibility and proximity.
  static Widget base(
    BuildContext context,
    Size floaterSize,
    Offset currentOffset,
    Offset targetOffset,
    bool isVisible,
    bool isNearest,
    Widget child,
  ) => BaseAnimation(
    targetOffset: targetOffset,
    isVisible: isVisible,
    isNearest: isNearest,
    child: child,
  );

  /// Slides the preview from [currentOffset] to [targetOffset] with
  /// an [Curves.easeOutCubic] curve when [isVisible] becomes true.
  static Widget slide(
    BuildContext context,
    Size floaterSize,
    Offset currentOffset,
    Offset targetOffset,
    bool isVisible,
    bool isNearest,
    Widget child,
  ) => SlideFloaterAnimation(
    currentOffset: currentOffset,
    targetOffset: targetOffset,
    isVisible: isVisible,
    isNearest: isNearest,
    child: child,
  );

  /// Scales the preview from 0 → 1.15 → 1.0 on appearance (iOS-style pop).
  static Widget pop(
    BuildContext context,
    Size floaterSize,
    Offset currentOffset,
    Offset targetOffset,
    bool isVisible,
    bool isNearest,
    Widget child,
  ) => PopFloaterAnimation(
    targetOffset: targetOffset,
    isVisible: isVisible,
    isNearest: isNearest,
    child: child,
  );

  /// Transitions the preview from blurred to sharp as [isVisible] becomes true.
  static Widget blur(
    BuildContext context,
    Size floaterSize,
    Offset currentOffset,
    Offset targetOffset,
    bool isVisible,
    bool isNearest,
    Widget child,
  ) => BlurFloaterAnimation(
    targetOffset: targetOffset,
    isVisible: isVisible,
    isNearest: isNearest,
    child: child,
  );
}
