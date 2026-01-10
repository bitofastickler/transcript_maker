#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "SUPABASE_URL and SUPABASE_ANON_KEY must be provided as build env vars." >&2
  exit 1
fi

cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
EOF

git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git /tmp/flutter
export PATH="/tmp/flutter/bin:${PATH}"

flutter config --enable-web
flutter precache --web
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
