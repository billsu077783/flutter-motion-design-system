#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform float uRefraction;
uniform float uBlur;
uniform float uCompare;
uniform float uThickness;
uniform float uHighlight;
uniform float uTint;
uniform float uDispersion;
uniform sampler2D uScene;
uniform sampler2D uBlurred;
out vec4 fragColor;

float sdf(vec2 p, vec2 b, float r) {
  vec2 q = abs(p)-b+r;
  return length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-r;
}
vec4 sampleScene(vec2 uv) {
  return texture(uScene,clamp(uv,vec2(0.0),vec2(1.0)));
}
void main() {
  vec2 p=FlutterFragCoord().xy;
  vec2 b=uSize*vec2(0.39,0.18);
  float r=min(b.y,30.0);
  vec2 local=p-uSize*0.5;
  float d=sdf(local,b,r);
  vec2 uv=p/uSize;
  vec4 base=sampleScene(uv);
  float mask=1.0-smoothstep(-0.8,0.8,d);
  float shadow=exp(-pow(max(0.0,sdf(local-vec2(0,5),b,r))/7.0,2.0))*0.10*(1.0-uCompare);
  base.rgb*=1.0-shadow;
  if(mask<=0.0) { fragColor=base; return; }
  float bevel=min(b.y*0.85,8.0+uThickness*24.0);
  float t=clamp(1.0+d/bevel,0.0,1.0);
  float slope=0.82*smoothstep(0.0,1.0,t);
  vec2 grad=vec2(sdf(local+vec2(0.5,0),b,r)-sdf(local-vec2(0.5,0),b,r),
                 sdf(local+vec2(0,0.5),b,r)-sdf(local-vec2(0,0.5),b,r));
  vec3 normal=normalize(vec3(grad*slope,sqrt(max(0.01,1.0-slope*slope))));
  float optical=1.0-uCompare;
  vec3 ray=refract(vec3(0,0,-1),normal,1.0/1.45);
  vec2 shift=ray.xy*uRefraction*uThickness*optical/uSize;
  vec2 center=uv+shift;
  vec2 chroma=shift*uDispersion*0.15;
  if(uBlur<0.001) { chroma=shift*uDispersion*0.15; }
  vec3 col=vec3(texture(uBlurred,clamp(center+chroma,vec2(0),vec2(1))).r,
    texture(uBlurred,clamp(center,vec2(0),vec2(1))).g,
    texture(uBlurred,clamp(center-chroma,vec2(0),vec2(1))).b);
  
  float fresnel=0.034+0.966*pow(1.0-normal.z,5.0);
  float spec=pow(max(0.0,dot(normal,normalize(vec3(-0.35,-0.65,0.68)))),18.0);
  col=mix(col,vec3(0.94,0.96,1.0),uTint*optical);
  float rim=exp(-pow((d+1.0)/1.1,2.0));
  float direction=0.06+0.94*pow(max(0.0,dot(normal.xy,vec2(-0.45,-0.89))),2.0);
  col+=optical*uHighlight*(fresnel*0.18+spec*0.18+rim*direction*0.48);
  col*=1.0-optical*0.08*t*max(0.0,normal.y);
  fragColor=mix(base,vec4(clamp(col,0.0,1.0),1.0),mask);
}
