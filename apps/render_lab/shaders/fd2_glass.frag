#include <flutter/runtime_effect.glsl>
uniform vec2 size;
uniform float progress;
uniform float dark;
uniform float model;
uniform float ior;
uniform float roughness;
uniform float thickness;
uniform float transmission;
uniform float env;
uniform float bevel;
uniform float depth;
uniform float tint;
uniform float angle;
uniform float exposure;
uniform float blur;
uniform float rim;
uniform float shadow;
uniform float crown;
uniform float refraction;
uniform float highlight;
uniform float bevelWidth;
uniform float fresnel;
uniform float contrast;
uniform float dispersion;
uniform float edgeHighlight;
uniform float highlightWidth;
uniform float surfaceReflection;
uniform float ambientLift;
uniform float refractionDetail;
uniform float thinShell;
uniform float topReflection;
uniform float bottomReflection;
uniform float sideReflection;
uniform float softReflection;
uniform float surfaceCurvature;
uniform float surfaceFalloff;
uniform float reflectionWidth;
uniform float reflectionFalloff;
uniform float adaptiveContrast;
uniform float darkEdgeStrength;
uniform sampler2D scene;
uniform sampler2D softScene;
uniform sampler2D environmentMap;
out vec4 fragColor;
float sd(vec2 p,vec2 b,float r){vec2 q=abs(p)-b+r;return length(max(q,0.0))+min(max(q.x,q.y),0.0)-r;}
vec2 bounds(){return vec2(124.,max(8.,33.+35.*progress));}
float radius(){return clamp(true?40.*(.72-.34*progress):bounds().y*(1.-progress)+15.2*progress,4.,bounds().y);}
float heightAt(vec2 p){
 float d=sd(p,bounds(),radius());
 float e=clamp(bevel*24.,1.2,8.);
 float u=clamp(-d/e,0.,1.);
 vec2 v=p/bounds();
 float dome=max(0.,1.-dot(v*v,v*v)*.5);
 float legacy=e*(.45+depth)*sqrt(max(0.,u*(2.-u)))+(crown*38.*dome)*smoothstep(0.,1.,u);
 float thin=e*(.24+depth*.65)*sin(u*1.5707963)+crown*18.*dome*smoothstep(0.,1.,u);
 float dual=step(2.5,thinShell)*(1.-step(3.5,thinShell));
 float face=surfaceCurvature*min(bounds().y,40.)*max(0.,1.-dot(v,v)*.5)*smoothstep(0.,1.,u);
 // v0.4.13: shallow continuous crown, with zero slope at the rim.
 float unified=step(6.5,thinShell)*(1.-step(7.5,thinShell));
 float interior=smoothstep(8.,22.,-d);
 float gentle=max(0.,1.-dot(v,v)*.5);
 return mix(legacy,thin,min(thinShell,1.))+dual*face+unified*surfaceCurvature*min(bounds().y,40.)*gentle*interior;
}
vec3 linearize(vec3 c){return pow(max(c,vec3(0.)),vec3(2.2));}
vec3 encode(vec3 c){return pow(clamp(c,0.,1.),vec3(1./2.2));}
vec3 sampleAt(vec2 p){return texture(scene,clamp(p/vec2(320.,200.),vec2(.001),vec2(.999))).rgb;}
vec3 blurred(vec2 p){vec2 uv=clamp(p/vec2(320.,200.),vec2(.001),vec2(.999));return mix(linearize(texture(softScene,uv).rgb),linearize(texture(scene,uv).rgb),refractionDetail);}
vec3 envSample(vec3 r){
 vec2 uv=clamp(r.xy*.45+.5,vec2(.02),vec2(.98));
 vec2 o=vec2(roughness*.13);
 return (linearize(texture(environmentMap,uv).rgb)*4.+linearize(texture(environmentMap,clamp(uv+vec2(o.x,0.),0.,1.)).rgb)+linearize(texture(environmentMap,clamp(uv-vec2(o.x,0.),0.,1.)).rgb)+linearize(texture(environmentMap,clamp(uv+vec2(0.,o.y),0.,1.)).rgb)+linearize(texture(environmentMap,clamp(uv-vec2(0.,o.y),0.,1.)).rgb))/8.;
}
float smith(float nv,float k){return nv/max(.001,nv*(1.-k)+k);}
void main(){
 float refined=step(1.5,thinShell);
 float dual=step(2.5,thinShell)*(1.-step(3.5,thinShell));
 float localized=step(3.5,thinShell)*(1.-step(4.5,thinShell));
 float directional=step(4.5,thinShell);
 float shell=min(thinShell,1.);
 vec2 xy=FlutterFragCoord().xy/size*vec2(320.,200.);vec2 p=xy-vec2(160.,100.);
 float d=sd(p,bounds(),radius());vec3 bg=sampleAt(xy);
 float sh=exp(-max(0.,sd(p-vec2(0.,mix(5.,2.,shell)),bounds(),radius()))*mix(.24,.48,shell))*shadow*.65;bg*=1.-sh;
 float alpha=clamp(.5-d,0.,1.);if(alpha<=0.){fragColor=vec4(bg,1.);return;}
 vec2 g=vec2(heightAt(p+vec2(.5,0.))-heightAt(p-vec2(.5,0.)),heightAt(p+vec2(0.,.5))-heightAt(p-vec2(0.,.5)));
 vec3 n=normalize(vec3(-g,1.)),v=vec3(0.,0.,1.);
 vec3 ray=refract(-v,n,1./ior);
 // Parallel back interface: lateral travel inside the dielectric slab.
 vec3 exitRay=refract(ray,vec3(0.,0.,1.),ior);
 float travel=min(bounds().y*.8,refraction*thickness*(1.+depth)*mix(1.,1.65,shell));
 vec2 lateral=ray.xy/max(.35,abs(ray.z))*travel;
 vec2 outgoing=exitRay.xy/max(.45,abs(exitRay.z))*travel*.28;
 float edgeDistance=max(0.,-d)*size.x/320.;
 float micro=exp(-pow(edgeDistance/2.0,2.));
 vec2 q=xy+lateral+outgoing+refined*n.xy*micro*refraction*.045;
 // A: interior-only lens displacement; baseline rim is untouched.
 float lens=step(7.5,thinShell)*(1.-step(8.5,thinShell));
 float faceGate=smoothstep(3.,12.,-d);
 vec2 lensUV=p/bounds();
 q-=lens*faceGate*lensUV*(1.-.35*dot(lensUV,lensUV))*surfaceCurvature*160.;
 vec3 c=blurred(q);c.r=blurred(q-n.xy*dispersion*refraction*thickness).r;c.b=blurred(q+n.xy*dispersion*refraction*thickness).b;
 float neutral=mix(.933,.125,dark);vec3 base=linearize(vec3(neutral));
 c=mix(c,base,tint);c=mix(base,c,transmission);c=mix(c,base,contrast*mix(.22,.06,shell));
 float f0=pow((ior-1.)/(ior+1.),2.);float nv=max(.001,n.z);
 float F=f0+(1.-f0)*pow(1.-nv,5.)*fresnel;
 vec3 r=reflect(-v,n);
 // Studio texture is a reflection source, not an additive ambient wash.
 vec3 studio=envSample(r);
 float localLum=dot(blurred(xy),vec3(.2126,.7152,.0722));
 float gain=mix(1.35,1.0,smoothstep(.02,.65,localLum));
 vec3 radiance=studio*env*exposure*gain*2.2;
 vec3 reflected=vec3(1.)-exp(-radiance);
 vec3 l=normalize(vec3(cos(angle)*.42,sin(angle)*.42,1.));vec3 h=normalize(v+l);
 float nl=max(0.,dot(n,l)),nh=max(0.,dot(n,h)),vh=max(0.,dot(v,h));
 float a=max(.12,roughness);float a2=a*a;float den=nh*nh*(a2-1.)+1.;
 float D=a2/(3.14159265*den*den);float k=(a+1.)*(a+1.)/8.;
 float Fs=f0+(1.-f0)*pow(1.-vh,5.);
 float spec=min(2.,D*smith(nv,k)*smith(nl,k)*Fs/max(.004,4.*nv*nl))*nl;
 // Reflection follows the same normal field as transmission; no distance-based outline.
 float slope=length(n.xy);
 float width=clamp(highlightWidth+bevelWidth*.35*(1.-shell),.025,.7);
 float grazing=exp(-pow((slope-mix(.78,.48,shell))/width,2.));
 // Limit the thin-shell reflection footprint in logical display pixels.
 float pixelScale=size.x/320.;
 grazing*=mix(1.,exp(-pow(max(0.,-d)*pixelScale/2.2,2.)),shell);
 float dir=clamp(dot(normalize(n.xy+vec2(.00001)),normalize(l.xy))*.5+.5,0.,1.);
 float edge=clamp(edgeHighlight*highlight*rim*grazing*pow(dir,3.)*.62,0.,.48);
 // Narrow optical glint: independent of shell geometry and broad reflection.
 float slopeGate=smoothstep(.035,.22,slope);
 float band=exp(-pow((edgeDistance-.55)/max(.35,highlightWidth*12.),2.));
 float adaptive=mix(1.25,.78,smoothstep(.025,.7,localLum));
 float fine=clamp(edgeHighlight*highlight*rim*band*slopeGate*pow(dir,2.)*adaptive*.48,0.,.42);
 vec2 axis=normalize(n.xy+vec2(.00001));
 float vertical=axis.y*axis.y;
 float dualDir=vertical*mix(topReflection,bottomReflection,step(0.,axis.y))+(1.-vertical)*sideReflection;
 float dualFine=clamp(edgeHighlight*highlight*rim*band*slopeGate*dualDir*adaptive*.48,0.,.42);
 edge=mix(edge,mix(fine,dualFine,dual),refined);
 // Preserve refined baseline; add only a localized lower reflection lobe.
 float lower=pow(max(0.,axis.y),4.);
 float lateralMask=exp(-pow((p.x/bounds().x+.18)/.62,2.));
 float lowerBand=exp(-pow((edgeDistance-.85)/1.05,2.));
 float localGlint=clamp(edgeHighlight*highlight*rim*bottomReflection*lower*lateralMask*lowerBand*slopeGate*adaptive*.16,0.,.12);
 edge+=localized*localGlint*(1.-edge);
 float directionalBand=exp(-pow(abs(edgeDistance-.55)/max(.35,highlightWidth*12.*reflectionWidth),reflectionFalloff));
 float bright=smoothstep(.18,.78,localLum);
 float directionalGain=mix(adaptive,1.15+bright*.65,adaptiveContrast);
 float directionalFine=clamp(edgeHighlight*highlight*rim*directionalBand*slopeGate*dualDir*directionalGain*.48,0.,.42);
 edge=mix(edge,directionalFine,directional);
 float faceMask=smoothstep(2.,6.,edgeDistance);
 float faceBand=pow(clamp(abs(p.y)/bounds().y,0.,1.),mix(3.,.8,surfaceFalloff));
 float broad=dual*softReflection*highlight*faceMask*(.15+.85*faceBand)*mix(.8,.45,smoothstep(.025,.7,localLum));
 float weight=clamp(F*(mix(.35,.10,shell)+surfaceReflection*2.)+edge+broad,0.,.65);
 // Allocate the directional glint from the same reflection budget.
 float glint=clamp(spec*surfaceReflection*highlight*.16,0.,.12);
 // B: sample the existing studio environment using a continuous virtual face normal.
 float faceReflect=step(8.5,thinShell);
 vec2 uvFace=p/bounds();
 vec3 faceNormal=normalize(vec3(uvFace*surfaceCurvature*12.,1.));
 vec3 faceStudio=envSample(reflect(-v,faceNormal));
 float faceWeight=faceReflect*faceGate*softReflection;
 float total=clamp(weight+glint,0.,.72);
 vec3 reflectionColor=mix(reflected,max(reflected,vec3(.85)),refined*band*slopeGate*.65);
 reflectionColor=mix(reflectionColor,max(reflectionColor,vec3(.65)),dual*faceMask*faceBand*.45);
 vec3 result=c*(1.-total)+reflectionColor*weight+vec3(glint);
 // Energy-bounded reflection, not an additive white stripe.
 vec3 faceRadiance=vec3(1.)-exp(-faceStudio*env*exposure*2.2);
 float extra=min(faceWeight,max(0.,.72-total));
 result=result*(1.-extra)+faceRadiance*extra;
 float darkBand=exp(-pow((edgeDistance-1.8)/max(.5,reflectionWidth*1.5),2.));
 result*=1.-directional*darkEdgeStrength*adaptiveContrast*bright*darkBand*slopeGate*(.35+.65*vertical);
 result=mix(result,max(result,c),ambientLift*mix(.12,.03,shell));
 // Diagnostic modes reuse the F-D2-only model uniform; no ABI change.
 vec3 outputColor=encode(result);
 if(model>0.5 && model<1.5) outputColor=n*.5+.5;
 else if(model>1.5 && model<2.5) outputColor=vec3(clamp(.5+(q-xy)/48.,0.,1.),.5);
 else if(model>2.5 && model<3.5) outputColor=encode(c);
 else if(model>3.5 && model<4.5) outputColor=encode((reflectionColor*weight+vec3(glint))*(1.-extra)+faceRadiance*extra);
 else if(model>4.5) outputColor=vec3(total*(1.-extra)+extra);
 fragColor=vec4(mix(bg,outputColor,alpha),1.);
}
