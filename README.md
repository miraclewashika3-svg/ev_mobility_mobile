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

Ten screens: Login, Register, Forgot/Reset Password, Station Finder (list
**and** map view, with one-tap Google Maps directions to any station), Log
a Swap, Add Bike, My Bike (profile + swap history), and Savings. Sign-out
is reachable from every tab's app bar.

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

7 tests: all four model classes' JSON parsing (including Laravel's
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
