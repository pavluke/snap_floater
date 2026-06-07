import 'package:flutter/material.dart';

import '../../extensions/to_screen_offset_x.dart';

/// Signature for a function that builds a preview widget at a snap target.
///
/// Called once per snap target while the user is dragging. Parameters:
/// - [floaterSize] — measured size of the floater button.
/// - [currentOffset] — current drag position in screen coordinates.
/// - [targetOffset] — position of this snap target in screen coordinates.
/// - [isVisible] — whether the preview should be visible (true while dragging).
/// - [isNearest] — whether this target is closest to the current drag position.
/// - [child] — the floater button widget to render as a preview.
///
/// Use one of the built-in implementations from [SnapFloaterAnimation],
/// or supply a custom function matching this signature.
typedef PreviewBuilder = Widget Function(
  BuildContext context,
  Size floaterSize,
  Offset currentOffset,
  Offset targetOffset,
  bool isVisible,
  bool isNearest,
  Widget child,
);

/// {@template snap_preview_builder}
/// Renders preview widgets at each snap target position during drag.
///
/// Previews are non-interactive ([IgnorePointer]) and are only meaningful
/// when [snapAlignments] contains at least two entries.
/// The nearest target to the current drag position receives [isNearest] = true,
/// allowing [previewBuilder] to visually distinguish it.
/// {@endtemplate}
class SnapPreviewBuilder extends StatefulWidget {
  ///{@macro snap_preview_builder}
  const SnapPreviewBuilder({
    required this.child,
    required this.padding,
    required this.useSafeArea,
    required this.isVisible,
    required this.snapAlignments,
    required this.currentAlignment,
    required this.floaterSize,
    required this.previewBuilder,
    super.key,
  });

  /// Whether to account for system safe area insets.
  final bool useSafeArea;

  /// Padding between previews and screen edges.
  final EdgeInsets padding;

  /// Whether the previews should currently be visible (true while dragging).
  final bool isVisible;

  /// All available snap targets.
  final Set<Alignment> snapAlignments;

  /// The floater's current alignment during drag.
  final Alignment currentAlignment;

  /// Measured size of the floater button.
  final Size floaterSize;

  /// The floater button widget rendered at each preview position.
  final Widget? child;

  /// Builds each preview widget. See [PreviewBuilder].
  final PreviewBuilder previewBuilder;

  @override
  State<SnapPreviewBuilder> createState() => _SnapPreviewBuilderState();
}

class _SnapPreviewBuilderState extends State<SnapPreviewBuilder> {
  Alignment? _nearestTarget;
  late Offset _currentOffset;

  EdgeInsets get _safePadding =>
      widget.useSafeArea ? MediaQuery.paddingOf(context) : EdgeInsets.zero;

  EdgeInsets get _totalPadding => widget.padding + _safePadding;

  void _recalculateNearest() {
    _currentOffset = widget.currentAlignment.toScreenOffset(
      context,
      targetSize: widget.floaterSize,
      padding: _totalPadding,
    );

    Alignment? nearest;
    double minDist = double.infinity;

    for (final alignment in widget.snapAlignments) {
      final snapOffset = alignment.toScreenOffset(
        context,
        targetSize: widget.floaterSize,
        padding: _totalPadding,
      );
      final dist = (snapOffset - _currentOffset).distance;
      if (dist < minDist) {
        minDist = dist;
        nearest = alignment;
      }
    }

    _nearestTarget = nearest;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recalculateNearest();
  }

  @override
  void didUpdateWidget(SnapPreviewBuilder old) {
    super.didUpdateWidget(old);
    if (old.currentAlignment != widget.currentAlignment ||
        old.floaterSize != widget.floaterSize ||
        old.snapAlignments != widget.snapAlignments) {
      _recalculateNearest();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child case final child?) {
      return IgnorePointer(
        child: Stack(
          children: widget.snapAlignments.map((snapAlignment) {
            final targetOffset = snapAlignment.toScreenOffset(
              context,
              targetSize: widget.floaterSize,
              padding: _totalPadding,
            );
            return widget.previewBuilder(
              context,
              widget.floaterSize,
              _currentOffset,
              targetOffset,
              widget.isVisible,
              snapAlignment == _nearestTarget,
              child,
            );
          }).toList(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
