# FMDS development workflow (v0.1.4)

## Before every submission

- Work on a feature/fix branch; inspect the diff against main and keep changes scoped.
- Check syntax, imports, unused declarations, SDK/API compatibility, dependency changes, asset paths, shader uniform ABI and lifecycle changes.
- Use Flutter 3.38.5. Where the SDK is available, run from apps/render_lab:
  `flutter pub get`, `dart format lib test`, `flutter analyze`, `flutter test`, and `flutter build web --release`.
- If the SDK is unavailable, explicitly report that local executable checks were not run; rely on PR CI and never claim a local pass.
- Review workflow YAML, shell commands and deployment paths when changing infrastructure.
- Preserve the accepted Glass Engine 1.0 baseline unless explicitly requested.

## PR and acceptance

Every change goes through a PR. PR Validation must succeed; Pages Assembly must deploy the corresponding preview. Provide PR, Actions run and preview links, plus the actual head SHA and check results. Preview path: /flutter-motion-design-system/previews/pr-N/. The user must approve the current revision before merging. Recheck the head SHA and CI before merge. After merge verify main deployment and preview cleanup.

## Deployment

One repository, one Pages site. Assemble main at the root and successful same-repository PR builds under previews/pr-N/. A failed preview is omitted; a failed main build blocks publication. Serialize Pages deployments. Keep main and refs/pull/*/merge environment rules; do not grant unrestricted deployment access. Do not merge untrusted workflow changes.

## Scope and deferred work

The v0.1.4 acceptance scope is normal PR CI, independent preview and user-approved merge. Dedicated multi-PR failure/concurrency tests, strict formatting enforcement, committed dependency lockfile and further infrastructure hardening are deferred to normal development. CI currently formats before analysis and archives the generated lockfile; neither is equivalent to a committed lockfile or a strict formatting gate.
