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
 return mix(legacy,thin,thinShell);
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
 vec2 xy=FlutterFragCoord().xy/size*vec2(320.,200.);vec2 p=xy-vec2(160.,100.);
 float d=sd(p,bounds(),radius());vec3 bg=sampleAt(xy);
 float sh=exp(-max(0.,sd(p-vec2(0.,mix(5.,2.,thinShell)),bounds(),radius()))*mix(.24,.48,thinShell))*shadow*.65;bg*=1.-sh;
 float alpha=clamp(.5-d,0.,1.);if(alpha<=0.){fragColor=vec4(bg,1.);return;}
 vec2 g=vec2(heightAt(p+vec2(.5,0.))-heightAt(p-vec2(.5,0.)),heightAt(p+vec2(0.,.5))-heightAt(p-vec2(0.,.5)));
 vec3 n=normalize(vec3(-g,1.)),v=vec3(0.,0.,1.);
 vec3 ray=refract(-v,n,1./ior);
 // Parallel back interface: lateral travel inside the dielectric slab.
 vec3 exitRay=refract(ray,vec3(0.,0.,1.),ior);
 float travel=min(bounds().y*.8,refraction*thickness*(1.+depth)*mix(1.,1.65,thinShell));
 vec2 lateral=ray.xy/max(.35,abs(ray.z))*travel;
 vec2 outgoing=exitRay.xy/max(.45,abs(exitRay.z))*travel*.28;
 vec2 q=xy+lateral+outgoing;
 vec3 c=blurred(q);c.r=blurred(q-n.xy*dispersion*refraction*thickness).r;c.b=blurred(q+n.xy*dispersion*refraction*thickness).b;
 float neutral=mix(.933,.125,dark);vec3 base=linearize(vec3(neutral));
 c=mix(c,base,tint);c=mix(base,c,transmission);c=mix(c,base,contrast*mix(.22,.06,thinShell));
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
 float width=clamp(highlightWidth+bevelWidth*.35*(1.-thinShell),.025,.7);
 float grazing=exp(-pow((slope-mix(.78,.48,thinShell))/width,2.));
 // Limit the thin-shell reflection footprint in logical display pixels.
 float pixelScale=size.x/320.;
 grazing*=mix(1.,exp(-pow(max(0.,-d)*pixelScale/2.2,2.)),thinShell);
 float dir=clamp(dot(normalize(n.xy+vec2(.00001)),normalize(l.xy))*.5+.5,0.,1.);
 float edge=clamp(edgeHighlight*highlight*rim*grazing*pow(dir,3.)*.62,0.,.48);
 float weight=clamp(F*(mix(.35,.10,thinShell)+surfaceReflection*2.)+edge,0.,.65);
 // Allocate the directional glint from the same reflection budget.
 float glint=clamp(spec*surfaceReflection*highlight*.16,0.,.12);
 float total=clamp(weight+glint,0.,.72);
 vec3 result=c*(1.-total)+reflected*weight+vec3(glint);
 result=mix(result,max(result,c),ambientLift*mix(.12,.03,thinShell));
 // Diagnostic modes reuse the F-D2-only model uniform; no ABI change.
 vec3 outputColor=encode(result);
 if(model>0.5 && model<1.5) outputColor=n*.5+.5;
 else if(model>1.5 && model<2.5) outputColor=vec3(clamp(.5+(q-xy)/48.,0.,1.),.5);
 else if(model>2.5 && model<3.5) outputColor=encode(c);
 else if(model>3.5 && model<4.5) outputColor=encode(reflected*weight+vec3(glint));
 else if(model>4.5) outputColor=vec3(total);
 fragColor=vec4(mix(bg,outputColor,alpha),1.);
}
