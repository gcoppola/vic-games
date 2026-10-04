#!/usr/bin/env bash
# Deploy public/ to the gs://vic-games bucket (project lmemvp1).
# Everything is served Cache-Control: no-cache, matching the live bucket, so a new build shows up
# on next load. Before deploying, bump "build" in public/games.json and CACHE in public/sw.js.
# Removed files stay in the bucket; pass -d to make it an exact mirror.
set -euo pipefail
cd "$(dirname "$0")"
gsutil -m -h "Cache-Control:no-cache" rsync -r -c "$@" public gs://vic-games
