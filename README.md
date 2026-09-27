# Homeschool Transcript Maker

A free, local-file homeschool transcript builder. Record courses, calculate GPA,
track awards and activities, and export a printable PDF. No accounts, subscriptions,
API keys, database, or application server.

**Release candidate:** the browser build is the primary supported target. Native
platform projects are included for contributors; signed desktop/mobile releases
are not yet verified or distributed. A public hosted URL will be added after release approval.

## Using it

1. Open the app and choose **Add Student**, or **Open transcript file** to resume.
2. Enter courses, awards, and activities. Course letters must be A+ through F;
   choose Pass/Fail mode for Pass or Fail grades.
3. Choose **Save file**. The JSON file contains every student in the current session.
   In a browser this starts a download: check that it completed and keep the file.
4. Open a student and choose **Export transcript to PDF** to print or share.

**The JSON file is your editable record. The PDF is a presentation copy.**
Work is held in memory until saved. There is no automatic recovery, cloud sync,
or browser storage. Closing/reloading can lose work; browser warnings are best-effort,
especially on mobile. Keep a second copy of important files. Opening a file replaces
all students in the session after a warning if changes are unsaved.

## Run from source

Install [Flutter 3.35.7](https://docs.flutter.dev/install/archive) (Dart 3.9.2).
Then, from a terminal:

```sh
git clone https://github.com/bitofastickler/transcript_maker.git
cd transcript_maker
flutter pub get
flutter run -d chrome
```

On Windows, Flutter plugins can require Windows Developer Mode for symbolic links.
Prefer a checkout outside OneDrive if build-cache deletion fails. No `.env` file is needed.

```sh
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
python -m http.server 8080 --bind 127.0.0.1 --directory build/web
```

Open http://localhost:8080. Serve the build through HTTP; opening `index.html` as a
file is unsupported. Build-time dependency downloads require internet access.
The build bundles CanvasKit and PDF fonts. A hosted browser app needs connectivity
to load its assets; this release does not promise offline PWA installation.

## GPA policy

GPA is weighted by course credits. A+/A = 4.0; A- = 3.7; B+ = 3.3; B = 3.0;
B- = 2.7; C+ = 2.3; C = 2.0; C- = 1.7; D+ = 1.3; D = 1.0; D- = 0.7; F = 0.
For weighted GPA, marked courses multiply grade points by their chosen multiplier.
This is **multiplicative**, not a fixed AP/Honors bonus. Pass/fail courses are excluded
from GPA; only Pass earns credits. F earns no credits. Credits display to two decimals.
An empty GPA displays 0.00. Institutions may recalculate using different policies.

The PDF uses one layout; it is not a guarantee of acceptance by any institution.
Review the receiving institution's transcript requirements. School details,
certification/signature fields, optional birth-date display, configurable grading
scales, and additional scripts/fonts remain release-roadmap items.

## Privacy and file format

See [PRIVACY.md](PRIVACY.md). Student data is not uploaded by the application.
The host receives normal requests for app assets. Saved JSON and PDF files are
unencrypted: your OS, chosen folder, backups, and sharing choices control access.
JSON files identify `format: "transcript-maker"` and `version: 1`; malformed,
unsupported, oversized, or inconsistent files are rejected before replacing work.

## Hosting on GitHub

GitHub Pages serves the static app; no Supabase, Stripe, Render, or paid service
is needed. The [Pages workflow](.github/workflows/pages.yml) runs **manually** only,
with build and test checks before deployment. Set repository Settings > Pages >
Source to GitHub Actions and run the workflow after approving a release. The workflow
sets the project base path from the repository name. Custom domains need a root base path.
The source repository's public visibility and Pages hosting are separate settings.

## Contributing and maintenance

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md),
[the full review](docs/OPEN_SOURCE_REVIEW.md), and [release checklist](docs/RELEASE_CHECKLIST.md).
The code is MIT licensed; bundled Noto fonts retain their SIL Open Font License.
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Older cloud architecture notes are archived under `docs/legacy/` and do not describe
this version. Removing integrations from source does not cancel existing subscriptions,
delete hosted records, or shut down previously deployed services.
