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

1. Bump `build` in `public/games.json` and `CACHE` in `public/sw.js` (they move together; both at 24 today).
2. `./deploy.sh` (needs `gsutil` signed in with write access to the bucket).

Initial commit is a byte-for-byte snapshot of the live bucket at build 24 (2026-06-19), checksum-verified.
