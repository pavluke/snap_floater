library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../animations/snap_floater_animation.dart';
import '../../models/shap_floater_state.dart';
import '../../models/snap_floater_snapshot.dart';
import '../../models/snap_floater_storage_model.dart';
import '../../settings/snap_floater_settings.dart';
import '../../storage/snap_floater_storage.dart';
import 'basic_snap_floater_button.dart';
import 'snap_floater_child.dart';
import 'snap_preview_builder.dart';

part '../controllers/snap_floater_controller.dart';

/// {@template snap_floater_scope}
/// A draggable floating button that snaps to predefined screen positions.
///
/// Place [SnapFloaterScope] once at the root of your app — it owns the
/// controller lifecycle and exposes it to the entire subtree via
/// [SnapFloaterScope.of].
///
/// **Basic usage:**
/// ```dart
/// SnapFloaterScope(
///   onPressed: () => doSomething(),
///   child: MaterialApp(...),
/// )
/// ```
///
/// **Custom button and preview animation:**
/// ```dart
/// SnapFloaterScope.builder(
///   builder: (context) => MyFancyButton(),
///   previewBuilder: SnapFloaterAnimation.blur,
///   child: MaterialApp(...),
/// )
/// ```
///
/// Control the floater from anywhere in the tree:
/// ```dart
/// SnapFloaterScope.of(context).hide();
/// SnapFloaterScope.of(context).snapTo(Alignment.topLeft);
/// ```
///
/// See also:
/// - [SnapFloaterController], which exposes the full control API.
/// - [SnapFloaterSettings], for configuring snap targets, visibility,
/// and storage.
/// - [SnapFloaterAnimation], for built-in preview animations.
/// {@endtemplate }
class SnapFloaterScope extends StatefulWidget {
  /// {@macro snap_floater_scope}
  factory SnapFloaterScope({
    required ValueGetter<FutureOr<void>> onPressed,
    required Widget? child,
    SnapFloaterSettings settings = const SnapFloaterSettings(),
    bool useSafeArea = true,
    EdgeInsets padding = const EdgeInsets.all(10),
    Curve curve = Curves.easeOutBack,
    Key? key,
  }) =>
      SnapFloaterScope._(
        builder: (context) => BasicSnapFloaterButton(
          () => SnapFloaterScope.of(context).runHidden(onPressed),
        ),
        previewBuilder: SnapFloaterAnimation.base,
        settings: settings,
        useSafeArea: useSafeArea,
        padding: padding,
        curve: curve,
        key: key,
        child: child,
      );

  /// {@macro snap_floater_scope}
  ///
  /// Creates a fully customizable floater with custom button appearance.
  factory SnapFloaterScope.builder({
    required WidgetBuilder builder,
    required PreviewBuilder previewBuilder,
    required Widget? child,
    SnapFloaterSettings settings = const SnapFloaterSettings(),
    bool useSafeArea = true,
    EdgeInsets padding = const EdgeInsets.all(10),
    Curve curve = Curves.easeOutBack,
    Key? key,
  }) =>
      SnapFloaterScope._(
        builder: builder,
        previewBuilder: previewBuilder,
        settings: settings,
        useSafeArea: useSafeArea,
        padding: padding,
        curve: curve,
        key: key,
        child: child,
      );

  const SnapFloaterScope._({
    required this.builder,
    required this.previewBuilder,
    required this.settings,
    required this.child,
    required this.useSafeArea,
    required this.padding,
    required this.curve,
    super.key,
  });

  /// Builds the draggable button widget.
  final WidgetBuilder builder;

  /// Builds preview widgets shown at snap targets during drag.
  final PreviewBuilder previewBuilder;

  /// Configuration for behaviour and appearance.
  final SnapFloaterSettings settings;

  /// The widget subtree this scope wraps.
  final Widget? child;

  /// Whether to account for system safe area insets when calculating positions.
  final bool useSafeArea;

  /// Padding between the floater and screen edges.
  final EdgeInsets padding;

  /// Curve used for the snap animation when the user releases the floater.
  final Curve curve;

  /// {@template snap_floater_scope.of}
  /// Returns the nearest [SnapFloaterController] from the given [context].
  ///
  /// Throws an [AssertionError] in debug mode if no [SnapFloaterScope]
  /// is found in the widget tree. Use [maybeOf] if presence is not guaranteed.
  /// {@endtemplate}
  static SnapFloaterController of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_SnapFloaterInherited>();

    assert(inherited != null, 'No SnapFloaterScope found in context.');
    return inherited?.notifier ??
        (throw Exception('SnapFloaterController is not initialized!'));
  }

  /// {@macro snap_floater_scope.of}
  ///
  /// Returns `null` instead of throwing when no [SnapFloaterScope] is found.
  static SnapFloaterController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SnapFloaterInherited>()
      ?.notifier;

  @override
  State<SnapFloaterScope> createState() => _SnapFloaterScopeState();
}

class _SnapFloaterScopeState extends State<SnapFloaterScope> {
  late final SnapFloaterController _controller = SnapFloaterController(
    settings: widget.settings,
  );
  late Set<Alignment> _snapAlignments;
  late Widget floaterChild;

  @override
  void initState() {
    super.initState();
    assert(
      SnapFloaterScope.maybeOf(context) == null,
      'SnapFloaterScope already defined in context.',
    );
    _snapAlignments = widget.settings.snapAlignments.toSet();
  }

  @override
  void didUpdateWidget(SnapFloaterScope old) {
    super.didUpdateWidget(old);
    if (old.settings.snapAlignments != widget.settings.snapAlignments) {
      _snapAlignments = widget.settings.snapAlignments.toSet();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChildSizeChanged(Size size) => _controller._updateChildSize(size);

  void _onDragStart() => _controller._dragStart();

  void _onDragUpdate(Alignment alignment) =>
      _controller._updatePosition(alignment);

  void _onDragEnd(Alignment alignment) => _controller
    .._dragEnd()
    ..snapTo(alignment);

  bool _isVisible(bool isVisible) => isVisible && widget.settings.isEnabled;

  bool get _shouldShowPreview =>
      widget.settings.showPreview && _snapAlignments.length >= 2;

  @override
  Widget build(BuildContext context) {
    final floaterChild = Builder(builder: widget.builder);

    return _SnapFloaterInherited(
      notifier: _controller,
      child: Stack(
        children: [
          if (widget.child case final child?) child,
          if (_shouldShowPreview)
            ValueListenableBuilder<SnapFloaterState>(
              valueListenable: _controller,
              child: floaterChild,
              builder: (context, value, child) => SnapPreviewBuilder(
                useSafeArea: widget.useSafeArea,
                padding: widget.padding,
                isVisible: value.isDragging,
                snapAlignments: _snapAlignments,
                currentAlignment: value.alignment,
                floaterSize: value.childSize,
                previewBuilder: widget.previewBuilder,
                child: child,
              ),
            ),
          ValueListenableBuilder<SnapFloaterState>(
            valueListenable: _controller,
            child: floaterChild,
            builder: (context, value, child) => SnapFloaterChild(
              dragMode: widget.settings.dragMode,
              alignment: value.alignment,
              isDragging: value.isDragging,
              isVisible: _isVisible(value.isVisible),
              snapAlignments: _snapAlignments,
              padding: widget.padding,
              onDragStart: _onDragStart,
              onDragUpdate: _onDragUpdate,
              onDragEnd: _onDragEnd,
              onChildSizeChanged: _onChildSizeChanged,
              useSafeArea: widget.useSafeArea,
              curve: widget.curve,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapFloaterInherited extends InheritedNotifier<SnapFloaterController> {
  const _SnapFloaterInherited({
    required super.notifier,
    required super.child,
  });
}
