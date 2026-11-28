import 'package:flutter/widgets.dart';

enum FMComponentKind { button, toggle, card, dialog, navigation }
enum FMQuality { low, medium, high }

@immutable
class FMParameters {
  const FMParameters({
    this.animationSpeed = 1,
    this.motionIntensity = 1,
    this.materialIntensity = 1,
    this.highlightIntensity = 1,
    this.ambientIntensity = 1,
    this.quality = FMQuality.high,
    this.reducedMotion = false,
  });
  final double animationSpeed, motionIntensity, materialIntensity,
      highlightIntensity, ambientIntensity;
  final FMQuality quality;
  final bool reducedMotion;
}

@immutable
class FMEngineManifest {
  FMEngineManifest({required this.id, required this.version,
    required Set<FMComponentKind> components})
      : components = Set.unmodifiable(components);
  final String id, version;
  final Set<FMComponentKind> components;
}

@immutable
class FMComponentState {
  const FMComponentState({this.pressed = false, this.hovered = false,
    this.focused = false, this.enabled = true, this.selected = false});
  final bool pressed, hovered, focused, enabled, selected;
}

abstract interface class FMEngine {
  FMEngineManifest get manifest;
  Future<void> initialize();
  FMComponentRenderer createRenderer(FMComponentKind kind);
  void dispose();
}

abstract interface class FMComponentRenderer {
  void attach();
  Size measure(BoxConstraints constraints, Size contentSize);
  void update(FMComponentState state, FMParameters parameters);
  void paint(Canvas canvas, Size size);
  void detach();
  void dispose();
}

/// Optional animation capability; static renderers need not implement it.
abstract interface class FMAnimatedRenderer implements FMComponentRenderer {
  bool get needsFrame;
  void advance(double seconds);
}

class FMEngineRegistry {
  final Map<String, FMEngine> _engines = {};
  void register(FMEngine engine) {
    final id = engine.manifest.id;
    if (_engines.containsKey(id)) {
      throw StateError('Duplicate engine: $id');
    }
    _engines[id] = engine;
  }

  FMEngine resolve(String id, FMComponentKind kind) {
    final engine = _engines[id];
    if (engine == null || !engine.manifest.components.contains(kind)) {
      throw StateError('Unsupported engine/component: $id / $kind');
    }
    return engine;
  }
}

class FMEngineScope extends InheritedWidget {
  const FMEngineScope({super.key, required this.engineId, required super.child});
  final String engineId;
  static String resolve(BuildContext context, {String? explicit, required String appDefault}) =>
      explicit ?? context.dependOnInheritedWidgetOfExactType<FMEngineScope>()?.engineId ?? appDefault;
  @override
  bool updateShouldNotify(FMEngineScope oldWidget) => engineId != oldWidget.engineId;
}
