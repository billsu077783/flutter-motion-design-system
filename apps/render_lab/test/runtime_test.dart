import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmds_render_lab/fmds/engine.dart';
import 'package:fmds_render_lab/fmds/runtime.dart';

class TestRenderer implements FMComponentRenderer {
  TestRenderer({this.fail = false});
  final bool fail;
  int attaches = 0, detaches = 0, disposals = 0;
  FMComponentState? state;
  @override
  void attach() { attaches++; }
  @override
  void update(FMComponentState state, FMParameters parameters) {
    if (fail) throw StateError('test failure');
    this.state = state;
  }
  @override
  Size measure(BoxConstraints constraints, Size contentSize) => contentSize;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  void detach() { detaches++; }
  @override
  void dispose() { disposals++; }
}

class TestEngine implements FMEngine {
  TestEngine(this.renderer);
  final TestRenderer renderer;
  @override
  final manifest = FMEngineManifest(id: 'test', version: '1',
      components: {FMComponentKind.button});
  @override
  Future<void> initialize() async {}
  @override
  FMComponentRenderer createRenderer(FMComponentKind kind) => renderer;
  @override
  void dispose() {}
}

void main() {
  test('runtime preserves state across replacement and releases old renderer', () {
    final first = TestRenderer();
    final second = TestRenderer();
    final runtime = FMComponentRuntime(kind: FMComponentKind.button,
        engine: TestEngine(first));
    runtime.update(const FMComponentState(pressed: true), const FMParameters());
    runtime.replaceEngine(TestEngine(second));
    expect(second.state?.pressed, isTrue);
    expect(first.detaches, 1);
    expect(first.disposals, 1);
    expect(runtime.measure(const BoxConstraints(maxWidth: 20), const Size(50, 10)), const Size(20, 10));
    runtime.dispose();
    runtime.dispose();
    expect(second.disposals, 1);
  });

  test('failed replacement preserves previous renderer', () {
    final first = TestRenderer();
    final failed = TestRenderer(fail: true);
    final runtime = FMComponentRuntime(kind: FMComponentKind.button,
        engine: TestEngine(first));
    expect(() => runtime.replaceEngine(TestEngine(failed)), throwsStateError);
    expect(failed.disposals, 1);
    expect(first.disposals, 0);
    runtime.update(const FMComponentState(selected: true), const FMParameters());
    expect(first.state?.selected, isTrue);
    runtime.dispose();
  });
}
