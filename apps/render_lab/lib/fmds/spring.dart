import 'dart:math' as math;

/// Semi-implicit Euler integration, matching the frozen Glass lab step size.
class FMSpring {
  FMSpring({this.value = 0});
  double value;
  double velocity = 0;
  double target = 0;
  bool get settled => (value - target).abs() < .001 && velocity.abs() < .005;

  void snap(double next) {
    target = next;
    value = next;
    velocity = 0;
  }

  void advance(double seconds, {required double mass,
    required double stiffness, required double damping}) {
    if (!seconds.isFinite || !mass.isFinite || mass <= 0 ||
        !stiffness.isFinite || stiffness <= 0 || !damping.isFinite || damping < 0) {
      throw ArgumentError('Invalid spring parameters');
    }
    var remaining = seconds.clamp(0.0, .1).toDouble();
    while (remaining > 0) {
      final h = math.min(remaining, 1 / 240);
      velocity += (-stiffness * (value - target) - damping * velocity) / mass * h;
      value += velocity * h;
      remaining -= h;
    }
    if (settled) snap(target);
  }
}
