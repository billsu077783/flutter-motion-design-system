# Render Lab v0.3.2

Base v0.3.1: user screenshot confirms Web deployment. Residual sharp/blur ghosting, strong rim and shadow; visual gate not passed.

Changes: regenerate Gaussian-filtered scene at selected sigma (texture pixels), remove sharp/blur blend, smoother slope approximation, directional rim, weaker shadow, pure blur comparison, two-decimal parameter display. Six controls retained. Async generation guard discards stale results; rapid slider changes can still cause excessive image generation and require profiling/coalescing. Static explicit scene; not a full height-field or environment reflection model. CI and browser verification pending. M0 acceptance 0/6.
