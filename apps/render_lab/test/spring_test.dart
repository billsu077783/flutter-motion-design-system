import 'package:flutter_test/flutter_test.dart';
import 'package:fmds_render_lab/fmds/spring.dart';

void main() {
  test('spring converges and preserves velocity on retarget', () {
    final spring = FMSpring()..target = 1;
    spring.advance(.016, mass: 1, stiffness: 180, damping: 12);
    expect(spring.value, greaterThan(0));
    final velocity = spring.velocity;
    spring.target = 0;
    expect(spring.velocity, velocity);
    for (var i = 0; i < 300; i++) {
      spring.advance(1 / 60, mass: 1, stiffness: 180, damping: 12);
    }
    expect(spring.settled, isTrue);
    expect(spring.value, 0);
  });
  test('snap clears velocity and invalid mass is rejected', () {
    final spring = FMSpring()..velocity = 2;
    spring.snap(1);
    expect(spring.velocity, 0);
    expect(spring.value, 1);
    expect(() => spring.advance(.016, mass: 0, stiffness: 180, damping: 12),
        throwsArgumentError);
  });
}
