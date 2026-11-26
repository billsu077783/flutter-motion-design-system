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
  if(mask<=0.0) { fragColor=base; return; }
  float bevel=min(b.y*0.85,8.0+uThickness*24.0);
  float t=clamp(1.0+d/bevel,0.0,1.0);
  float slope=sin(t*1.5707963)*0.94;
  vec2 grad=vec2(sdf(local+vec2(0.5,0),b,r)-sdf(local-vec2(0.5,0),b,r),
                 sdf(local+vec2(0,0.5),b,r)-sdf(local-vec2(0,0.5),b,r));
  vec3 normal=normalize(vec3(grad*slope,sqrt(max(0.01,1.0-slope*slope))));
  float optical=1.0-uCompare;
  vec3 ray=refract(vec3(0,0,-1),normal,1.0/1.45);
  vec2 shift=ray.xy*uRefraction*uThickness*optical/uSize;
  vec2 center=uv+shift;
  vec3 col=vec3(0);
  float total=0.0;
  for(int y=-2;y<=2;y++) {
    for(int x=-2;x<=2;x++) {
      vec2 delta=vec2(float(x),float(y));
      float weight=exp(-dot(delta,delta)*0.5);
      vec2 q=center+delta*uBlur/uSize;
      vec2 chroma=shift*uDispersion*0.15;
      col+=vec3(sampleScene(q+chroma).r,sampleScene(q).g,sampleScene(q-chroma).b)*weight;
      total+=weight;
    }
  }
  col/=total;
  float fresnel=0.034+0.966*pow(1.0-normal.z,5.0);
  float spec=pow(max(0.0,dot(normal,normalize(vec3(-0.35,-0.65,0.68)))),18.0);
  col=mix(col,vec3(0.94,0.96,1.0),uTint);
  col+=optical*uHighlight*(fresnel*0.45+spec*0.24+pow(t,16.0)*0.12);
  fragColor=mix(base,vec4(clamp(col,0.0,1.0),1.0),mask);
}
