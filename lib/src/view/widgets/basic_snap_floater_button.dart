import 'package:flutter/material.dart';

/// {@template basic_snap_floater_button}
/// The default floater button used by [SnapFloaterScope].
///
/// Renders a filled [IconButton] with a circular shadow.
/// Replace it via [SnapFloaterScope.builder] if you need a custom widget.
/// {@endtemplate }
class BasicSnapFloaterButton extends StatelessWidget {
  /// {@macro basic_snap_floater_button}
  const BasicSnapFloaterButton(this.onTap, {super.key});

  /// Called when the button is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(color);

    final adjusted = hsl
        .withLightness(
          (hsl.lightness + (isDark ? .1 : -.1)).clamp(0.0, 1.0),
        )
        .toColor();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          width: 3,
          color: adjusted,
        ),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: IconButton.filled(
          padding: const EdgeInsets.all(15),
          onPressed: onTap,
          icon: Icon(
            Icons.code,
            color: Theme.of(context).buttonTheme.colorScheme?.onPrimary,
          ),
        ),
      ),
    );
  }
}
