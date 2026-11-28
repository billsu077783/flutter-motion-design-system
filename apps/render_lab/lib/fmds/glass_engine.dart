import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'engine.dart';
import 'spring.dart';

const specs=<String,List<double>>{
'ior':[1,2,.01,1.46],'roughness':[0,.65,.01,.08],'thickness':[0,1.5,.01,.42],'transmission':[0,1,.01,1],'envMapIntensity':[0,4,.05,1.5],'bevel':[.02,.32,.01,.16],'depth':[.05,.5,.01,.20],'tint':[0,.8,.01,0],'angle':[0,360,1,315],'exposure':[.5,2,.05,1.15],'blur':[0,18,.5,5],'rimLight':[0,1,.05,.65],'shadow':[0,.6,.02,.22],'crown':[0,.15,.005,.06],'refraction':[0,48,1,24],'highlight':[0,1.5,.05,.85],'mass':[.5,3,.1,1],'stiffness':[60,380,1,180],'damping':[4,70,1,12],'bevelWidth':[.05,.45,.01,.18],'fresnel':[0,1,.05,.65],'contrast':[0,1,.05,.22],'dispersion':[0,.3,.01,.05],'edgeHighlight':[0,2,.05,1.35],'highlightWidth':[.02,.5,.01,.18],'surfaceReflection':[0,.6,.01,.18],'ambientLift':[0,.4,.01,.10],'refractionDetail':[0,1,.05,.25]};
const dualSpecs=<String,List<double>>{'topReflection':[0,1.5,.05,.85],'bottomReflection':[0,1.5,.05,.55],'sideReflection':[0,1.5,.05,.20],'softReflection':[0,.4,.01,.12],'surfaceCurvature':[0,.08,.005,.025],'surfaceFalloff':[0,1,.05,.65]};
const adaptiveSpecs=<String,List<double>>{'reflectionWidth':[.5,3,.1,1.2],'reflectionFalloff':[1,4,.1,2],'adaptiveContrast':[0,1,.05,.65],'darkEdgeStrength':[0,.4,.01,.12]};
const thinDefaults=<String,double>{'thickness':.18,'bevel':.07,'depth':.08,'crown':.015,'highlightWidth':.06,'surfaceReflection':.08,'ambientLift':.02,'shadow':.08,'contrast':.08};

class PortPainter extends CustomPainter{PortPainter(this.image,this.soft,this.shader,this.p,this.progress,this.dark,this.model,this.environment,this.diagnostic,this.profile,this.dual);final Map<String,double> dual;final int profile;final int diagnostic;final ui.Image image,soft,environment;final ui.FragmentShader shader;final Map<String,double> p;final double progress,model;final bool dark;@override void paint(Canvas c,Size s){final values=[s.width,s.height,progress,dark?1.0:0.0,model==0?diagnostic.toDouble():model,for(final k in ['ior','roughness','thickness','transmission','envMapIntensity','bevel','depth','tint','angle','exposure','blur','rimLight','shadow','crown','refraction','highlight','bevelWidth','fresnel','contrast','dispersion','edgeHighlight','highlightWidth','surfaceReflection','ambientLift','refractionDetail']) k=='angle'?p[k]!*math.pi/180:p[k]!];for(int i=0;i<values.length;i++){shader.setFloat(i,values[i]);}if(model==0){shader.setFloat(values.length,profile.toDouble());int j=values.length+1;for(final key in [...dualSpecs.keys,...adaptiveSpecs.keys]){shader.setFloat(j++,dual[key]!);}}shader.setImageSampler(0,image);shader.setImageSampler(1,soft);if(model==0)shader.setImageSampler(2,environment);c.drawRect(Offset.zero&s,Paint()..shader=shader);}@override bool shouldRepaint(covariant PortPainter oldDelegate)=>true;}


/// Shared shader program; each renderer owns its own shader.
/// Scene textures are borrowed from the host and must outlive paint.
class FMGlassEngine implements FMEngine {
  ui.FragmentProgram? _program;
  bool _disposed = false;
  @override
  final manifest = FMEngineManifest(id: 'glass', version: '1.0.0',
      components: {FMComponentKind.button, FMComponentKind.card});
  @override
  Future<void> initialize() async {
    if (_disposed) throw StateError('Glass engine disposed');
    final program = await ui.FragmentProgram.fromAsset('shaders/fd2_glass.frag');
    if (_disposed) throw StateError('Glass engine disposed');
    _program = program;
  }
  @override
  FMGlassRenderer createRenderer(FMComponentKind kind) {
    final program = _program;
    if (_disposed || program == null || !manifest.components.contains(kind)) {
      throw StateError('Glass engine unavailable for $kind');
    }
    return FMGlassRenderer(program.fragmentShader());
  }
  @override
  void dispose() { _disposed = true; _program = null; }
}

class FMGlassRenderer implements FMAnimatedRenderer {
  FMGlassRenderer(this._shader);
  final ui.FragmentShader _shader;
  bool _attached = false, _disposed = false;
  final FMSpring _spring = FMSpring();
  double _speed = 1;
  @override
  bool get needsFrame => !_spring.settled;
  @override
  void advance(double seconds) {
    if (!_attached || _disposed) return;
    _spring.advance(seconds * _speed, mass: optics['mass']!,
      stiffness: optics['stiffness']!, damping: optics['damping']!);
  }
  ui.Image? _scene, _soft, _environment;
  bool _dark = false;
  final optics = specs.map((k,v) => MapEntry(k,v[3]));
  final lighting = {...dualSpecs.map((k,v)=>MapEntry(k,v[3])),
    ...adaptiveSpecs.map((k,v)=>MapEntry(k,v[3])), 'bottomReflection': .75};
  void setScene(ui.Image scene, ui.Image soft, ui.Image environment, {bool dark = false}) {
    _scene = scene; _soft = soft; _environment = environment; _dark = dark;
  }
  @override
  void attach() {
    if (_disposed) throw StateError('Renderer disposed');
    _attached = true;
  }
  @override
  Size measure(BoxConstraints constraints, Size contentSize) => constraints.constrain(contentSize);
  @override
  void update(FMComponentState state, FMParameters parameters) {
    _speed = parameters.animationSpeed.isFinite ? parameters.animationSpeed.clamp(0.1, 4.0).toDouble() : 1;
    final target = state.enabled && state.pressed ? parameters.motionIntensity.clamp(0.0,1.0).toDouble() : 0.0;
    _spring.target = target;
    if (parameters.reducedMotion) _spring.snap(target);
  }
  @override
  void paint(Canvas canvas, Size size) {
    final scene = _scene, soft = _soft, environment = _environment;
    if (!_attached || _disposed || scene == null || soft == null || environment == null) return;
    final p = {...optics, for(final e in thinDefaults.entries)
      e.key: (optics[e.key]! + e.value - specs[e.key]![3]).clamp(specs[e.key]![0], specs[e.key]![1]).toDouble()};
    PortPainter(scene, soft, _shader, p, _spring.value, _dark, 0, environment, 0, 5, lighting).paint(canvas,size);
  }
  @override
  void detach() { _attached = false; _scene = null; _soft = null; _environment = null; }
  @override
  void dispose() { if (_disposed) return; detach(); _disposed = true; _shader.dispose(); }
}
