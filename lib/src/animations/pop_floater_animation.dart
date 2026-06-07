part of 'snap_floater_animation.dart';

/// {@template pop_floater_animation}
/// Scales the preview from 0 → [popOvershoot] → 1.0 on appearance.
///
/// Uses an [AnimationController] with a [TweenSequence] to produce
/// an iOS-style spring-like pop effect. Reverses on disappear.
/// {@endtemplate}
class PopFloaterAnimation extends StatefulWidget {
  /// {@macro pop_floater_animation}
  const PopFloaterAnimation({
    required this.targetOffset,
    required this.isVisible,
    required this.isNearest,
    required this.child,
    super.key,
    this.popOvershoot = 1.15,
  });

  /// The target position in screen coordinates.
  final Offset targetOffset;

  /// Whether the preview should be visible.
  final bool isVisible;

  /// Whether this snap target is the nearest to the current drag position.
  final bool isNearest;

  /// The floater button widget to render as a preview.
  final Widget child;

  /// The intermediate overshoot scale before settling at 1.0.
  /// Defaults to `1.15`.
  final double popOvershoot;

  @override
  State<PopFloaterAnimation> createState() => _PopFloaterAnimationState();
}

class _PopFloaterAnimationState extends State<PopFloaterAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0, end: widget.popOvershoot),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: widget.popOvershoot,
        end: 1,
      ),
      weight: 40,
    ),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) unawaited(_controller.forward());
  }

  @override
  void didUpdateWidget(PopFloaterAnimation old) {
    super.didUpdateWidget(old);
    if (old.isVisible != widget.isVisible) {
      unawaited(
        widget.isVisible ? _controller.forward(from: 0) : _controller.reverse(),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: widget.targetOffset,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: SnapFloaterAnimation._opacity(
            isVisible: widget.isVisible,
            isNearest: widget.isNearest,
          ),
          child: AnimatedBuilder(
            animation: _scale,
            builder: (context, child) => Transform.scale(
              scale: _scale.value *
                  SnapFloaterAnimation._scale(isNearest: widget.isNearest),
              child: child,
            ),
            child: widget.child,
          ),
        ),
      );
}
