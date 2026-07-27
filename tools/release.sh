#!/usr/bin/env bash
# Cut a GitHub release for one mod: pack it with the game repo's modkit
# and upload the zip as the release asset.
#
#   tools/release.sh jj_repel_prompt
#
# GAME_REPO points at the game checkout (for modkit pack); it defaults to
# the sibling folder of this repo.
set -euo pipefail

MOD=${1:?usage: tools/release.sh <mod-id>}
GAME_REPO=${GAME_REPO:-../pokemon-gen1-recomp-project}
REPO=johnjohto/pokemon-mods

VERSION=$(python -c "import json; print(json.load(open('$MOD/manifest.json'))['version'])")
TAG="$MOD-v$VERSION"
ZIP="$(mktemp -u)/$TAG.zip"
mkdir -p "$(dirname "$ZIP")"

python "$GAME_REPO/tools/modkit.py" pack "$GAME_REPO/mods/$MOD" -o "$ZIP"

gh release create "$TAG" --repo "$REPO" \
  --title "$MOD v$VERSION" \
  --notes-file "$MOD/README.md" \
  "$ZIP"

echo "released: https://github.com/$REPO/releases/tag/$TAG"
