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

Fifteen screens: Login, Register, Forgot/Reset Password, Station Finder
(list **and** map view, with one-tap Google Maps directions to any
station), Scan Station, Pay for Swap, Log a Swap, Add Bike, My Bike
(profile + swap history), Savings, Settings, Change Password, and Help &
support. Settings is reachable from every tab's app bar and is where Sign
out now lives.

**Light/dark theme.** A real `ThemeExtension`-backed theme, not just a
system default follow — toggled from Settings, persisted across restarts
via `flutter_secure_storage`, and applied consistently across every
screen (cards, nav bar, empty states) rather than a partial pass that
leaves some surfaces stuck in light mode.

**More than one bike.** The backend has always allowed unlimited bikes
per rider; the UI now actually exposes it. My Bike's app bar can always
add another bike (not just from the empty state), and a chip selector
appears — on My Bike and on Log a Swap — the moment there's more than
one to choose between, so a rider with a growing fleet can view any
bike's own profile/history and pick exactly which bike a swap counts
against, without cluttering the common single-bike case.

**Pay for Swap.** Sits between picking a station and logging a swap — a
swap can't be logged without a completed payment (the backend enforces
this, not just the UI). The amount is always the station's own listed
price, never something the rider types in. `method` is `'simulated'`:
there's no live payment gateway account behind this yet, and the screen
says so in an explicit on-screen badge rather than pretending otherwise.
See the backend repo's `docs/FUTURE_CONSIDERATIONS.md` for what wiring in
a real gateway (e.g. M-Pesa's Daraja STK push) would change — the payment
model, the swap-log gating, and this screen's flow all stay the same;
only what confirms a payment changes. **Log a Swap** also has a
date/time picker (defaulting to now, editable back to 90 days) — the
same "you can pick any past date and time" Help & support has always
told riders, for a swap they forgot to log at the time.

**Settings** shows the rider's real profile (via `GET /me`), a functional
"Stay signed in" toggle, a dark mode toggle, a "Require fingerprint to
unlock" toggle (shown on any biometric-capable device, even before
anything's enrolled — turning it on when nothing is explains that in
plain language and points to the phone's own Settings, since no app can
ever enroll a fingerprint on a rider's behalf), Change Password, Help &
support, and About. **Help & support** is a real FAQ grounded in this
app's actual product decisions (the savings formula, cross-network swaps,
logging a swap after the fact) plus a working `mailto:` contact link.

**Biometric unlock.** A fingerprint never reaches the backend and isn't a
new server-side auth method — it's a local gate (`local_auth`) in front
of the session token already sitting in the platform keystore, and every
prompt is rider-initiated: nothing pops up on its own. Three tap-triggered
entry points: a **"Sign in with fingerprint"** button on the Login screen
when a restored session is waiting to be confirmed; an **"Unlock"** button
on a lock screen shown the moment the app is resumed from the background
with the Settings toggle on (an `AppLifecycleState` observer, not just a
cold-launch check — MIUI in particular keeps the process alive across
what looks, to the rider, like fully closing the app, so relying on a
fresh process alone turned out to be unreliable); and confirming it from
Settings when first turning the toggle on. A rider without biometric
hardware never sees any of it — this is additive, and the email/password
flow is untouched throughout. See the backend repo's
`docs/FUTURE_CONSIDERATIONS.md` §5 for where this goes
next (biometric confirmation on sensitive actions, passkeys/WebAuthn).

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
tabs doesn't re-trigger API calls). Pull-to-refresh re-fetches on demand,
and a shared `DataRefreshSignal` also refetches My Bike and Savings
automatically the moment a swap is logged from Stations — no manual
refresh needed, even while those tabs are sitting inactive behind the
tab bar.

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

14 tests: all five model classes' JSON parsing (including Laravel's
decimal-fields-as-strings quirk), the light/dark theme and its
Settings-driven toggle, the shared DataRefreshSignal, and that the app
boots to the login screen when no prior session exists.

## Deployment

**Live:** https://ev-mobility-mobile.ev-mobility-mobile.workers.dev

Deployed as a web build to Cloudflare Workers. `.github/workflows/deploy.yml`
redeploys automatically on every push to `main` — provided the repo's
`CLOUDFLARE_API_TOKEN` secret (Settings → Secrets and variables →
Actions) is a valid token with Workers Scripts edit permission for the
account. To deploy by hand instead (e.g. while that secret is missing
or invalid):

```bash
flutter build web --dart-define=API_BASE_URL=https://backend-production-10b9.up.railway.app/api
npx wrangler deploy
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
