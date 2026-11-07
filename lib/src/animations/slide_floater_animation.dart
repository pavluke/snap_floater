part of 'snap_floater_animation.dart';

/// {@template slide_floater_animation}
/// Slides the preview from [currentOffset] to [targetOffset] when
/// [isVisible] becomes true, and back when it becomes false.
///
/// Uses [TweenAnimationBuilder] with [Curves.easeOutCubic].
/// {@endtemplate}
class SlideFloaterAnimation extends StatelessWidget {
  /// {@macro slide_floater_animation}
  const SlideFloaterAnimation({
    required this.currentOffset,
    required this.targetOffset,
    required this.isVisible,
    required this.isNearest,
    required this.child,
    super.key,
  });

  /// The current drag position in screen coordinates (slide origin).
  final Offset currentOffset;

  /// The snap target position in screen coordinates (slide destination).
  final Offset targetOffset;

  /// Whether the preview should be visible.
  final bool isVisible;

  /// Whether this snap target is the nearest to the current drag position.
  final bool isNearest;

  /// The floater button widget to render as a preview.
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Offset>(
    tween: Tween<Offset>(
      begin: currentOffset,
      end: isVisible ? targetOffset : currentOffset,
    ),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
    builder: (context, offset, child) => Transform.translate(
      offset: offset,
      child: child,
    ),
    child: SnapFloaterAnimation._opacityScale(
      isVisible: isVisible,
      isNearest: isNearest,
      child: child,
    ),
  );
}
