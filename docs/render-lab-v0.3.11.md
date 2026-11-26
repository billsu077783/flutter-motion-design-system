# Render Lab v0.3.11

Base: v0.3.10. Code commit: 09d1bf11361b7fdf52abd23d3d8d3464a05ac907.

- D2: directional multilayer inset rim, adjusted mask radius to match nominal geometry radius. Physical transmission unchanged. Exact silhouette matching remains unverified.
- D4: increased bounded refraction, directional highlight and Fresnel contribution, luminance-aware shading.
- Canvas 1/2, D1, D3 algorithms unchanged; shared controls and defaults retained. Canvas baselines remain reconstructions.
- Browser WebGL/Canvas reference only; not Flutter rendering. No browser runtime, visual, performance or device acceptance performed in this iteration.
- Verify pill/panel, light/dark, stripes/app, dynamic background and spring reversals; compare D2/D4 with fixed baselines. M0 remains open.
