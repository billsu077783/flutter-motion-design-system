import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:fmds_render_lab/fmds/engine.dart';

class FakeEngine implements FMEngine {
  @override
  final manifest = FMEngineManifest(id: 'test', version: '1.0.0',
      components: {FMComponentKind.button});
  @override
  Future<void> initialize() async {}
  @override
  FMComponentRenderer createRenderer(FMComponentKind kind) => throw UnimplementedError();
  @override
  void dispose() {}
}

void main() {
  test('registry rejects duplicate and unsupported engines', () {
    final registry = FMEngineRegistry();
    final engine = FakeEngine();
    registry.register(engine);
    expect(registry.resolve('test', FMComponentKind.button), same(engine));
    expect(() => registry.register(engine), throwsStateError);
    expect(() => registry.resolve('test', FMComponentKind.card), throwsStateError);
    expect(() => registry.resolve('missing', FMComponentKind.button), throwsStateError);
  });
  testWidgets('explicit selection overrides nearest scope and default', (tester) async {
    await tester.pumpWidget(FMEngineScope(engineId: 'outer',
      child: FMEngineScope(engineId: 'inner', child: Builder(builder: (context) {
        expect(FMEngineScope.resolve(context, appDefault: 'default'), 'inner');
        expect(FMEngineScope.resolve(context, explicit: 'explicit', appDefault: 'default'), 'explicit');
        return const SizedBox();
      }))));
  });
}
