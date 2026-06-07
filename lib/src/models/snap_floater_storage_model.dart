import 'package:flutter/foundation.dart';

import 'snap_floater_snapshot.dart';

/// {@template snap_floater_storage_model}
/// Persistent state written to and read from storage.
///
/// Separates storage concerns from the runtime [SnapFloaterState] —
/// only data that needs to survive app restarts lives here.
///
/// Currently stores only [base] alignment; extend with route-specific
/// overrides for complex multi-route apps.
/// {@endtemplate}
@immutable
class SnapFloaterStorageModel {
  /// {@macro snap_floater_storage_model}
  const SnapFloaterStorageModel({
    required this.base,
  });

  /// Deserializes from JSON storage format.
  factory SnapFloaterStorageModel.fromJson(Map<String, dynamic> json) =>
      SnapFloaterStorageModel(
        base: SnapFloaterSnapshot.fromJson(
          json['base'] as Map<String, dynamic>,
        ),
      );

  /// The default snapshot used when no per-route override exists.
  final SnapFloaterSnapshot base;

  /// Creates a new instance with specified fields replaced.
  SnapFloaterStorageModel copyWith({
    SnapFloaterSnapshot? base,
  }) =>
      SnapFloaterStorageModel(
        base: base ?? this.base,
      );

  /// Serializes to JSON storage format.
  Map<String, dynamic> toJson() => {
        'base': base.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnapFloaterStorageModel && base == other.base;

  @override
  int get hashCode => base.hashCode;

  @override
  String toString() => 'SnapFloaterStorageModel(base: $base)';
}
