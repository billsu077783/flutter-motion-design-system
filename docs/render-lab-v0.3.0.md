# Render Lab v0.3.0

Base v0.2.0: user confirmed iOS in-app browser display and refraction/blur adjustments via screenshot. This is partial Web evidence, not full M0 acceptance.

v0.3.0: source committed; build and visual verification pending. Adds approximate 3D normals, GLSL refract, weighted 25-position blur with RGB-separated sampling (75 texture reads inside mask), Schlick-style Fresnel, directional highlight, thickness, tint intensity, dispersion and reset. Retains comparison and independent foreground.

Defaults: refraction 24, blur sample spacing 7, thickness .8, highlight .8, tint .25, dispersion .05. Fixed pale tint, not configurable hue. Static explicit scene only; comparison retains tint; foreground contrast not adaptive. Optical model is approximate; performance, artifacts and cross-platform behavior unverified. Spring/morph and theme/state colors remain planned. Architecture v1.1, historical deployment and strict format gate remain pending. M0 acceptance 0/6.
