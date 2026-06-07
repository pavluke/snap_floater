import '../models/snap_floater_storage_model.dart';

/// Persistence contract for [SnapFloaterStorageModel].
///
/// Implement this interface to persist the floater's position across
/// app launches using any storage backend (SharedPreferences, Hive, etc.):
///
/// ```dart
/// class PrefsStorage implements SnapFloaterStorage {
///   @override
///   Future<SnapFloaterStorageModel?> read() async {
///     final raw = prefs.getString('snap_floater');
///     if (raw == null) return null;
///     return SnapFloaterStorageModel.fromJson(jsonDecode(raw));
///   }
///
///   @override
///   Future<void> write(SnapFloaterStorageModel model) =>
///       prefs.setString('snap_floater', jsonEncode(model.toJson()));
///
///   @override
///   Future<void> clear() => prefs.remove('snap_floater');
/// }
/// ```
abstract interface class SnapFloaterStorage {
  /// Reads the previously persisted model, or `null` if nothing was saved.
  Future<SnapFloaterStorageModel?> read();

  /// Writes [model] to the underlying storage.
  Future<void> write(SnapFloaterStorageModel model);

  /// Removes all persisted data.
  /// The floater will reset to [SnapFloaterSettings.initialAlignment]
  /// on the next cold start.
  Future<void> clear();
}
