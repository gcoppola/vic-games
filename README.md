# Vic's Games

Little browser games for kids, playable on phone or computer. Each game is a single self-contained HTML file.

Live: https://storage.googleapis.com/vic-games/index.html (public bucket `gs://vic-games`, project `lmemvp1`)

| Game | File | Type |
|---|---|---|
| Warbound: Orcs & Humans | `warcraft.html` | Pixel-art RTS |
| Warbound HD | `wc3.html` | Same game, HD art |
| Warbound: Remastered | `reforged.html` | Same game, cinematic effects |
| Aethermoor | `aethermoor.html` | 3D action-RPG (needs internet) |
| Sparklehoof's Meadow | `fairyland.html` | Ages 6–7 learning game, installable + offline |
| Once Upon a You | `onceuponayou.html` | Deployed, not yet listed in `games.json` |

## How it fits together

- `public/index.html` is the hub. It renders the game cards from `public/games.json`, which is the single source of truth for the menu, and appends `?v=<build>` to each link to bust stale caches.
- `public/sw.js` + `public/manifest.webmanifest` make Sparklehoof's Meadow installable and playable offline. Other games use the default network path.

## Deploy

**Automatic:** every push to `main` that touches `public/` is published by the GitHub Action
[`.github/workflows/deploy.yml`](.github/workflows/deploy.yml). It checks the build numbers agree, syncs `public/` to the
bucket, then confirms the live `games.json` reports the new build. Auth is keyless (Workload Identity Federation):
only `main` of this repo can deploy, and only to `gs://vic-games`.

One-time Google-side setup (project owner): `./infra/setup-github-deploy.sh` in Cloud Shell, or
`.\infra\setup-github-deploy.ps1` in Windows PowerShell with gcloud installed.

**By hand** (e.g. Cloud Shell): `./deploy.sh`

Before shipping a new build, bump `build` in `public/games.json` and the `sparklehoof-bNN` cache name in `public/sw.js`
and `public/fairyland.html` together — the Action refuses to deploy if they disagree.

Initial commit is a byte-for-byte snapshot of the live bucket at build 24 (2026-06-19), checksum-verified.
