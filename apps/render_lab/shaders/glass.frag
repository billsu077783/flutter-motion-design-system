#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform float uRefraction;
uniform float uBlur;
uniform float uCompare;
uniform sampler2D uScene;
out vec4 fragColor;

float sdf(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, vec2(0.0))) + min(max(q.x,q.y),0.0)-r;
}
void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  vec2 b = halfSize * vec2(0.78,0.36);
  float r = min(b.y,30.0);
  vec2 local = p-halfSize;
  float d = sdf(local,b,r);
  vec2 uv = p/uSize;
  vec4 base = texture(uScene,uv);
  vec2 n = vec2(sdf(local+vec2(1,0),b,r)-sdf(local-vec2(1,0),b,r),
                sdf(local+vec2(0,1),b,r)-sdf(local-vec2(0,1),b,r))*0.5;
  float edge = clamp(1.0+d/24.0,0.0,1.0);
  vec2 sampleUV = uv-n*edge*uRefraction*(1.0-uCompare)/uSize;
  vec4 col = vec4(0);
  for(int y=-2;y<=2;y++) {
    for(int x=-2;x<=2;x++) {
      col += texture(uScene,clamp(sampleUV+vec2(float(x),float(y))*uBlur/uSize,vec2(0),vec2(1)));
    }
  }
  col /= 25.0;
  float light = pow(edge,4.0)*max(0.0,dot(n,vec2(-0.45,-0.89)));
  col.rgb = mix(col.rgb,vec3(0.92,0.96,1.0),0.13);
  col.rgb += (light*0.30+pow(edge,12.0)*0.15)*(1.0-uCompare);
  fragColor = mix(base,vec4(clamp(col.rgb,0.0,1.0),1.0),1.0-smoothstep(-0.8,0.8,d));
}
