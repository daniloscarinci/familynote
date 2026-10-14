#!/usr/bin/env bash
# Builds the web app and publishes it to GitHub Pages (branch gh-pages).
# Run from Git Bash, in the T: mapped folder (the project path has an apostrophe):
#   export PATH="/c/Users/danil/dev/flutter/bin:$PATH"; cd /t/familynote; ./deploy-pages.sh
set -euo pipefail

OWNER="daniloscarinci"
REPO="familynote"
APP_URL="https://${OWNER}.github.io/${REPO}"

if [ ! -f dart_defines.json ] || grep -q "PASTE-THE-ANON" dart_defines.json; then
  echo "Missing dart_defines.json with the real anon key. Copy dart_defines.example.json and paste the key." >&2
  exit 1
fi
if grep -qi "service_role" dart_defines.json; then
  echo "dart_defines.json must contain only the anon/public key, never service_role." >&2
  exit 1
fi

flutter build web --release \
  --base-href "/${REPO}/" \
  --dart-define-from-file=dart_defines.json \
  --dart-define=APP_URL="${APP_URL}"

OUT="$(mktemp -d)"
cp -r build/web/. "$OUT/"
touch "$OUT/.nojekyll"
cp "$OUT/index.html" "$OUT/404.html"

cd "$OUT"
git init -q -b gh-pages
git add -A
git -c user.name="FamilyNote deploy" -c user.email="deploy@users.noreply.github.com" \
  commit -q -m "Deploy web build"
git push -q --force "https://github.com/${OWNER}/${REPO}.git" gh-pages

# Enable Pages from gh-pages (idempotent; errors if already enabled are ignored).
gh api -X POST "repos/${OWNER}/${REPO}/pages" \
  -f "source[branch]=gh-pages" -f "source[path]=/" >/dev/null 2>&1 || true

echo "Published. Site: ${APP_URL}/ (can take 1-2 minutes to appear)"
