# EV Mobility Platform — Rider App (Mobile)

![Mobile Tests](https://github.com/miraclewashika3-svg/ev_mobility_mobile/actions/workflows/tests.yml/badge.svg)

The rider-facing Flutter app for the EV Mobility Platform: find a swap
station across every network, get one-tap directions, log a swap, and
track real savings against petrol. Talks to the
[`ev-mobility-platform`](https://github.com/miraclewashika3-svg/ev-mobility-platform)
Laravel API — see that repo's [`docs/ARCHITECTURE.md`](https://github.com/miraclewashika3-svg/ev-mobility-platform/blob/main/docs/ARCHITECTURE.md)
for the full system design. The admin-facing counterpart to this app is
[`ev-mobility-web`](https://github.com/miraclewashika3-svg/ev-mobility-web)
(Vue).

Built for the Certificate in Software Development, @iLabAfrica Research
Centre, Strathmore University (cohort June–August 2026).

## Tech stack

| Layer | Technology |
|---|---|
| Language | Dart |
| Framework | Flutter (SDK ^3.12.2) |
| HTTP | `http` package, bearer-token auth against Sanctum |
| Maps | `flutter_map` + OpenStreetMap tiles (no API key or billing account) |
| Directions | `url_launcher`, deep-links into the real Google Maps app |
| Testing | `flutter_test` — model unit tests + a widget test |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.12.2
- The backend ([`ev-mobility-platform`](https://github.com/miraclewashika3-svg/ev-mobility-platform))
  running locally, or a deployed instance's URL

## Setup

```bash
git clone https://github.com/miraclewashika3-svg/ev_mobility_mobile.git
cd ev_mobility_mobile
flutter pub get
```

By default the app points at `http://localhost:8000/api`
(`http://10.0.2.2:8000/api` automatically on an Android emulator, since it
can't reach the host machine as `localhost`). Run against a local backend
with no further setup:

```bash
flutter run
```

To point a build at a deployed backend instead (e.g. for a web build you
can hand someone a link to), pass the API URL at compile time:

```bash
flutter build web --dart-define=API_BASE_URL=https://your-backend.up.railway.app/api
```

Sign in with a seeded rider account (see the backend repo's README for
credentials), or register a new one from the login screen.

## What's here

Thirteen screens: Login, Register, Forgot/Reset Password, Station Finder
(list **and** map view, with one-tap Google Maps directions to any
station), Scan Station, Log a Swap, Add Bike, My Bike (profile + swap
history), Savings, Settings, and Help & support. Settings is reachable
from every tab's app bar and is where Sign out now lives.

**Settings** shows the rider's real profile (via `GET /me`), a functional
"Stay signed in" toggle, Help & support, and About. **Help & support** is
a real FAQ grounded in this app's actual product decisions (the savings
formula, cross-network swaps, logging a swap after the fact) plus a
working `mailto:` contact link.

**Scan Station.** A "tap and go" alternative to picking a station from
the list — the camera icon in Station Finder opens a QR scanner
(`mobile_scanner`); scanning a station's code jumps straight to Log a
Swap for that exact station, skipping manual selection. Same pattern
real swap networks use for their check-in flow. Native-camera feature —
works on Android, not through the web build (a browser can't usefully
scan a QR code being displayed on the same screen it's running on).

A successful scan also records the rider's check-in with the backend
immediately — before the swap itself is logged, and independent of
whether it's ever completed. This is the accountability record behind a
station visit: the rider's identity and arrival time are on file the
moment they scan, whether or not the swap that follows is finished.
Best-effort — a failed check-in request never blocks logging the swap.

Every screen's data cache is kept alive across tab switches (so switching
tabs doesn't re-trigger API calls), with pull-to-refresh on each tab so a
swap logged from Stations shows up on My Bike/Savings without needing a
restart.

**Persistent login.** A rider who's already signed in stays signed in
across app restarts and Android backgrounding the process — the auth
token is saved to the platform keystore (`flutter_secure_storage`), not
just an in-memory variable, so the app checks for a prior session on
launch and skips straight to Home when one exists. Verified end-to-end
on a physical Redmi 12 5G.

## Running tests

```bash
flutter test
```

8 tests: all five model classes' JSON parsing (including Laravel's
decimal-fields-as-strings quirk) and that the app boots to the login
screen when no prior session exists.

## Deployment

**Live:** https://ev-mobility-mobile.netlify.app

Deployed as a web build to Netlify (free tier, no card required):

```bash
flutter build web --dart-define=API_BASE_URL=https://backend-production-10b9.up.railway.app/api
netlify deploy --prod --dir=build/web --no-build
```

A native build needs a $25 one-time Google Play fee or a $99/year Apple
developer account — both real costs this project deliberately avoids at
this stage. Instead:

- `flutter build web` produces a build deployable to any free static host
  (Netlify, Vercel) — anyone can open a link and use the real app with no
  install, arguably a *better* demo experience than an app-store link.
- `flutter build apk` produces a `.apk` installable by direct download
  (e.g. attached to a GitHub Release) — a real native Android install with
  no Play Store account needed, for anyone who wants to try it on an
  actual device.
