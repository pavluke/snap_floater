import 'package:flutter/material.dart';

import '../../enums/floater_drag_mode.dart';
import '../../extensions/to_screen_offset_x.dart';
import 'size_reporter.dart';

/// {@template snap_floater_child}
/// The draggable floater button that snaps to predefined [snapAlignments].
///
/// Handles long-press drag, position clamping within screen bounds,
/// and reports its measured size via [onChildSizeChanged].
///
/// Drag is disabled when [snapAlignments] contains fewer than two entries —
/// the button sits statically at [alignment].
/// {@endtemplate}
class SnapFloaterChild extends StatefulWidget {
  /// {@macro snap_floater_child}
  const SnapFloaterChild({
    required this.dragMode,
    required this.curve,
    required this.useSafeArea,
    required this.padding,
    required this.snapAlignments,
    required this.alignment,
    required this.isDragging,
    required this.isVisible,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
    required this.onChildSizeChanged,
    super.key,
  });

  /// The widget rendered as the draggable button.
  final Widget? child;

  /// Called whenever the button's measured size changes.
  final ValueChanged<Size>? onChildSizeChanged;

  /// Available snap targets. Drag is disabled when fewer than two.
  final Set<Alignment> snapAlignments;

  /// Current snap alignment of the button.
  final Alignment alignment;

  /// True while the user is actively dragging.
  final bool isDragging;

  /// Whether the button should be visible.
  final bool isVisible;

  /// Called when a long-press drag begins.
  final VoidCallback onDragStart;

  /// Called continuously as the button is dragged, with the current alignment.
  final ValueChanged<Alignment> onDragUpdate;

  /// Called when the drag ends, with the nearest snap alignment.
  final ValueChanged<Alignment> onDragEnd;

  /// Padding between the button and screen edges.
  final EdgeInsets padding;

  /// Whether to account for system safe area insets.
  final bool useSafeArea;

  /// Curve used for the [AnimatedPositioned] snap animation.
  final Curve curve;

  /// How the user initiates dragging; defaults to [FloaterDragMode.longPress]
  /// to prevent accidental drags on a tappable button.
  final FloaterDragMode dragMode;

  @override
  State<SnapFloaterChild> createState() => _SnapFloaterChildState();
}

class _SnapFloaterChildState extends State<SnapFloaterChild> {
  Size _buttonSize = Size.zero;
  Offset? _dragAnchor;
  late Set<Alignment> _snapAlignments;

  @override
  void initState() {
    super.initState();
    _snapAlignments = widget.snapAlignments;
  }

  @override
  void didUpdateWidget(SnapFloaterChild old) {
    super.didUpdateWidget(old);
    if (old.snapAlignments != widget.snapAlignments) {
      _snapAlignments = widget.snapAlignments;
    }
  }

  bool get _isDragDisabled => widget.snapAlignments.length < 2;

  Size get _screenSize => MediaQuery.sizeOf(context);

  EdgeInsets get _effectiveSafePadding =>
      widget.useSafeArea ? MediaQuery.paddingOf(context) : EdgeInsets.zero;

  Alignment? _nearestSnapAlignment(Offset currentOffset) {
    if (_isDragDisabled) return null;

    Alignment? nearest;
    double minDistance = double.infinity;

    for (final alignment in _snapAlignments) {
      final snapOffset = alignment.toScreenOffset(
        context,
        targetSize: _buttonSize,
        padding: widget.padding + _effectiveSafePadding,
      );
      final dist = (snapOffset - currentOffset).distance;
      if (dist < minDistance) {
        minDistance = dist;
        nearest = alignment;
      }
    }
    return nearest;
  }

  void _handleDragMove(Offset globalPosition) {
    if (_dragAnchor == null) return;
    final size = _buttonSize;
    final raw = globalPosition - _dragAnchor!;
    final clamped = Offset(
      raw.dx.clamp(
        widget.padding.left + _effectiveSafePadding.left,
        _screenSize.width -
            size.width -
            widget.padding.right -
            _effectiveSafePadding.right,
      ),
      raw.dy.clamp(
        widget.padding.top + _effectiveSafePadding.top,
        _screenSize.height -
            size.height -
            widget.padding.bottom -
            _effectiveSafePadding.bottom,
      ),
    );
    widget.onDragUpdate(_offsetToAlignment(clamped));
  }

  void _handleDragStart(Offset globalPosition, Offset currentOffset) {
    widget.onDragStart();
    _dragAnchor = globalPosition - currentOffset;
  }

  void _handleDragEnd(Offset currentOffset) {
    _dragAnchor = null;
    final nearest = _nearestSnapAlignment(currentOffset);
    widget.onDragEnd(nearest ?? widget.alignment);
  }

  GestureLongPressStartCallback? _onLongPressStart(Offset currentOffset) =>
      _isDragDisabled
          ? null
          : (d) => _handleDragStart(d.globalPosition, currentOffset);

  GestureLongPressMoveUpdateCallback _onLongPressMoveUpdate() =>
      (d) => _handleDragMove(d.globalPosition);

  GestureLongPressEndCallback _onLongPressEnd(Offset currentOffset) =>
      (d) => _handleDragEnd(currentOffset);

  GestureDragStartCallback? _onPanStart(Offset currentOffset) => _isDragDisabled
      ? null
      : (d) => _handleDragStart(d.globalPosition, currentOffset);

  GestureDragUpdateCallback _onPanUpdate() =>
      (d) => _handleDragMove(d.globalPosition);

  GestureDragEndCallback _onPanEnd(Offset currentOffset) =>
      (d) => _handleDragEnd(currentOffset);

  Alignment _offsetToAlignment(Offset offset) => Alignment(
        (2 * (offset.dx + _buttonSize.width / 2) / _screenSize.width) - 1,
        (2 * (offset.dy + _buttonSize.height / 2) / _screenSize.height) - 1,
      );

  void _onSize(Size size) {
    setState(() => _buttonSize = size);
    widget.onChildSizeChanged?.call(size);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child case final child?) {
      final currentOffset = widget.alignment.toScreenOffset(
        context,
        targetSize: _buttonSize,
        padding: widget.padding + _effectiveSafePadding,
      );
      return AnimatedPositioned(
        duration: widget.isDragging
            ? Duration.zero
            : const Duration(milliseconds: 200),
        left: currentOffset.dx,
        top: currentOffset.dy,
        curve: widget.curve,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.isVisible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !widget.isVisible,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: widget.dragMode == FloaterDragMode.longPress
                  ? _onLongPressStart(currentOffset)
                  : null,
              onLongPressMoveUpdate:
                  widget.dragMode == FloaterDragMode.longPress
                      ? _onLongPressMoveUpdate()
                      : null,
              onLongPressEnd: widget.dragMode == FloaterDragMode.longPress
                  ? _onLongPressEnd(currentOffset)
                  : null,
              onPanStart: widget.dragMode == FloaterDragMode.pan
                  ? _onPanStart(currentOffset)
                  : null,
              onPanUpdate: widget.dragMode == FloaterDragMode.pan
                  ? _onPanUpdate()
                  : null,
              onPanEnd: widget.dragMode == FloaterDragMode.pan
                  ? _onPanEnd(currentOffset)
                  : null,
              child: SizeReporter(
                onSizeCalculated: _onSize,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
