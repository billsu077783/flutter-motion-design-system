import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'engine.dart';

/// Owns one component renderer, not the shared engine.
class FMComponentRuntime extends ChangeNotifier {
  FMComponentRuntime({required this.kind, required FMEngine engine,
    FMComponentState state = const FMComponentState(),
    FMParameters parameters = const FMParameters(), TickerProvider? vsync})
      : _state = state, _parameters = parameters {
    _renderer = _prepare(engine);
    _ticker = vsync?.createTicker(_tick);
    _syncTicker();
  }

  final FMComponentKind kind;
  late FMComponentRenderer _renderer;
  FMComponentState _state;
  FMParameters _parameters;
  bool _disposed = false;
  Ticker? _ticker;
  Duration _last = Duration.zero;

  bool get needsFrame {
    final renderer = _renderer;
    return !_disposed && renderer is FMAnimatedRenderer && renderer.needsFrame;
  }

  void _syncTicker() {
    final ticker = _ticker;
    if (ticker == null) return;
    if (needsFrame && !ticker.isActive) {
      _last = Duration.zero;
      ticker.start();
    } else if (!needsFrame && ticker.isActive) {
      ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final seconds = (elapsed - _last).inMicroseconds / 1000000;
    _last = elapsed;
    advance(seconds);
  }

  /// Also supports hosts with their own frame clock.
  void advance(double seconds) {
    _checkAlive();
    final renderer = _renderer;
    if (renderer is FMAnimatedRenderer && renderer.needsFrame) {
      renderer.advance(seconds);
      _syncTicker();
      notifyListeners();
    } else {
      _syncTicker();
    }
  }

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
    _syncTicker();
    notifyListeners();
  }

  /// The engine must already be initialized. Prepare before replacing.
  void replaceEngine(FMEngine engine) {
    _checkAlive();
    final next = _prepare(engine);
    final previous = _renderer;
    _renderer = next;
    _syncTicker();
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
    _ticker?.dispose();
    _ticker = null;
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
