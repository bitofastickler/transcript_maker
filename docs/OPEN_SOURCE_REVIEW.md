# Open-source readiness review

Reviewed September 26, 2026. Baseline: `ea075dd` on private `main`.
Implementation branch: `codex/local-first-open-source`.

## Scope and conclusion

Reviewed the complete application source, models/forms, GPA/PDF paths, SQL policies,
three billing functions, setup/build/platform files, lockfile, project documentation,
and signed-in Squarespace Products page. Scanned the 24 existing commits for secrets.
This was one agent's source and runtime review, not an independent penetration test.
No real student records, production login sessions, payment flows, or databases were modified.

The core has useful transcript functionality but the original service-backed app was
not public-release-ready. The user chose to remove Supabase and Stripe entirely,
with local files only and no service infrastructure. This branch implements that direction.
GitHub Pages is a suitable static host; publishing code and publishing the site are separate actions.

## Findings and disposition

| Priority | Baseline finding and impact | Disposition |
|---|---|---|
| High | `supabase/schema.sql` permits owner UPDATE of all profile columns, including Stripe customer ID. Portal/checkout functions trust this ID. A caller able to learn another customer ID could request that customer's portal session under the supplied schema's privileges. Live production grants were not checked. | Cloud/billing source and dependencies removed. This does **not** fix any old deployed copy; legacy service retirement needs separate review. |
| High | `StudentRepository.saveStudent` upserts a parent then deletes/inserts child rows through separate requests. Partial failures can lose courses/awards/activities. | Removed remote repository. Local save prepares and validates all records, then commits session state after the file operation succeeds. Cancellation/failure tests preserve state. Native OS writes are not claimed to be crash-atomic. |
| High | `StudentDetailPage._updateStudent` notifies the parent on every edit; leaving shows unsaved values as persisted. Save completion also accessed disposed state. | Edits remain in the detail draft until successful save; guarded route exit and mounted check added. Saving disables editing. |
| High | Long academic-year PDF sections are nested in an unbreakable Padding; an 80-course test raised TooManyPagesException. | Flattened sections to allow spanning tables; repeated column headings, page footers, and a regression test added. |
| Medium | Any nonempty grade accepted; unknown grades silently omitted from GPA. Numeric fields accept non-finite values. Weighted calculation applies a multiplier even when `isWeighted` is false. | Grade and finite/range validation added; multiplier honors the flag; tests cover credit weighting, pass/fail, F, quarter credits, and empty records. |
| Medium | Credits rounded to one decimal and activity hours to whole numbers in output. | Display to two decimals. |
| Medium | Default PDF fonts do not reliably support accented names. GPA method not explained on output. | Bundled licensed Noto Sans fonts and printed policy note; accented-name test. Not full international-script support. |
| Medium | Billing redirects and price IDs are caller-controlled. Webhook code lacks durable event ordering/idempotency storage; errors are exposed directly. | Billing removed. No production remediation/retirement claimed. |
| Medium | Fresh-clone setup references absent `.env.example`; `.env` bundled into client, so README claim that config stays local is misleading. README Flutter version is incompatible with Dart requirement. Android config unconditionally loads private signing file. | No environment setup or bundled secrets. Pinned verified SDK guidance. Android signing config becomes conditional; native builds remain unverified. |
| Medium | A stale widget test expects a Students screen despite auth-gated startup. No file/GPA/save/PDF regressions or CI. | Replaced with domain, persistence, widget, and PDF tests; added CI and a manual Pages workflow. |
| Medium | No local data portability, documented privacy boundary, or unsaved-close protection. | Versioned JSON for all records, strict import checks, explicit manual-save guidance, route/browser warnings, privacy/help docs. Browser warnings are best-effort. |
| Medium | Product page promises customizable formatting and college-ready output; implementation has one fixed layout. Transcript link points to Biblical Bot. | Accurate replacement copy drafted; live page unchanged pending release approval. |
| Medium | No open-source license or contributor/security process. | MIT license prepared, third-party font notice, contributor/security/privacy docs and release checklist added. Ownership confirmation remains a publication prerequisite. |
| Medium | Academic-year header overflows on a 390 px screen with enlarged text. | Changed the fixed row to a wrapping layout and added a regression test. |
| Low | 4,330-line main file mixes UI, billing, persistence, model, GPA, PDF, and samples. Old docs overstate status. | Removed service code, extracted model/calculator/file-store/platform layers, archived obsolete docs, replaced old samples with an explicitly fictional fixture. Further UI/PDF extraction is a follow-up. |

The historical March review said Stripe customer persistence errors were ignored;
that specific issue was already fixed in the current baseline and is not a new finding.

## Verification evidence

- Flutter 3.35.7 / Dart 3.9.2; no backend/environment secrets used for builds/tests.
- All 13 unit/widget tests pass; analyzer reports no issues. Tests cover JSON round-trips, invalid/future versions, foreign child IDs,
  duplicate IDs, malformed/oversized files, invalid dates/grades/credits, save cancellation,
  failed-save state, GPA rules, startup, dirty navigation, mobile layout, and long PDFs.
- Release web build with `--no-web-resources-cdn` bundles rendering assets locally.
- PDF stress fixture: 80 courses, accented name, quarter credits, award and fractional
  activity hours. Generated three pages; first/last page visual inspection confirmed
  table flow and legibility (initial pagination failure was fixed).
- Edge browser: local app opens without configuration; built-in fictional example
  loads with GPA 4.00 / credits 1.00. Browser download produced `transcript-records.json`;
  its parsed JSON exactly matched the fictional source fixture.
- Browser file chooser automation could not reopen a disk file because the extension's
  file-URL permission is disabled. Permission was not changed. Reopen is covered at the
  serialization/store boundary; manual browser chooser round-trip remains on the release checklist.
- Automated typing into Flutter's numeric semantics field was inconsistent; full new-student
  browser entry is not counted as passed. Form/draft widget behavior is tested. Human walkthrough
  before publication remains valuable.
- Gitleaks 8.30.1: all 24 baseline commits and the 25-commit conversion history, zero findings. Official release archive SHA-256
  verified against upstream checksums. Supplementary pattern scan: 191 unique Git blobs,
  no credential-pattern matches. These scans cannot establish that all personal information
  or secrets are absent.
- OSV query of 49 locked hosted Pub versions: zero known advisories returned on review date.
  This is a snapshot, not a guarantee that dependencies have no vulnerabilities.

Tests/builds use a source copy under the local cache because OneDrive interfered with
Flutter's test-cache directory cleanup. The source workspace remains the repository.
No signed native builds, mobile-device tests, screen-reader audit, production database
policy checks, or hosted Pages deployment were performed.

## Remaining product improvements, in order

1. Complete manual browser save/reopen and new-student entry, then test keyboard-only
   navigation and major mobile browsers before calling the release stable.
2. School identity, parent/administrator certification and signature lines, optional
   birth-date/contact display, print preview, US Letter/A4 selection. Current PDF uses A4.
3. Configurable grading policies (including additive AP/Honors weights), clear treatment
   of in-progress/repeated/withdrawn courses, and policy printed on the transcript.
4. Recovery drafts or an explicit document save model, only if they preserve the user's
   local-only privacy expectation; never silently introduce cloud storage.
5. Export/import UX for merging files and migrating existing hosted-user records.
6. More modular UI/PDF code, expanded accessibility testing, localization/font coverage,
   and verified native binaries with signing before advertising platform support.

## Publication boundary

The maintainer confirmed the historical John/Jane Smith samples are fictional and safe
to publish on September 26, 2026. Keep the repository private until final release approval,
including the prepared MIT license. Public history can be copied even if visibility is later reversed.
Review the preview and PR, then explicitly approve public visibility and Pages deployment.
No live Squarespace copy, hosting project, database, or Stripe subscription was changed.

## Sources

- [GitHub Pages static hosting](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages)
- [Supabase column-level privileges](https://supabase.com/docs/guides/database/postgres/column-level-security)
- [File picker package](https://pub.dev/packages/file_picker)
- [OSV API](https://google.github.io/osv.dev/api/)
