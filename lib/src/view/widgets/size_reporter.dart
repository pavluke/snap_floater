import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// {@template size_reporter}
/// Reports its child's [Size] after every layout pass via [onSizeCalculated].
///
/// Uses a [RenderProxyBox] to intercept [RenderObject.performLayout],
/// guaranteeing the reported size is always in sync with the actual layout —
/// unlike post-frame callbacks which can miss intermediate frames.
/// {@endtemplate}
class SizeReporter extends StatefulWidget {
  /// {@macro size_reporter}
  const SizeReporter({
    required this.child,
    required this.onSizeCalculated,
    super.key,
  });

  /// The widget whose size is being tracked.
  final Widget child;

  /// Called after every layout pass with the child's current [Size].
  /// Only fires when the size actually changes.
  final ValueChanged<Size> onSizeCalculated;

  @override
  State<SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<SizeReporter> {
  Size? _lastSize;

  void _report(Size size) {
    if (size == _lastSize) return;
    _lastSize = size;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (mounted) widget.onSizeCalculated(size);
      },
    );
  }

  @override
  Widget build(BuildContext context) => _SizeReporterRenderWidget(
    onSize: _report,
    child: widget.child,
  );
}

class _SizeReporterRenderWidget extends SingleChildRenderObjectWidget {
  const _SizeReporterRenderWidget({required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  _SizeReporterRenderBox createRenderObject(BuildContext context) =>
      _SizeReporterRenderBox(onSize: onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _SizeReporterRenderBox renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _SizeReporterRenderBox extends RenderProxyBox {
  _SizeReporterRenderBox({required this.onSize});

  ValueChanged<Size> onSize;

  @override
  void performLayout() {
    super.performLayout();
    onSize(size);
  }
}
