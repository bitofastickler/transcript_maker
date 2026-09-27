# Contributing

Use Flutter 3.35.7 and `flutter pub get`. Run `dart format lib test`, `flutter analyze`,
`flutter test`, and `flutter build web --release --no-web-resources-cdn` before a PR.
Commit the lockfile when dependencies change. Do not use real student records in
issues, fixtures, screenshots, commits, or pull requests.

Keep the local-only architecture: no account, analytics, payment, server, or remote font
requirements. Version the file format before incompatible changes and preserve import
compatibility. Test cancellation, disk/read failures, malformed files, and unchanged state
on failure. GPA changes need explicit policy documentation and boundary tests.

Source layout:
- `lib/models/student.dart`: record types and local serialization.
- `lib/transcript_calculator.dart`: GPA and credit calculation.
- `lib/local_store.dart`: validated files and save/open boundary.
- `lib/platform/`: conditional browser exit warning.
- `lib/main.dart`: Flutter screens/forms and PDF composition (further separation welcome).
- `test/`: fictional fixtures and regression coverage.

Submit a focused PR explaining the user-visible change and verification. Use reproducible
steps and synthetic examples when reporting bugs. Be respectful and constructive.
