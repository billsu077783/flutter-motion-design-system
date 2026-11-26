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
uniform sampler2D scene;
uniform sampler2D softScene;
uniform sampler2D environmentMap;
out vec4 fragColor;
float sd(vec2 p,vec2 b,float r){vec2 q=abs(p)-b+r;return length(max(q,0.0))+min(max(q.x,q.y),0.0)-r;}
vec2 bounds(){return vec2(124.,max(8.,33.+35.*progress));}
float radius(){return clamp(true?40.*(.72-.34*progress):bounds().y*(1.-progress)+15.2*progress,4.,bounds().y);}
float heightAt(vec2 p){
 float d=sd(p,bounds(),radius());
 float e=max(3.,bevel*40.);
 float u=clamp(-d/e,0.,1.);
 vec2 v=p/bounds();
 float dome=max(0.,1.-dot(v*v,v*v)*.5);
 return e*.72*sin(u*1.5707963)+(crown*85.*dome+depth*10.)*smoothstep(0.,1.,u);
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
 float sh=exp(-max(0.,sd(p-vec2(0.,5.),bounds(),radius()))*.24)*shadow*.65;bg*=1.-sh;
 float alpha=clamp(.5-d,0.,1.);if(alpha<=0.){fragColor=vec4(bg,1.);return;}
 vec2 g=vec2(heightAt(p+vec2(.5,0.))-heightAt(p-vec2(.5,0.)),heightAt(p+vec2(0.,.5))-heightAt(p-vec2(0.,.5)));
 vec3 n=normalize(vec3(-g,1.)),v=vec3(0.,0.,1.);
 vec3 ray=refract(-v,n,1./ior);
 // Parallel back interface: lateral travel inside the dielectric slab.
 vec3 exitRay=refract(ray,vec3(0.,0.,1.),ior);
 float travel=min(bounds().y*.8,refraction*thickness*(1.+depth));
 vec2 lateral=ray.xy/max(.35,abs(ray.z))*travel;
 vec2 outgoing=exitRay.xy/max(.45,abs(exitRay.z))*travel*.28;
 vec2 q=xy+lateral+outgoing;
 vec3 c=blurred(q);c.r=blurred(q-n.xy*dispersion*refraction*thickness).r;c.b=blurred(q+n.xy*dispersion*refraction*thickness).b;
 float neutral=mix(.933,.125,dark);vec3 base=linearize(vec3(neutral));
 c=mix(c,base,tint);c=mix(base,c,transmission);c=mix(c,base,contrast*.22);
 float f0=pow((ior-1.)/(ior+1.),2.);float nv=max(.001,n.z);
 float F=f0+(1.-f0)*pow(1.-nv,5.)*fresnel;
 vec3 r=reflect(-v,n);
 // Studio texture is a reflection source, not an additive ambient wash.
 vec3 studio=envSample(r);
 float localLum=dot(blurred(xy),vec3(.2126,.7152,.0722));
 float gain=mix(.32,.85,smoothstep(.02,.65,localLum));
 vec3 reflected=clamp(studio*env*exposure*gain,0.,1.);
 vec3 l=normalize(vec3(cos(angle)*.42,sin(angle)*.42,1.));vec3 h=normalize(v+l);
 float nl=max(0.,dot(n,l)),nh=max(0.,dot(n,h)),vh=max(0.,dot(v,h));
 float a=max(.12,roughness);float a2=a*a;float den=nh*nh*(a2-1.)+1.;
 float D=a2/(3.14159265*den*den);float k=(a+1.)*(a+1.)/8.;
 float Fs=f0+(1.-f0)*pow(1.-vh,5.);
 float spec=min(2.,D*smith(nv,k)*smith(nl,k)*Fs/max(.004,4.*nv*nl))*nl;
 float e=max(3.,bounds().y*2.*bevelWidth);
 float band=exp(-pow((clamp(-d/e,0.,1.)-.10)/max(.02,highlightWidth),2.));
 float dir=clamp(dot(normalize(n.xy+vec2(.00001)),l.xy)*.5+.5,0.,1.);
 float edge=clamp(edgeHighlight*highlight*rim*band*pow(dir,3.)*.12,0.,.22);
 float weight=clamp(F*(.35+surfaceReflection*2.)+edge,0.,.65);
 // Allocate the directional glint from the same reflection budget.
 float glint=clamp(spec*surfaceReflection*highlight*.12,0.,.12);
 float total=clamp(weight+glint,0.,.72);
 vec3 result=c*(1.-total)+reflected*weight+vec3(glint);
 result=mix(result,max(result,c),ambientLift*.12);
 fragColor=vec4(mix(bg,encode(result),alpha),1.);
}
