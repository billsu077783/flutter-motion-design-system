import 'package:flutter/widgets.dart';
import 'engine.dart';

/// Owns one component renderer, not the shared engine.
class FMComponentRuntime extends ChangeNotifier {
  FMComponentRuntime({required this.kind, required FMEngine engine,
    FMComponentState state = const FMComponentState(),
    FMParameters parameters = const FMParameters()})
      : _state = state, _parameters = parameters {
    _renderer = _prepare(engine);
  }

  final FMComponentKind kind;
  late FMComponentRenderer _renderer;
  FMComponentState _state;
  FMParameters _parameters;
  bool _disposed = false;

  FMComponentRenderer _prepare(FMEngine engine) {
    if (!engine.manifest.components.contains(kind)) {
      throw StateError('Unsupported component: $kind');
    }
    final renderer = engine.createRenderer(kind);
    var attached = false;
    try {
      renderer.attach();
      attached = true;
      renderer.update(_state, _parameters);
      return renderer;
    } catch (_) {
      try {
        if (attached) renderer.detach();
      } finally {
        renderer.dispose();
      }
      rethrow;
    }
  }

  void update(FMComponentState state, FMParameters parameters) {
    _checkAlive();
    _renderer.update(state, parameters);
    _state = state;
    _parameters = parameters;
    notifyListeners();
  }

  /// The engine must already be initialized. Prepare before replacing.
  void replaceEngine(FMEngine engine) {
    _checkAlive();
    final next = _prepare(engine);
    final previous = _renderer;
    _renderer = next;
    try {
      previous.detach();
    } finally {
      try {
        previous.dispose();
      } finally {
        notifyListeners();
      }
    }
  }

  Size measure(BoxConstraints constraints, Size contentSize) {
    _checkAlive();
    return constraints.constrain(_renderer.measure(constraints, contentSize));
  }

  void paint(Canvas canvas, Size size) {
    _checkAlive();
    _renderer.paint(canvas, size);
  }

  void _checkAlive() {
    if (_disposed) throw StateError('Component runtime disposed');
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      _renderer.detach();
    } finally {
      try {
        _renderer.dispose();
      } finally {
        super.dispose();
      }
    }
  }
}
