# Render Lab v0.2.0

Status: source committed; CI and browser verification pending.
Base: v0.1.0 Web smoke test.

Implemented: explicit static PictureRecorder scene texture, rounded-box SDF, finite-difference normals, approximate refraction, 25-tap box blur, edge lighting, separate foreground text, refraction and blur controls, comparison mode.

Limitations: not arbitrary Flutter backdrop sampling; no dynamic background, physical Fresnel, dispersion, spring, morph, theme or state color yet. Comparison retains tint. Blur control is sample spacing, not Gaussian sigma. Controls are experimental pointer controls, not production accessible components. Shader orientation and GPU behavior require platform tests. Smoke test checks version text only. CI temporarily formats sources in runner instead of rejecting formatting drift; restore strict gate after formatting source. No M0 gate passed. Historical preview hosting and architecture v1.1 archive pending.
