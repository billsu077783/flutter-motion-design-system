#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform float uRefraction;
uniform float uBlur;
uniform float uCompare;
uniform float uThickness;
uniform float uHighlight;
uniform float uTint;
uniform float uDispersion;
uniform float uReference;
uniform float uBevel;
uniform float uCurvature;
uniform float uIOR;
uniform float uFresnel;
uniform float uRoughness;
uniform float uReflection;
uniform float uAngle;
uniform float uShadow;
uniform sampler2D uScene;
uniform sampler2D uBlurred;
out vec4 fragColor;
float sdf(vec2 p, vec2 b, float r) {
  vec2 q=abs(p)-b+r;
  return length(max(q,vec2(0)))+min(max(q.x,q.y),0.0)-r;
}
float heightAt(vec2 p,vec2 b,float r,float bevel,float h) {
  float x=clamp(-sdf(p,b,r)/bevel,0.0,1.0);
  return h*(1.0-pow(1.0-x,3.0));
}
vec3 transmission(vec2 uv) {
  if(uBlur<0.001) return texture(uScene,clamp(uv,vec2(0),vec2(1))).rgb;
  return texture(uBlurred,clamp(uv,vec2(0),vec2(1))).rgb;
}
vec3 studio(vec3 ray, float rough, vec2 light) {
  float a=dot(ray.xy,light);
  float side=dot(ray.xy,vec2(-light.y,light.x));
  float width=0.10+rough*0.48;
  float strip=exp(-pow((a-0.63)/width,2.0))*exp(-pow(side/0.85,4.0));
  float fill=exp(-pow((a+0.58)/(0.25+rough*0.45),2.0));
  return vec3(0.24,0.28,0.34)+vec3(0.92,0.95,1.0)*strip+vec3(0.42,0.45,0.49)*fill;
}
vec3 systemGlass(vec2 local,vec2 b,float r,float d,vec2 uv) {
  float w=clamp(uBevel,1.0,b.y*0.95);
  float x=clamp(-d/w,0.0,1.0);
  vec2 g=vec2(sdf(local+vec2(0.5,0),b,r)-sdf(local-vec2(0.5,0),b,r),
    sdf(local+vec2(0,0.5),b,r)-sdf(local-vec2(0,0.5),b,r));
  // Rounded bevel: bounded slope, continuous at the inner boundary.
  float slope=(1.0-x)*sqrt(max(0.0,1.0-x*x))*uCurvature*uThickness*3.0;
  vec3 n=normalize(vec3(g*slope,1.0));
  vec3 ray=refract(vec3(0,0,-1),n,1.0/max(1.0,uIOR));
  vec2 shift=ray.xy/max(0.6,-ray.z)*uRefraction*uThickness/uSize;
  // Bound displacement relative to bevel width to reduce texture foldover.
  float pixels=length(shift*uSize);
  shift*=min(1.0,w*0.65/max(pixels,0.001));
  vec2 chroma=shift*uDispersion*0.15;
  vec3 t=vec3(transmission(uv+shift+chroma).r,transmission(uv+shift).g,transmission(uv+shift-chroma).b);
  vec2 light=vec2(cos(uAngle),sin(uAngle));
  vec3 reflected=reflect(vec3(0,0,-1),n);
  float f0=pow((uIOR-1.0)/(uIOR+1.0),2.0);
  float fresnel=f0+(1.0-f0)*pow(1.0-n.z,5.0);
  vec3 env=studio(reflected,uRoughness,light);
  // Linear-light approximate energy-weighted composition.
  vec3 lin=pow(max(t,vec3(0)),vec3(2.2));
  lin=mix(lin,pow(vec3(0.95,0.97,1.0),vec3(2.2)),uTint);
  float weight=clamp(fresnel*uFresnel*uReflection*uHighlight,0.0,0.75);
  lin=mix(lin,env,weight);
  float facing=dot(g,light);
  float lobe=exp(-pow((x-0.22)/(0.12+uRoughness*0.25),2.0));
  lin+=vec3(0.24)*lobe*pow(max(0.0,facing),2.0)*uHighlight*uReflection;
  lin*=1.0-0.10*lobe*max(0.0,-facing)*uHighlight;
  return pow(clamp(lin,0.0,1.0),vec3(1.0/2.2));
}
void main() {
  vec2 p=FlutterFragCoord().xy;
  vec2 b=uSize*vec2(0.39,0.18);
  float r=min(b.y,30.0);
  vec2 local=p-uSize*0.5;
  float d=sdf(local,b,r);
  vec2 uv=p/uSize;
  vec4 base=texture(uScene,uv);
  float mask=1.0-smoothstep(-0.65,0.65,d);
  float optical=1.0-uCompare;
  float shadow=exp(-pow(max(0.0,sdf(local-vec2(0,3),b,r))/5.0,2.0))*0.065*optical;
  if(uReference>1.5) shadow=exp(-pow(max(0.0,sdf(local-vec2(0,2),b,r))/3.0,2.0))*uShadow*0.25*optical;
  base.rgb*=1.0-shadow;
  if(mask<=0.0){fragColor=base;return;}
  float bevel=min(b.y*0.48,5.0+uThickness*7.0);
  float h=bevel*0.55*uThickness;
  float dx=heightAt(local+vec2(0.4,0),b,r,bevel,h)-heightAt(local-vec2(0.4,0),b,r,bevel,h);
  float dy=heightAt(local+vec2(0,0.4),b,r,bevel,h)-heightAt(local-vec2(0,0.4),b,r,bevel,h);
  vec3 n=normalize(vec3(-dx/0.8,-dy/0.8,1.0));
  vec3 ray=refract(vec3(0,0,-1),n,1.0/1.46);
  vec2 shift=ray.xy/max(0.5,-ray.z)*uRefraction*uThickness*optical/uSize;
  vec2 center=uv+shift;
  vec2 chroma=shift*uDispersion*0.15;
  vec3 col=vec3(transmission(center+chroma).r,transmission(center).g,transmission(center-chroma).b);
  vec3 reflected=reflect(vec3(0,0,-1),n);
  // Analytic studio environment: broad ceiling and narrow strip light.
  float ceiling=smoothstep(0.15,0.95,-reflected.y);
  float strip=exp(-pow((reflected.y+0.72)/0.12,2.0))*smoothstep(-0.9,-0.1,reflected.x);
  vec3 env=mix(vec3(0.16,0.21,0.30),vec3(0.95,0.98,1.0),ceiling)+strip*0.65;
  float fresnel=0.035+0.965*pow(1.0-n.z,5.0);
  col=mix(col,vec3(0.94,0.96,1.0),uTint*optical);
  col=mix(col,env,clamp(fresnel*uHighlight*optical,0.0,0.65));
  float upper=max(0.0,dot(n.xy,vec2(-0.35,-0.94)));
  float lower=max(0.0,n.y);
  float outer=exp(-pow((d+0.8)/0.65,2.0));
  float inner=exp(-pow((d+bevel*0.72)/1.0,2.0));
  col+=optical*uHighlight*(outer*(0.12+upper*0.65)+inner*lower*0.16);
  col*=1.0-optical*inner*upper*0.09;
  if(uReference>0.5 && uReference<1.5 && optical>0.5) {
    vec2 grad=vec2(sdf(local+vec2(0.5,0),b,r)-sdf(local-vec2(0.5,0),b,r),
      sdf(local+vec2(0,0.5),b,r)-sdf(local-vec2(0,0.5),b,r));
    float edge=clamp(1.0+d/max(1.0,12.0*uThickness),0.0,1.0);
    vec2 offset=-grad*edge*edge*uRefraction*0.55/uSize;
    vec2 uv2=uv+offset;
    vec2 rgbShift=offset*uDispersion*0.15;
    col=vec3(transmission(uv2+rgbShift).r,transmission(uv2).g,transmission(uv2-rgbShift).b);
    float directional=dot(grad,vec2(-0.45,-0.89));
    float shine=pow(max(0.0,directional),3.0)*pow(edge,3.0);
    float shade=pow(max(0.0,-directional),2.0)*edge;
    col=mix(col,vec3(0.96,0.98,1.0),uTint);
    col+=uHighlight*(shine*0.28+outer*0.16);
    col*=1.0-0.12*shade*uHighlight;
  }
  if(uReference>1.5 && optical>0.5) col=systemGlass(local,b,r,d,uv);
  fragColor=mix(base,vec4(clamp(col,0.0,1.0),1.0),mask);
}
