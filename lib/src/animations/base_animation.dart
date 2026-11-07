part of 'snap_floater_animation.dart';

/// {@template base_animation}
/// Instantly places the preview at [targetOffset] with no position animation.
///
/// Opacity and scale animate based on [isVisible] and [isNearest].
/// This is the default [PreviewBuilder] used by [SnapFloaterScope].
/// {@endtemplate}
class BaseAnimation extends StatelessWidget {
  /// {@macro base_animation}
  const BaseAnimation({
    required this.targetOffset,
    required this.isVisible,
    required this.isNearest,
    required this.child,
    super.key,
  });

  /// The target position in screen coordinates.
  final Offset targetOffset;

  /// Whether the preview should be visible.
  final bool isVisible;

  /// Whether this snap target is the nearest to the current drag position.
  final bool isNearest;

  /// The floater button widget to render as a preview.
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: targetOffset,
    child: SnapFloaterAnimation._opacityScale(
      isVisible: isVisible,
      isNearest: isNearest,
      child: child,
    ),
  );
}
