#!/usr/bin/env bash
# Builds the web app and publishes it to the gh-pages branch.
set -euo pipefail

cd "$(dirname "$0")/.."

flutter build web --base-href /yeremchuk-dental-calculator/ --no-wasm-dry-run -O1

cd build/web

# GitHub Pages serves everything with max-age=600 and Flutter loads its
# scripts by fixed names, so without a version query returning visitors get
# the previous build for up to 10 minutes after a deploy.
version=$(md5 -q main.dart.js | cut -c1-10)
sed -i '' "s|\"mainJsPath\":\"main.dart.js\"|\"mainJsPath\":\"main.dart.js?v=${version}\"|" flutter_bootstrap.js
sed -i '' "s|flutter_bootstrap.js\"|flutter_bootstrap.js?v=${version}\"|g" index.html

touch .nojekyll
cp index.html 404.html

if [ ! -d .git ]; then
  git init -q
  git checkout -q -b gh-pages
  git remote add origin https://github.com/exteel/yeremchuk-dental-calculator.git
  git fetch -q origin gh-pages
  git reset -q --soft origin/gh-pages
fi

git add -A
git commit -q -m "Deploy ${version}" || { echo "Nothing changed"; exit 0; }
git push -q origin gh-pages
echo "Deployed ${version}"
