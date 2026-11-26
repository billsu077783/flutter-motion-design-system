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
uniform sampler2D scene;
uniform sampler2D softScene;
out vec4 fragColor;
float sd(vec2 p,vec2 b,float r){vec2 q=abs(p)-b+r;return length(max(q,0.0))+min(max(q.x,q.y),0.0)-r;}
vec2 bounds(){return vec2(124.,max(8.,33.+35.*progress));}
float radius(){return clamp(false?40.*(.72-.34*progress):bounds().y*(1.-progress)+15.2*progress,4.,bounds().y);}
float heightAt(vec2 p){float d=sd(p,bounds(),radius());float e=false?max(3.,bevel*40.):max(3.,min(bounds().y*.9,bounds().y*2.*bevelWidth));float u=clamp(-d/e,0.,1.);return e*.58*sin(u*1.5707963)+(false?crown*40.*max(0.,1.-dot(p/bounds(),p/bounds()))+depth*10.*smoothstep(0.,1.,u):0.);}
vec3 sampleAt(vec2 p){return texture(scene,clamp(p/vec2(320.,200.),vec2(.001),vec2(.999))).rgb;}
vec3 blurred(vec2 p,float b){return texture(softScene,clamp(p/vec2(320.,200.),vec2(.001),vec2(.999))).rgb;}
void main(){vec2 xy=FlutterFragCoord().xy/size*vec2(320.,200.);vec2 p=xy-vec2(160.,100.);float d=sd(p,bounds(),radius());vec3 bg=sampleAt(xy);float sh=exp(-max(0.,sd(p-vec2(0.,5.),bounds(),radius()))*.24)*shadow*.65;bg*=1.-sh;float alpha=clamp(.5-d,0.,1.);if(alpha<=0.){fragColor=vec4(bg,1.);return;}
vec2 g=vec2(heightAt(p+vec2(.5,0))-heightAt(p-vec2(.5,0)),heightAt(p+vec2(0,.5))-heightAt(p-vec2(0,.5)));vec3 n=normalize(vec3(-g,1.));float eta=1./ior;float bend=sqrt(max(0.,1.-eta*eta*(1.-n.z*n.z)))-eta*n.z;float e=max(3.,bounds().y*2.*bevelWidth);float shift=min(e*.85,refraction*thickness*bend*1.5);vec2 q=xy-n.xy*shift;float b=blur+(false?roughness*18.:0.);vec3 c=blurred(q,b);c.r=blurred(q-n.xy*dispersion*shift,b).r;c.b=blurred(q+n.xy*dispersion*shift,b).b;float f0=pow((ior-1.)/(ior+1.),2.);float F=f0+(1.-f0)*pow(1.-n.z,5.);float dir=clamp((dot(normalize(p+vec2(.00001)),vec2(cos(angle),sin(angle)))+1.)*.5,0.,1.);float band=exp(-pow((clamp(-d/e,0.,1.)-.10)/.17,2.));float neutral=mix(.933,.125,dark);c=mix(c,vec3(neutral),tint);c=mix(vec3(neutral),c,transmission);c=mix(c,vec3(neutral),contrast*.22);float shine=highlight*rim*(band*(.025+.38*pow(dir,3.))+mix(.10,.24,dark)*n.x*n.x)+fresnel*F*.55;if(false){shine+=F*env*exposure*.35+band*rim*.12; }float lum=dot(c,vec3(.2126,.7152,.0722));c*=1.-.19*pow(1.-dir,2.)*band*highlight*(.55+.45*lum);c=mix(c,vec3(1.),clamp(shine,0.,.85));fragColor=vec4(mix(bg,c,alpha),1.);}
