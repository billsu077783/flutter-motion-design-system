# Render Lab v0.3.1

Base v0.3.0: user confirmed deployment but rejected visual quality relative to Canvas prototype. Visible ghosting and weak depth. Do not advance morph acceptance yet.

Changes: Flutter ImageFilter Gaussian prefilter of explicit static scene, second texture sampler, sharp/blurred blend, directional narrow rim, approximate shadow and lower tint (.12). All six controls retained; blur now controls blend, not sigma. Fixed sigma 12 texture pixels. Sharp/blur blend can still produce residual ghosting; dispersion attenuates at low blur. No dynamic backdrop or native verification. Source committed, CI/browser verification pending. M0 0/6. Historical deployment and architecture archive pending.
