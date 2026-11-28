# Glass optics baseline decision

Status: selected for subsequent engineering; not production acceptance.

Baseline: F-D2 v0.4.11, adaptive profile 5. Historical reference commit `6e2415c779acbba8a12a4635d3f5c1c57c26d95c`, shader blob `c60d6ecdf9e093b6fdc52637baab470f4a1b0fa6`.

Decision: stop the current optical exploration after v0.4.18 A/B/C. User-provided light and dark Web screenshots show discontinuous refraction, distorted background objects and, in C, internal reflection bands. Retain experimental history; do not promote these variants.

Next: extract the selected shader and matching parameter defaults into the Glass engine through the standard engine interface. Preserve blur, rim lighting, refraction, spring controls and morph behavior. Generalize geometry and scene sampling without visual regression. Keep iOS, Android and Web as target platforms. Preserve engine isolation and internal fallback.

Acceptance remains pending: historical baseline reproduction, actual component integration, dynamic interaction, platform/device performance and M0 gates. This decision does not mark M0 complete or change runtime code.
