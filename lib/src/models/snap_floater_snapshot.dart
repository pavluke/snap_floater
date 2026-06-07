import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// {@template snap_floater_snapshot}
/// A saved snapshot of the floater's user-facing state.
///
/// Used as the value type in [SnapFloaterStorageModel].
/// Currently stores [alignment]; extend this class
/// to persist additional per-session state like size or visibility.
/// {@endtemplate}
@immutable
class SnapFloaterSnapshot {
  /// {@macro snap_floater_snapshot}
  const SnapFloaterSnapshot({
    required this.alignment,
  });

  /// Deserializes from JSON storage format.
  factory SnapFloaterSnapshot.fromJson(Map<String, dynamic> json) =>
      SnapFloaterSnapshot(
        alignment: Alignment(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
      );

  /// The saved snap alignment.
  final Alignment alignment;

  /// Creates a new instance with specified fields replaced.
  SnapFloaterSnapshot copyWith({Alignment? alignment}) => SnapFloaterSnapshot(
        alignment: alignment ?? this.alignment,
      );

  /// Serializes to JSON storage format.
  Map<String, dynamic> toJson() => {
        'x': alignment.x,
        'y': alignment.y,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnapFloaterSnapshot && alignment == other.alignment;

  @override
  int get hashCode => alignment.hashCode;

  @override
  String toString() => 'SnapFloaterSnapshot(alignment: $alignment)';
}
