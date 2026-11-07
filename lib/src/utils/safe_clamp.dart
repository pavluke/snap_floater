/// Internal helper (not exported).
extension SafeClampX on double {
  /// Like [num.clamp] but never throws when `max < min`
  /// (tiny screen / split-screen): the lower bound wins.
  double clampSafe(double min, double max) =>
      clamp(min, max < min ? min : max).toDouble();
}
