part of 'snap_floater_animation.dart';

/// {@template blur_floater_animation}
/// Transitions the preview from blurred to sharp as [isVisible] becomes true.
///
/// Uses [ImageFilter.blur] animated via [TweenAnimationBuilder].
/// The blur sigma animates from [maxBlurSigma] → 0 on appear,
/// and 0 → [maxBlurSigma] on disappear.
/// {@endtemplate}
class BlurFloaterAnimation extends StatelessWidget {
  /// {@macro blur_floater_animation}
  const BlurFloaterAnimation({
    required this.targetOffset,
    required this.isVisible,
    required this.isNearest,
    required this.child,
    this.maxBlurSigma = 12.0,
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

  /// Maximum blur sigma applied when the preview is fully hidden.
  /// Defaults to `12.0`.
  final double maxBlurSigma;

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: targetOffset,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: maxBlurSigma,
            end: isVisible ? 0.0 : maxBlurSigma,
          ),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (context, sigma, child) => ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          ),
          child: SnapFloaterAnimation._opacityScale(
            isVisible: isVisible,
            isNearest: isNearest,
            child: child,
          ),
        ),
      );
}
