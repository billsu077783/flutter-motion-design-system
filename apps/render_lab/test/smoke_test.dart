import 'dart:io';
import 'dart:ui' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:fmds_render_lab/main.dart';

void main() {
  test('parameter contract', () {
    expect(specs.length, 28);
    for (final s in [...specs.values, ...dualSpecs.values, ...adaptiveSpecs.values]) {
      expect(s.length, 4);
      expect(s.every((v) => v.isFinite), isTrue);
      expect(s[2], greaterThan(0));
      expect(s[3], inInclusiveRange(s[0], s[1]));
    }
    expect(specs['edgeHighlight']![3], 1.35);
    expect(specs['refractionDetail']![3], .25);
    expect(specs['mass']![3], 1);
    expect(specs['stiffness']![3], 180);
    expect(specs['damping']![3], 12);
  });

  test('frozen glass shader uniform ABI', () {
    final source = File('shaders/fd2_glass.frag').readAsStringSync();
    final uniforms = RegExp(r'^uniform\s+(\w+)\s+(\w+);', multiLine: true)
        .allMatches(source)
        .map((m) => '${m[1]} ${m[2]}')
        .toList();
    expect(uniforms, [
      'vec2 size',
      for (final name in [
        'progress', 'dark', 'model', 'ior', 'roughness', 'thickness',
        'transmission', 'env', 'bevel', 'depth', 'tint', 'angle',
        'exposure', 'blur', 'rim', 'shadow', 'crown', 'refraction',
        'highlight', 'bevelWidth', 'fresnel', 'contrast', 'dispersion',
        'edgeHighlight', 'highlightWidth', 'surfaceReflection',
        'ambientLift', 'refractionDetail', 'thinShell',
        ...dualSpecs.keys, ...adaptiveSpecs.keys,
      ]) 'float $name',
      'sampler2D scene', 'sampler2D softScene', 'sampler2D environmentMap',
    ]);
  });

  testWidgets('index renders without layout exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FMDSApp());
    expect(find.text('FMDS'), findsOneWidget);
    expect(find.text('Glass'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
