import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'fmds/glass_engine.dart';
const fmdsVersion = String.fromEnvironment('FMDS_VERSION', defaultValue: '0.1.4');
const fmdsEnvironment = String.fromEnvironment('FMDS_ENV', defaultValue: 'local');
const fmdsCommit = String.fromEnvironment('FMDS_COMMIT', defaultValue: 'local');
const fmdsPr = String.fromEnvironment('FMDS_PR');
const fmdsBuildLabel = fmdsEnvironment == 'preview' ? 'PR #$fmdsPr · $fmdsCommit' : '$fmdsEnvironment · $fmdsCommit';
void main()=>runApp(const FMDSApp());
class RenderLab extends StatefulWidget{const RenderLab({super.key});@override State<RenderLab> createState()=>_Lab();}
class _Lab extends State<RenderLab> with SingleTickerProviderStateMixin{
final p=specs.map((k,v)=>MapEntry(k,v[3]));int profile=5;bool versionCompare=false;final dual={...dualSpecs.map((k,v)=>MapEntry(k,v[3])),...adaptiveSpecs.map((k,v)=>MapEntry(k,v[3])),'bottomReflection':.75};final versionShaders=<ui.FragmentShader>[];bool get thin=>profile>0;Map<String,double> fd2Params([int? version])=>(version??profile)>0?{...p,...{for(final e in thinDefaults.entries)e.key:(p[e.key]!+e.value-specs[e.key]![3]).clamp(specs[e.key]![0],specs[e.key]![1]).toDouble()}}:Map.of(p);bool dark=false,app=false,moving=false,busy=false;double progress=0,target=0,velocity=0,phase=0;Duration last=Duration.zero;late Ticker ticker;ui.Image? image,softA,softB,environment;bool queued=false;double displayedPhase=0;bool displayedDark=false,displayedApp=false,displayedMoving=false;double fps=0;int frames=0;double frameSeconds=0;ui.FragmentShader? a,b;String? error;bool solo=false;int diagnostic=0;
@override void initState(){super.initState();ticker=createTicker(tick);load();}
Future<void> load() async {try{final pa=await ui.FragmentProgram.fromAsset('shaders/fd2_glass.frag');if(!mounted)return;a=pa.fragmentShader();environment=await makeEnvironment();if(!mounted){environment?.dispose();return;}await scene();}catch(e){if(mounted)setState(()=>error=e.toString());}}
Future<ui.Image> makeEnvironment() async {
 final rec=ui.PictureRecorder();final c=Canvas(rec);
 const rect=Rect.fromLTWH(0,0,256,256);
 c.drawRect(rect,Paint()..shader=ui.Gradient.linear(const Offset(0,0),const Offset(0,256),const [Color(0xffe8f3ff),Color(0xff849bb8),Color(0xffdbe8fa)]));
 for(final box in [const Rect.fromLTWH(12,18,232,38),const Rect.fromLTWH(180,72,42,150),const Rect.fromLTWH(20,208,170,24)]){
 c.drawRRect(RRect.fromRectAndRadius(box,const Radius.circular(12)),Paint()..color=const Color(0xfff9fcff)..maskFilter=const MaskFilter.blur(BlurStyle.normal,7));
 }
 final pic=rec.endRecording();try{return await pic.toImage(256,256);}finally{pic.dispose();}
}
Future<void> scene() async {if(busy){queued=true;return;}busy=true;final capturePhase=phase,captureDark=dark,captureApp=app,captureMoving=moving;final sigma=p['blur']!;final rough=p['roughness']!;final rec=ui.PictureRecorder();final c=Canvas(rec);c.scale(3.2);final paint=Paint();void rect(double x,double y,double w,double h,Color color){c.drawRect(Rect.fromLTWH(x,y,w,h),paint..color=color);}void label(String s,double x,double y,double size,Color color){final t=TextPainter(text:TextSpan(text:s,style:TextStyle(fontSize:size,color:color)),textDirection:TextDirection.ltr)..layout();t.paint(c,Offset(x,y));t.dispose();}
final colors=dark?[0xff44374d,0xff304967,0xff4d4668,0xff325b60]:[0xffe6b9ae,0xff829fc9,0xffc4b5e4,0xff85bdb8];for(int i=0;i<16;i++){rect(i*20.0,0,20,200,Color(colors[i%4]));}c.drawCircle(const Offset(96.875,81.25),43.75,paint..color=Color(dark?0xff92b6e8:0xff344968));c.drawCircle(const Offset(221.875,118.75),51.25,paint..color=Color(dark?0xffd8a56d:0xfff4dfaf));if(app){rect(0,0,320,200,Color(dark?0xff23364e:0xffedf2f8));label('Today',20,12,15,Color(dark?0xffb9d2f4:0xff23364e));for(int j=0;j<3;j++){rect(20,40+j*47.0,279,36,Color(dark?0xff405b78:0xffb7cce8));label(['Your activity','Recent messages','Discover more'][j],31,49+j*47.0,10,Color(dark?0xffffffff:0xff23364e));}}if(moving)c.drawCircle(Offset(160+math.sin(phase)*109.375,100),15,paint..color=Color(dark?0xffa9c7ff:0xffe879a0));final pic=rec.endRecording();try{final next=await pic.toImage(1024,640);ui.Image? sa,sb;try{sb=await soften(next,sigma);sa=rough==0?sb.clone():await soften(next,math.sqrt(sigma*sigma+rough*rough*81));}catch(e){next.dispose();sa?.dispose();sb?.dispose();rethrow;}if(!mounted){next.dispose();sa.dispose();sb.dispose();return;}final old=image,oa=softA,ob=softB;setState((){image=next;softA=sa;softB=sb;displayedPhase=capturePhase;displayedDark=captureDark;displayedApp=captureApp;displayedMoving=captureMoving;});WidgetsBinding.instance.addPostFrameCallback((_){old?.dispose();oa?.dispose();ob?.dispose();});}catch(e){if(mounted)setState(()=>error=e.toString());}finally{pic.dispose();busy=false;if(queued&&mounted){queued=false;scene();}}}
Future<ui.Image> soften(ui.Image source,double sigma) async {final rec=ui.PictureRecorder();final c=Canvas(rec);final paint=Paint();if(sigma>0)paint.imageFilter=ui.ImageFilter.blur(sigmaX:sigma*3.2,sigmaY:sigma*3.2,tileMode:TileMode.clamp);c.drawImage(source,Offset.zero,paint);final pic=rec.endRecording();try{return await pic.toImage(1024,640);}finally{pic.dispose();}}
void tick(Duration now){final elapsed=(now-last).inMicroseconds/1e6;double dt=elapsed.clamp(0,.1).toDouble();last=now;frames++;frameSeconds+=elapsed;if(frameSeconds>=.5){fps=frames/frameSeconds;frames=0;frameSeconds=0;}while(dt>0){final h=math.min(dt,1/240);velocity+=(-p['stiffness']!*(progress-target)-p['damping']!*velocity)/p['mass']!*h;progress+=velocity*h;dt-=h;if(moving)phase+=h;}if((progress-target).abs()<.001&&velocity.abs()<.005){progress=target;velocity=0;if(!moving)ticker.stop();}if(moving&&!busy)scene();setState((){});}
void start(){if(!ticker.isActive){last=Duration.zero;ticker.start();}}
@override void dispose(){ticker.dispose();image?.dispose();softA?.dispose();softB?.dispose();environment?.dispose();a?.dispose();b?.dispose();for(final shader in versionShaders){shader.dispose();}super.dispose();}
Widget tile(String name,ui.FragmentShader? shader,double model,{int? version})=>Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(fontSize:13)),const SizedBox(height:4),AspectRatio(aspectRatio:1.6,child:ClipRRect(borderRadius:BorderRadius.circular(8),child:Stack(fit:StackFit.expand,children:[if(image!=null&&shader!=null&&softA!=null&&softB!=null&&environment!=null)CustomPaint(painter:PortPainter(image!,model==0?softA!:softB!,shader,model==0?fd2Params(version):Map.of(p),progress,displayedDark,model,environment!,diagnostic,version??profile,Map.of(dual))),if(model!=0||diagnostic==0)Center(child:Text('Optical Glass',style:TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:displayedDark?Colors.white:const Color(0xff172337))))])))]);
Widget control(String label, VoidCallback action, {bool selected = false}) {
  return OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: selected ? FMDSIndex.accent : FMDSIndex.ink,
      side: BorderSide(color: selected ? FMDSIndex.accent : FMDSIndex.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    onPressed: action,
    child: Text(label),
  );
}

Widget parameterGroup(String title, List<String> keys) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      border: Border.all(color: FMDSIndex.line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ExpansionTile(
      title: Text(title),
      trailing: const Text('+ / -', style: TextStyle(color: FMDSIndex.muted)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        for (final key in keys)
          Column(
            children: [
              Row(children: [
                Expanded(child: Text(key)),
                Text(fd2Params()[key]!.toStringAsFixed(3),
                    style: const TextStyle(color: FMDSIndex.accent)),
              ]),
              Slider(
                value: p[key]!,
                min: specs[key]![0],
                max: specs[key]![1],
                onChanged: (v) {
                  setState(() => p[key] = v);
                  if (key == 'blur' || key == 'roughness') scene();
                },
              ),
            ],
          ),
      ],
    ),
  );
}

void resetParameters() {
  setState(() {
    p.addAll(specs.map((k, v) => MapEntry(k, v[3])));
    dual.addAll(dualSpecs.map((k, v) => MapEntry(k, v[3])));
    dual.addAll(adaptiveSpecs.map((k, v) => MapEntry(k, v[3])));
    dual['bottomReflection'] = .75;
    target = 0;
    start();
  });
  scene();
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xff0b1119),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(children: [
                control('< INDEX', () => Navigator.of(context).maybePop()),
                const Spacer(),
                const Text('FMDS / v$fmdsVersion',
                    style: TextStyle(color: FMDSIndex.muted, fontSize: 12)),
              ]),
              const SizedBox(height: 16),
              const Divider(color: FMDSIndex.line),
              const SizedBox(height: 16),
              const Text('01 / MATERIAL ENGINE',
                  style: TextStyle(color: FMDSIndex.accent, letterSpacing: 2, fontSize: 11)),
              const SizedBox(height: 8),
              const Text('Glass', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
              const Text('ENGINE 1.0.0 / OPTICAL BASELINE 0.4.11',
                  style: TextStyle(color: FMDSIndex.muted, fontSize: 11)),
              const SizedBox(height: 24),
              const Text('01  /  LIVE SURFACE', style: TextStyle(color: FMDSIndex.accent, fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff101b26),
                  border: Border.all(color: FMDSIndex.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (error != null) Text(error!),
                  if (image == null && error == null) const LinearProgressIndicator(),
                  tile('Surface / spring morph', a, 0),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    control(target == 1 ? 'Collapse' : 'Expand', () {
                      setState(() => target = target == 1 ? 0 : 1);
                      start();
                    }, selected: target == 1),
                    control(dark ? 'Dark' : 'Light', () {setState(() => dark = !dark); scene();}, selected: dark),
                    control(app ? 'App scene' : 'Test scene', () {setState(() => app = !app); scene();}, selected: app),
                    control(moving ? 'Motion on' : 'Motion off', () {setState(() => moving = !moving); start(); scene();}, selected: moving),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Text('02  /  INSPECTOR',
                    style: TextStyle(color: FMDSIndex.accent, fontSize: 12))),
                control('Reset', resetParameters),
              ]),
              const SizedBox(height: 12),
              parameterGroup('Motion / Spring', ['mass','stiffness','damping']),
              parameterGroup('Material / Optics', ['roughness','depth','thickness','blur','refraction','transmission','ior','tint']),
              parameterGroup('Lighting / Environment', ['highlight','rimLight','shadow','envMapIntensity','angle']),
              const SizedBox(height: 16),
              const Text('FLUTTER SHADER / PLATFORM VALIDATION PENDING',
                  style: TextStyle(color: FMDSIndex.muted, fontSize: 10, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    ),
  );
}
}
class FMDSApp extends StatelessWidget {
const FMDSApp({super.key});
@override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'FMDS',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff7289ad),brightness:Brightness.dark),useMaterial3:true),home:const FMDSIndex());
}
class FMDSIndex extends StatelessWidget {
  const FMDSIndex({super.key});
  static const ink=Color(0xffe5edf5);
  static const muted=Color(0xff91a2b6);
  static const accent=Color(0xff78e4d0);
  static const line=Color(0xff293746);
  void open(BuildContext context)=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const RenderLab()));
  Widget tag(String value,{bool live=false})=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(border:Border.all(color:live?accent:line),borderRadius:BorderRadius.circular(4)),child:Text(value,style:TextStyle(fontSize:10,letterSpacing:1,color:live?accent:muted)));
  Widget section(String number,String title,String detail)=>Padding(padding:const EdgeInsets.only(top:28,bottom:12),child:Row(children:[Text(number,style:const TextStyle(color:accent,fontSize:12)),const SizedBox(width:10),Expanded(child:Text(title,style:const TextStyle(color:ink,fontSize:18,fontWeight:FontWeight.w600))),Text(detail,style:const TextStyle(color:muted,fontSize:11))]));
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xff0b1119),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1120),child:ListView(padding:const EdgeInsets.fromLTRB(20,16,20,32),children:[
    Row(children:[const Text('FMDS',style:TextStyle(color:ink,fontSize:22,fontWeight:FontWeight.w800,letterSpacing:2)),const SizedBox(width:10),tag('v$fmdsVersion'),const Spacer(),tag('FLUTTER')]),
    const SizedBox(height:8),
    const Text(fmdsBuildLabel,style:TextStyle(color:Color(0xff94a3b8),fontSize:11)),
    const SizedBox(height:18),const Divider(color:line,height:1),const SizedBox(height:24),
    const Text('MOTION / MATERIAL / SYSTEM',style:TextStyle(color:accent,fontSize:10,letterSpacing:1.7)),
    const SizedBox(height:10),
    const Text('Motion Design\nSystem',style:TextStyle(color:ink,fontSize:38,height:1.06,fontWeight:FontWeight.w700,letterSpacing:-1.5)),
    const SizedBox(height:12),
    const Text('Independent rendering engines. Shared component contracts.',style:TextStyle(color:muted,fontSize:14,height:1.5)),
    const SizedBox(height:18),
    Wrap(spacing:8,runSpacing:8,children:[tag('iOS'),tag('ANDROID'),tag('WEB'),tag('01 / 04 ENGINES')]),
    section('01','Render engines','MATERIAL LAB'),
    LayoutBuilder(builder:(context,c){final count=c.maxWidth>=720?4:2;final width=(c.maxWidth-(count-1)*10)/count;return Wrap(spacing:10,runSpacing:10,children:[for(var i=0;i<4;i++)SizedBox(width:width,child:Semantics(button:i==0,enabled:i==0,child:InkWell(onTap:i==0?()=>open(context):null,borderRadius:BorderRadius.circular(8),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xff101b26),border:Border.all(color:i==0?const Color(0xff477e7c):line),borderRadius:BorderRadius.circular(8)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      SizedBox(height:82,width:double.infinity,child:CustomPaint(painter:FMEngineGlyph(i))),
      const SizedBox(height:12),Text(['Glass','Liquid','Metal','Light'][i],style:const TextStyle(color:ink,fontSize:19,fontWeight:FontWeight.w600)),
      const SizedBox(height:7),tag(i==0?'BASELINE 1.0':'PLANNED',live:i==0),
      const SizedBox(height:8),Text(i==0?'Open lab  >':'Not implemented',style:const TextStyle(color:muted,fontSize:11))
    ])))))]);}),
    section('02','Component index','01 / 07 PREVIEWS'),
    for(final entry in const {'Surface':'Optical surface / Morph','Button':'Interaction / Press','IconButton':'Compact action','Switch':'Binary state','Slider':'Continuous value','SelectionDialog':'Overlay / Morph','Navigation':'Route transitions'}.entries)
      Padding(padding:const EdgeInsets.only(bottom:6),child:Semantics(button:entry.key=='Surface',enabled:entry.key=='Surface',child:InkWell(onTap:entry.key=='Surface'?()=>open(context):null,child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:14),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:line))),child:Row(children:[Container(width:34,height:34,decoration:BoxDecoration(border:Border.all(color:line),borderRadius:BorderRadius.circular(5)),alignment:Alignment.center,child:Text(entry.key.substring(0,1),style:const TextStyle(color:accent,fontSize:16))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(entry.key,style:const TextStyle(color:ink,fontSize:15,fontWeight:FontWeight.w600)),const SizedBox(height:4),Text(entry.value,style:const TextStyle(color:muted,fontSize:11))])),tag(entry.key=='Surface'?'PREVIEW >':'PLANNED',live:entry.key=='Surface')]))))),
    const SizedBox(height:24),const Text('FMDS / ENGINEERING PREVIEW',style:TextStyle(color:muted,fontSize:10,letterSpacing:1.5)),
    const SizedBox(height:6),const Text('Glass baseline: v0.4.11 · Platform validation pending',style:TextStyle(color:muted,fontSize:11)),
  ])))));
}
class FMEngineGlyph extends CustomPainter {
  final int kind;
  const FMEngineGlyph(this.kind);
  @override void paint(Canvas canvas,Size size){
    final p=Paint()..color=const Color(0xff243646)..strokeWidth=.6;
    for(double x=0;x<size.width;x+=12){canvas.drawLine(Offset(x,0),Offset(x,size.height),p);}
    for(double y=0;y<size.height;y+=12){canvas.drawLine(Offset(0,y),Offset(size.width,y),p);}
    final c=size.center(Offset.zero);
    final r=math.min(size.width*.30,29.0);
    final color=[const Color(0xff78e4d0),const Color(0xff679cf0),const Color(0xffaab7c8),const Color(0xffd3a4ff)][kind];
    final stroke=Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=1.3;
    if(kind==0){for(int i=2;i>=0;i--){final rect=Rect.fromCenter(center:c+Offset(i*5.0-5,i*-5.0+5),width:r*2.1,height:r*1.35);canvas.drawRRect(RRect.fromRectAndRadius(rect,const Radius.circular(8)),Paint()..color=color.withAlpha(20));canvas.drawRRect(RRect.fromRectAndRadius(rect,const Radius.circular(8)),stroke);}}
    else if(kind==1){final path=Path()..moveTo(c.dx,c.dy-r)..cubicTo(c.dx+r*1.4,c.dy-r*.3,c.dx+r,c.dy+r,c.dx,c.dy+r)..cubicTo(c.dx-r,c.dy+r,c.dx-r*1.4,c.dy-r*.3,c.dx,c.dy-r)..close();canvas.drawPath(path,stroke);}
    else if(kind==2){final path=Path()..moveTo(c.dx,c.dy-r)..lineTo(c.dx+r,c.dy-r*.4)..lineTo(c.dx+r,c.dy+r*.5)..lineTo(c.dx,c.dy+r)..lineTo(c.dx-r,c.dy+r*.5)..lineTo(c.dx-r,c.dy-r*.4)..close();canvas.drawPath(path,stroke);canvas.drawLine(c,Offset(c.dx,c.dy+r),stroke);canvas.drawLine(c,Offset(c.dx+r,c.dy-r*.4),stroke);canvas.drawLine(c,Offset(c.dx-r,c.dy-r*.4),stroke);}
    else{for(int i=1;i<=3;i++){canvas.drawCircle(c,r*i/3,stroke);}canvas.drawLine(c-Offset(r*1.3,0),c+Offset(r*1.3,0),stroke);canvas.drawLine(c-Offset(0,r*1.3),c+Offset(0,r*1.3),stroke);}
  }
  @override bool shouldRepaint(covariant FMEngineGlyph oldDelegate)=>oldDelegate.kind!=kind;
}
