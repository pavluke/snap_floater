import 'package:flutter/painting.dart';

/// Internal helper (not exported): inverse of `Alignment.toScreenOffset`.
///
/// Returns the alignment that places a widget of [targetSize] at [offset]
/// inside [area] with [padding], so dragging and snapping share one mapping
/// and the button never jumps. Degenerate (no free space) -> centre.
Alignment offsetToAlignment(
  Offset offset, {
  required Size targetSize,
  required EdgeInsets padding,
  required Size area,
}) {
  final freeWidth = area.width - targetSize.width - padding.horizontal;
  final freeHeight = area.height - targetSize.height - padding.vertical;
  final tx = freeWidth > 0 ? (offset.dx - padding.left) / freeWidth : 0.5;
  final ty = freeHeight > 0 ? (offset.dy - padding.top) / freeHeight : 0.5;
  return Alignment(2 * tx - 1, 2 * ty - 1);
}
