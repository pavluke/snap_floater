import 'package:material_ui/material_ui.dart';

import '../../enums/floater_drag_mode.dart';
import '../../extensions/to_screen_offset_x.dart';
import '../../utils/offset_to_alignment.dart';
import '../../utils/safe_clamp.dart';
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
    this.areaSize,
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

  /// Bounds the button is positioned in. Defaults to the whole screen
  /// (`MediaQuery.sizeOf`); `SnapFloaterScope` passes its own bounds.
  final Size? areaSize;

  @override
  State<SnapFloaterChild> createState() => _SnapFloaterChildState();
}

class _SnapFloaterChildState extends State<SnapFloaterChild> {
  Size _buttonSize = Size.zero;
  Offset? _dragAnchor;

  /// Latest (clamped) position of the button during a drag. Kept in state —
  /// not captured from build — so release in the same frame as the last move
  /// still uses the up-to-date position.
  Offset _dragOffset = Offset.zero;

  bool get _isDragDisabled => widget.snapAlignments.length < 2;

  Size get _area => widget.areaSize ?? MediaQuery.sizeOf(context);

  EdgeInsets get _effectiveSafePadding =>
      widget.useSafeArea ? MediaQuery.paddingOf(context) : EdgeInsets.zero;

  EdgeInsets get _totalPadding => widget.padding + _effectiveSafePadding;

  Offset _offsetFor(Alignment alignment) => alignment.toScreenOffset(
    context,
    targetSize: _buttonSize,
    padding: _totalPadding,
    areaSize: widget.areaSize,
  );

  Alignment? _nearestSnapAlignment(Offset currentOffset) {
    if (_isDragDisabled) return null;

    Alignment? nearest;
    double minDistance = .infinity;

    for (final alignment in widget.snapAlignments) {
      final dist = (_offsetFor(alignment) - currentOffset).distance;
      if (dist < minDistance) {
        minDistance = dist;
        nearest = alignment;
      }
    }
    return nearest;
  }

  void _handleDragStart(Offset globalPosition) {
    final current = _offsetFor(widget.alignment);
    widget.onDragStart();
    _dragOffset = current;
    _dragAnchor = globalPosition - current;
  }

  void _handleDragMove(Offset globalPosition) {
    final anchor = _dragAnchor;
    if (anchor == null) return;
    final raw = globalPosition - anchor;
    final area = _area;
    final padding = _totalPadding;
    final clamped = Offset(
      raw.dx.clampSafe(
        padding.left,
        area.width - _buttonSize.width - padding.right,
      ),
      raw.dy.clampSafe(
        padding.top,
        area.height - _buttonSize.height - padding.bottom,
      ),
    );
    _dragOffset = clamped;
    widget.onDragUpdate(_offsetToAlignment(clamped));
  }

  /// Ends the drag (release or cancel). Does nothing if no drag is active.
  void _handleDragEnd() {
    if (_dragAnchor == null) return;
    _dragAnchor = null;
    widget.onDragEnd(_nearestSnapAlignment(_dragOffset) ?? widget.alignment);
  }

  Alignment _offsetToAlignment(Offset offset) => offsetToAlignment(
    offset,
    targetSize: _buttonSize,
    padding: _totalPadding,
    area: _area,
  );

  void _onSize(Size size) {
    setState(() => _buttonSize = size);
    widget.onChildSizeChanged?.call(size);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child case final child?) {
      final currentOffset = _offsetFor(widget.alignment);
      final isLongPress = widget.dragMode == .longPress;
      final isPan = widget.dragMode == .pan;
      return AnimatedPositioned(
        duration: widget.isDragging ? .zero : const Duration(milliseconds: 200),
        left: currentOffset.dx,
        top: currentOffset.dy,
        curve: widget.curve,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.isVisible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !widget.isVisible,
            // Raw pointer cancel (system gesture, route push, ...) is not
            // always reported by the recognizers once they have accepted.
            child: Listener(
              onPointerCancel: (_) => _handleDragEnd(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: isLongPress && !_isDragDisabled
                    ? (d) => _handleDragStart(d.globalPosition)
                    : null,
                onLongPressMoveUpdate: isLongPress
                    ? (d) => _handleDragMove(d.globalPosition)
                    : null,
                onLongPressEnd: isLongPress ? (_) => _handleDragEnd() : null,
                onLongPressCancel: isLongPress ? _handleDragEnd : null,
                onPanStart: isPan && !_isDragDisabled
                    ? (d) => _handleDragStart(d.globalPosition)
                    : null,
                onPanUpdate: isPan
                    ? (d) => _handleDragMove(d.globalPosition)
                    : null,
                onPanEnd: isPan ? (_) => _handleDragEnd() : null,
                onPanCancel: isPan ? _handleDragEnd : null,
                child: SizeReporter(
                  onSizeCalculated: _onSize,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
