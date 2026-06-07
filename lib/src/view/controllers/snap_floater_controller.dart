part of '../widgets/snap_floater_scope.dart';

/// {@template snap_floater_controller}
/// Controls the state and behaviour of a [SnapFloaterScope].
///
/// Obtain via [SnapFloaterScope.of] or [SnapFloaterScope.maybeOf] —
/// do not instantiate directly.
///
/// The controller is a [ValueNotifier] of [SnapFloaterState], so you can
/// listen to raw state changes if needed:
/// ```dart
/// SnapFloaterScope.of(context).addListener(() { ... });
/// ```
/// {@endtemplate}
class SnapFloaterController extends ValueNotifier<SnapFloaterState> {
  /// {@macro snap_floater_controller}
  SnapFloaterController({
    SnapFloaterSettings settings = const SnapFloaterSettings(),
  })  : _settings = settings,
        _storageModel = SnapFloaterStorageModel(
          base: SnapFloaterSnapshot(alignment: settings.initialAlignment),
        ),
        super(SnapFloaterState(alignment: settings.initialAlignment)) {
    unawaited(_init());
  }

  final SnapFloaterSettings _settings;
  SnapFloaterStorageModel _storageModel;

  SnapFloaterStorage? get _storage => _settings.storage;

  Future<void> _init() async {
    final saved = await _storage?.read();
    if (saved == null) return;
    _storageModel = saved;
    _emit(value.copyWith(alignment: saved.base.alignment));
  }

  void _emit(SnapFloaterState state) => value != state ? value = state : null;

  void _dragStart() => _emit(value.copyWith(isDragging: true));

  void _dragEnd() => _emit(value.copyWith(isDragging: false));

  void _updatePosition(Alignment alignment) {
    if (!value.isDragging) return;
    _emit(value.copyWith(alignment: alignment));
  }

  void _updateChildSize(Size size) => _emit(value.copyWith(childSize: size));

  /// Current snap alignment of the floater.
  Alignment get alignment => value.alignment;

  /// Whether the floater is currently visible.
  bool get isVisible => value.isVisible;

  /// Whether the user is actively dragging the floater.
  bool get isDragging => value.isDragging;

  /// Hides the floater. Has no effect if already hidden.
  void hide() => _emit(value.copyWith(isVisible: false));

  /// Shows the floater. Has no effect if already visible.
  void show() => _emit(value.copyWith(isVisible: true));

  /// Snaps the floater to [alignment] and persists the position to storage
  /// if a [SnapFloaterStorage] is configured.
  void snapTo(Alignment alignment) {
    _storageModel = _storageModel.copyWith(
      base: _storageModel.base.copyWith(alignment: alignment),
    );
    unawaited(_storage?.write(_storageModel));
    _emit(value.copyWith(alignment: alignment));
  }

  bool _isRunning = false;

  /// Hides the floater while [action] runs, then shows it again.
  ///
  /// If [action] is synchronous the floater is hidden for its duration
  /// and shown immediately after. If it returns a [Future], the floater
  /// stays hidden until the future completes — even if it throws.
  ///
  /// ```dart
  /// await controller.runHidden(() async {
  ///   await Navigator.of(context).push(...);
  /// });
  /// ```

  Future<void> runHidden(ValueGetter<FutureOr<void>> action) async {
    if (_isRunning) return;

    _isRunning = true;
    try {
      final result = action();
      if (result is Future) {
        hide();
        await result;
      }
    } finally {
      show();
      _isRunning = false;
    }
  }
}
