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
  }) : assert(
         settings.snapAlignments.isNotEmpty,
         'snapAlignments must not be empty',
       ),
       assert(
         settings.snapAlignments.toSet().length ==
             settings.snapAlignments.length,
         'snapAlignments must not contain duplicates',
       ),
       _settings = settings,
       _storageModel = SnapFloaterStorageModel(
         base: SnapFloaterSnapshot(alignment: settings.snapAlignments.first),
       ),
       super(SnapFloaterState(alignment: settings.snapAlignments.first)) {
    unawaited(_init());
  }

  SnapFloaterSettings _settings;
  SnapFloaterStorageModel _storageModel;
  bool _disposed = false;

  /// Set once the user (or code) has moved the floater, so a slow storage
  /// read never overwrites a newer position.
  bool _touched = false;

  SnapFloaterStorage? get _storage => _settings.storage;

  Future<void> _init() async {
    final storage = _storage;
    if (storage == null) return;
    try {
      final saved = await storage.read();
      if (_disposed || _touched || saved == null) return;
      final alignment = saved.base.alignment;
      // The saved position may come from an older list of snap targets.
      if (!_settings.snapAlignments.contains(alignment)) return;
      _storageModel = saved;
      _emit(value.copyWith(alignment: alignment));
    } on Object catch (e) {
      debugPrint('SnapFloater: failed to restore position: $e');
    }
  }

  Future<void> _persist() async {
    try {
      await _storage?.write(_storageModel);
    } on Object catch (e) {
      debugPrint('SnapFloater: failed to persist position: $e');
    }
  }

  /// Applies new settings from the owning scope.
  void _updateSettings(SnapFloaterSettings settings) {
    assert(
      settings.snapAlignments.isNotEmpty,
      'snapAlignments must not be empty',
    );
    assert(
      settings.snapAlignments.toSet().length == settings.snapAlignments.length,
      'snapAlignments must not contain duplicates',
    );
    _settings = settings;
    if (!value.isDragging &&
        !settings.snapAlignments.contains(value.alignment)) {
      final first = settings.snapAlignments.first;
      // Called from didUpdateWidget (build phase): notify after the frame.
      scheduleMicrotask(() => _emit(value.copyWith(alignment: first)));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _emit(SnapFloaterState state) {
    if (_disposed || value == state) return;
    value = state;
  }

  void _dragStart() {
    _touched = true;
    _emit(value.copyWith(isDragging: true));
  }

  void _dragEnd() => _emit(value.copyWith(isDragging: false));

  void _updatePosition(Alignment alignment) {
    if (!value.isDragging) return;
    _emit(value.copyWith(alignment: alignment));
  }

  void _updateChildSize(Size size) => _emit(value.copyWith(childSize: size));

  /// Current snap alignment of the floater.
  Alignment get alignment => value.alignment;

  /// Whether the floater is currently visible.
  ///
  /// Always `false` while [SnapFloaterSettings.isEnabled] is `false`.
  bool get isVisible => _settings.isEnabled && value.isVisible;

  /// Whether the user is actively dragging the floater.
  bool get isDragging => value.isDragging;

  /// Hides the floater. Has no effect if already hidden.
  void hide() => _emit(value.copyWith(isVisible: false));

  /// Shows the floater. Has no effect if already visible, and none while
  /// [SnapFloaterSettings.isEnabled] is `false` ([isVisible] stays `false`).
  void show() => _emit(value.copyWith(isVisible: true));

  /// Snaps the floater to [alignment] and persists the position to storage
  /// if a [SnapFloaterStorage] is configured.
  ///
  /// Storage errors are logged and never reach the caller.
  void snapTo(Alignment alignment) {
    if (_disposed) return;
    _touched = true;
    _storageModel = _storageModel.copyWith(
      base: _storageModel.base.copyWith(alignment: alignment),
    );
    unawaited(_persist());
    _emit(value.copyWith(alignment: alignment));
  }

  bool _isRunning = false;

  /// Hides the floater while [action] runs, then shows it again.
  ///
  /// The floater is hidden for the duration of [action] whether it is
  /// synchronous or returns a [Future], and is shown again when it
  /// completes — even if it throws.
  ///
  /// A call made while another [runHidden] is still running is ignored
  /// (protects against double taps).
  ///
  /// ```dart
  /// await controller.runHidden(() async {
  ///   await Navigator.of(context).push(...);
  /// });
  /// ```
  Future<void> runHidden(ValueGetter<FutureOr<void>> action) async {
    if (_isRunning) return;

    _isRunning = true;
    hide();
    try {
      await action();
    } finally {
      _isRunning = false;
      show();
    }
  }
}
