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
  if(uReference>0.5 && optical>0.5) {
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
  fragColor=mix(base,vec4(clamp(col,0.0,1.0),1.0),mask);
}
