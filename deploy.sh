#!/usr/bin/env bash
# Deploy public/ to the gs://vic-games bucket (project lmemvp1). Used by the GitHub Action and by hand (e.g. in Cloud Shell).
# Everything is served Cache-Control: no-cache so a new build shows up on next load. Only files whose checksum changed are
# uploaded. Before deploying a new build, bump "build" in public/games.json and the CACHE name in public/sw.js (and
# fairyland.html's precache name) together. Removed files stay in the bucket; pass --delete-unmatched-destination-objects
# to make it an exact mirror.
set -euo pipefail
cd "$(dirname "$0")"
gcloud storage rsync public gs://vic-games --recursive --checksums-only --cache-control=no-cache "$@"
# the PWA manifest's type isn't inferred from .webmanifest; pin it so "Add to Home Screen" keeps working
gcloud storage objects update gs://vic-games/manifest.webmanifest --content-type=application/manifest+json --cache-control=no-cache
