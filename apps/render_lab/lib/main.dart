import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

void main() => runApp(const RenderLab());

class RenderLab extends StatefulWidget {
  const RenderLab({super.key});

  @override
  State<RenderLab> createState() => _RenderLabState();
}

class _RenderLabState extends State<RenderLab> {
  ui.Image? scene;
  ui.Image? blurred;
  int blurGeneration = 0;
  ui.FragmentShader? shader;
  String? error;
  double refraction = 24;
  double blur = 3;
  double thickness = 0.8;
  double highlight = 0.8;
  double tint = 0.06;
  double dispersion = 0.05;
  bool compare = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/glass.frag');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();
      const colors = [
        Color(0xffe6b9ae),
        Color(0xff829fc9),
        Color(0xffc4b5e4),
        Color(0xff85bdb8),
      ];
      for (var i = 0; i < 16; i++) {
        paint.color = colors[i % colors.length];
        canvas.drawRect(Rect.fromLTWH(i * 32, 0, 32, 320), paint);
      }
      paint.color = const Color(0xff344968);
      canvas.drawCircle(const Offset(155, 130), 70, paint);
      paint.color = const Color(0xfff4dfaf);
      canvas.drawCircle(const Offset(355, 190), 82, paint);
      final picture = recorder.endRecording();
      final image = await picture.toImage(512, 320);
      final blurRecorder = ui.PictureRecorder();
      final blurCanvas = Canvas(blurRecorder);
      blurCanvas.saveLayer(const Rect.fromLTWH(0, 0, 512, 320), Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3, tileMode: ui.TileMode.clamp));
      blurCanvas.drawImage(image, Offset.zero, Paint());
      blurCanvas.restore();
      final blurPicture = blurRecorder.endRecording();
      final filtered = await blurPicture.toImage(512, 320);
      blurPicture.dispose();
      picture.dispose();
      if (!mounted) {
        image.dispose();
        filtered.dispose();
        return;
      }
      setState(() {
        scene = image;
        blurred = filtered;
        shader = program.fragmentShader();
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> changeBlur(double value) async {
    setState(() => blur = value);
    final source = scene;
    if (source == null) return;
    final generation = ++blurGeneration;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (value > 0) {
      canvas.saveLayer(const Rect.fromLTWH(0, 0, 512, 320), Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: value, sigmaY: value, tileMode: ui.TileMode.clamp));
    }
    canvas.drawImage(source, Offset.zero, Paint());
    if (value > 0) canvas.restore();
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(512, 320);
      if (!mounted || generation != blurGeneration) {
        image.dispose();
        return;
      }
      final old = blurred;
      setState(() => blurred = image);
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    } finally {
      picture.dispose();
    }
  }

  @override
  void dispose() {
    scene?.dispose();
    blurred?.dispose();
    shader?.dispose();
    super.dispose();
  }

  Widget control(String label, double value, double max, ValueChanged<double> onChange) {
    return Column(
      children: [
        Text('$label: ${value.toStringAsFixed(2)}'),
        GestureDetector(
          onTapDown: (e) => onChange((e.localPosition.dx / 280).clamp(0.0, 1.0).toDouble() * max),
          onHorizontalDragUpdate: (e) => onChange((e.localPosition.dx / 280).clamp(0.0, 1.0).toDouble() * max),
          child: SizedBox(
            width: 280,
            height: 40,
            child: Center(
              child: Stack(
                children: [
                  Container(height: 8, color: const Color(0xff435168)),
                  Container(width: 280 * value / max, height: 8, color: const Color(0xffaac6e8)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xff172337),
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xffeeeeff), fontSize: 16),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('FMDS Render Lab v0.3.3'),
                    const SizedBox(height: 16),
                    if (error != null) Text(error!),
                    if (scene == null && error == null) const Text('Loading shader'),
                    if (scene != null && blurred != null && shader != null)
                      SizedBox(
                        width: 320,
                        height: 200,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(painter: OpticalPainter(scene!, blurred!, shader!, refraction, blur, compare, thickness, highlight, tint, dispersion)),
                            const Center(child: Text('Optical Glass', style: TextStyle(color: Color(0xff172337), fontSize: 20, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    control('Refraction', refraction, 48, (v) => setState(() => refraction = v)),
                    control('Blur sigma', blur, 12, changeBlur),
                    control('Thickness', thickness, 1.5, (v) => setState(() => thickness = v)),
                    control('Highlight', highlight, 1.5, (v) => setState(() => highlight = v)),
                    control('Tint', tint, 0.8, (v) => setState(() => tint = v)),
                    control('Dispersion', dispersion, 1, (v) => setState(() => dispersion = v)),
                    GestureDetector(
                      onTap: () { setState(() { refraction = 24; thickness = 0.8; highlight = 0.8; tint = 0.06; dispersion = 0.05; compare = false; }); changeBlur(3); },
                      child: const Padding(padding: EdgeInsets.all(12), child: Text('Reset parameters')),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => compare = !compare),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(compare ? 'Mode: blur only (tap)' : 'Mode: optical (tap)'),
                      ),
                    ),
                    const Text('Explicit scene texture / GPU shader experiment'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OpticalPainter extends CustomPainter {
  OpticalPainter(this.scene, this.blurred, this.shader, this.refraction, this.blur, this.compare, this.thickness, this.highlight, this.tint, this.dispersion);

  final ui.Image scene;
  final ui.Image blurred;
  final ui.FragmentShader shader;
  final double refraction;
  final double blur;
  final bool compare;
  final double thickness;
  final double highlight;
  final double tint;
  final double dispersion;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, refraction)
      ..setFloat(3, blur)
      ..setFloat(4, compare ? 1 : 0)
      ..setFloat(5, thickness)
      ..setFloat(6, highlight)
      ..setFloat(7, tint)
      ..setFloat(8, dispersion)
      ..setImageSampler(0, scene)
      ..setImageSampler(1, blurred);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(OpticalPainter oldDelegate) => true;
}
