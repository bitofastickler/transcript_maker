# Public release checklist

Release v2.0.0 was approved and published on September 26, 2026 (US Eastern).

- [x] Maintainer approved publishing the prepared MIT-licensed release and full Git history.
- [x] Maintainer confirmed historical John/Jane Smith sample records are fictional and safe to publish.
- [x] Gitleaks re-scan across all 28 pre-merge commits returned no findings.
- [x] Maintainer reviewed and approved the local browser preview; multi-page PDF visually reviewed.
- [x] CI analysis, 13 tests, and web build passed; Pages repeated analysis/tests/build on the merged release commit.
- [x] Known limitations documented in README; native binaries are not advertised as verified.
- [x] Private vulnerability reporting enabled.
- [x] Repository made public and PR #1 merged.
- [x] Pages deployed; live example and JSON download verified at the project-path URL.
- [x] v2.0.0 release published, targeting deployed commit d6687679e42d580650b54c87ca19174dab48adea.

Remaining follow-up:

- [ ] Complete browser file-chooser reopen and full new-student walkthrough across major browsers; see review for automation limitations.
- [ ] Configure a maintainer-appropriate branch protection policy.
- [ ] Approve and publish the prepared Squarespace product copy; verify the public page afterward.

Live app: https://bitofastickler.github.io/transcript_maker/
Deployment evidence: https://github.com/bitofastickler/transcript_maker/actions/runs/36282069740

Separate legacy-service retirement: inventory existing users/records and subscriptions,
provide an authorized export/migration path where needed, cancel billing through an approved
process, and only then retire hosting/database projects. Source removal alone does none of these.
No production legacy service or subscription was changed by this conversion.
