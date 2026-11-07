import 'package:flutter/material.dart';

/// Converts an [Alignment]
/// to a position for a widget of [targetSize] inside an area.
///
/// Works like Flutter's own [Alignment]: the widget is placed inside the
/// *free* rectangle (the area minus [padding] minus the widget itself), so
/// `-1` is the left/top edge, `1` the right/bottom edge and `0` the center of
/// the padded area. Values in between are linear (`0.5` is exactly halfway
/// between the center and the edge).
///
/// Used internally by [SnapPreviewBuilder] and [SnapFloaterChild]
/// to calculate both the floater's position and snap target positions.
extension AlignmentToScreenOffsetX on Alignment {
  /// Returns the top-left [Offset] where a widget of [targetSize] should be
  /// placed to match this alignment.
  ///
  /// The area is [areaSize] when given (the bounds of the enclosing
  /// `SnapFloaterScope`), otherwise the whole screen (`MediaQuery.sizeOf`).
  /// Alignment values outside `-1..1` are clamped to the edges. Never throws:
  /// if the area is smaller than the widget plus padding, the top/left
  /// padding edge wins.
  Offset toScreenOffset(
    BuildContext context, {
    required Size targetSize,
    required EdgeInsets padding,
    Size? areaSize,
  }) {
    final area = areaSize ?? MediaQuery.sizeOf(context);

    final double freeWidth =
        (area.width - targetSize.width - padding.horizontal).clamp(
          0.0,
          .infinity,
        );
    final double freeHeight =
        (area.height - targetSize.height - padding.vertical).clamp(
          0.0,
          .infinity,
        );

    final double tx = ((x + 1) / 2).clamp(0.0, 1.0);
    final double ty = ((y + 1) / 2).clamp(0.0, 1.0);

    return Offset(
      padding.left + freeWidth * tx,
      padding.top + freeHeight * ty,
    );
  }
}
