import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
void main()=>runApp(const FMDSApp());
const specs=<String,List<double>>{
'ior':[1,2,.01,1.46],'roughness':[0,.65,.01,.08],'thickness':[0,1.5,.01,.42],'transmission':[0,1,.01,1],'envMapIntensity':[0,4,.05,1.5],'bevel':[.02,.32,.01,.16],'depth':[.05,.5,.01,.20],'tint':[0,.8,.01,0],'angle':[0,360,1,315],'exposure':[.5,2,.05,1.15],'blur':[0,18,.5,5],'rimLight':[0,1,.05,.65],'shadow':[0,.6,.02,.22],'crown':[0,.15,.005,.06],'refraction':[0,48,1,24],'highlight':[0,1.5,.05,.85],'mass':[.5,3,.1,1],'stiffness':[60,380,1,180],'damping':[4,70,1,12],'bevelWidth':[.05,.45,.01,.18],'fresnel':[0,1,.05,.65],'contrast':[0,1,.05,.22],'dispersion':[0,.3,.01,.05],'edgeHighlight':[0,2,.05,1.35],'highlightWidth':[.02,.5,.01,.18],'surfaceReflection':[0,.6,.01,.18],'ambientLift':[0,.4,.01,.10],'refractionDetail':[0,1,.05,.25]};
const dualSpecs=<String,List<double>>{'topReflection':[0,1.5,.05,.85],'bottomReflection':[0,1.5,.05,.55],'sideReflection':[0,1.5,.05,.20],'softReflection':[0,.4,.01,.12],'surfaceCurvature':[0,.08,.005,.025],'surfaceFalloff':[0,1,.05,.65]};
const adaptiveSpecs=<String,List<double>>{'reflectionWidth':[.5,3,.1,1.2],'reflectionFalloff':[1,4,.1,2],'adaptiveContrast':[0,1,.05,.65],'darkEdgeStrength':[0,.4,.01,.12]};
const thinDefaults=<String,double>{'thickness':.18,'bevel':.07,'depth':.08,'crown':.015,'highlightWidth':.06,'surfaceReflection':.08,'ambientLift':.02,'shadow':.08,'contrast':.08};
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
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Glass · v1.0.0')),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760),child:ListView(padding:const EdgeInsets.all(20),children:[
const Text('Surface & spring morph',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
const Text('Optical baseline v0.4.11'),
const SizedBox(height:16),
if(error!=null)Text(error!),
if(image==null&&error==null)const Center(child:CircularProgressIndicator()),
tile('Glass surface',a,0),
Wrap(spacing:8,children:[
TextButton(onPressed:(){target=target==1?0:1;start();},child:const Text('Morph')),
TextButton(onPressed:(){setState(()=>dark=!dark);scene();},child:const Text('Theme')),
TextButton(onPressed:(){setState(()=>app=!app);scene();},child:const Text('Scene')),
TextButton(onPressed:(){setState(()=>moving=!moving);start();scene();},child:const Text('Dynamic')),
TextButton(onPressed:(){setState((){p.addAll(specs.map((k,v)=>MapEntry(k,v[3])));dual.addAll(dualSpecs.map((k,v)=>MapEntry(k,v[3])));dual.addAll(adaptiveSpecs.map((k,v)=>MapEntry(k,v[3])));dual['bottomReflection']=.75;});scene();},child:const Text('Reset'))]),
for(final group in const {'Motion':['mass','stiffness','damping'],'Material':['roughness','depth','thickness','blur','refraction','transmission','ior','tint'],'Lighting':['highlight','rimLight','shadow','envMapIntensity','angle']}.entries)
ExpansionTile(title:Text(group.key),children:[for(final key in group.value)Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$key: ${fd2Params()[key]!.toStringAsFixed(3)}'),Slider(value:p[key]!,min:specs[key]![0],max:specs[key]![1],onChanged:(v){setState(()=>p[key]=v);if(key=='blur'||key=='roughness')scene();})])]),
])))));}
class FMDSApp extends StatelessWidget {
const FMDSApp({super.key});
@override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'FMDS',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff7289ad),brightness:Brightness.dark),useMaterial3:true),home:const FMDSIndex());
}
class FMDSIndex extends StatelessWidget {
const FMDSIndex({super.key});
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('FMDS  /  v0.1.0')),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:960),child:ListView(padding:const EdgeInsets.all(24),children:[
const Text('Motion Design System',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),
const Text('Component library · Flutter'),
const SizedBox(height:28),
const Text('RENDER ENGINES'),
const SizedBox(height:12),
Wrap(spacing:12,runSpacing:12,children:[for(final name in ['Glass','Liquid','Metal','Light']) SizedBox(width:145,child:Card(child:ListTile(title:Text(name),subtitle:Text(name=='Glass'?'v1.0.0 baseline':'Planned'),leading:const Icon(Icons.layers_outlined),onTap:name=='Glass'?()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const RenderLab())):null)))]),
const SizedBox(height:28),
const Text('COMPONENTS'),
const SizedBox(height:12),
for(final entry in const {'Surface':'Optical material preview','Button':'Planned','IconButton':'Planned','Switch':'Planned','Slider':'Planned','SelectionDialog':'Planned','Navigation':'Planned'}.entries)
Card(child:ListTile(title:Text(entry.key),subtitle:Text(entry.value),trailing:Icon(entry.key=='Surface'?Icons.chevron_right:Icons.lock_outline),onTap:entry.key=='Surface'?()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const RenderLab())):null)),
])))));}
class PortPainter extends CustomPainter{PortPainter(this.image,this.soft,this.shader,this.p,this.progress,this.dark,this.model,this.environment,this.diagnostic,this.profile,this.dual);final Map<String,double> dual;final int profile;final int diagnostic;final ui.Image image,soft,environment;final ui.FragmentShader shader;final Map<String,double> p;final double progress,model;final bool dark;@override void paint(Canvas c,Size s){final values=[s.width,s.height,progress,dark?1.0:0.0,model==0?diagnostic.toDouble():model,for(final k in ['ior','roughness','thickness','transmission','envMapIntensity','bevel','depth','tint','angle','exposure','blur','rimLight','shadow','crown','refraction','highlight','bevelWidth','fresnel','contrast','dispersion','edgeHighlight','highlightWidth','surfaceReflection','ambientLift','refractionDetail']) k=='angle'?p[k]!*math.pi/180:p[k]!];for(int i=0;i<values.length;i++){shader.setFloat(i,values[i]);}if(model==0){shader.setFloat(values.length,profile.toDouble());int j=values.length+1;for(final key in [...dualSpecs.keys,...adaptiveSpecs.keys]){shader.setFloat(j++,dual[key]!);}}shader.setImageSampler(0,image);shader.setImageSampler(1,soft);if(model==0)shader.setImageSampler(2,environment);c.drawRect(Offset.zero&s,Paint()..shader=shader);}@override bool shouldRepaint(covariant PortPainter oldDelegate)=>true;}
