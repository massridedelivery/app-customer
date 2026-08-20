# Permissions — Customer app (store-ready reference)

**Principle:** ask only what a feature needs, ask **in context** (never at launch),
and declare **foreground location only** — no background location on either platform.

Last audited: 2026-08-21 (merged Android manifest + iOS Info.plist + code).

## Audit — what the app declares & why

| Permission | Feature | Needed? | Requested when |
|---|---|---|---|
| **INTERNET** | all networking | ✅ | n/a (normal) |
| **ACCESS_NETWORK_STATE** | connectivity checks | ✅ | n/a |
| **ACCESS_WIFI_STATE** | wifi-assisted coarse location (plugin `location`) | ✅ (plugin) | n/a |
| **ACCESS_FINE_LOCATION** | current location: nearby shops, autofill pickup, live map | ✅ | on entering the map / "ใช้ตำแหน่งปัจจุบัน" |
| **ACCESS_COARSE_LOCATION** | same (coarse fallback) | ✅ | same |
| **POST_NOTIFICATIONS** | order status / promos | ✅ | **after login only** |
| **VIBRATE**, **WAKE_LOCK** | local/FCM notifications (plugin-injected) | ✅ (plugin) | n/a |
| ~~ACCESS_BACKGROUND_LOCATION~~ | — | ❌ **absent** (verified in merged manifest) | never |

iOS (`Info.plist`):

| Key | Feature | Status |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | foreground location | ✅ present, specific |
| ~~`NSLocationAlwaysAndWhenInUseUsageDescription`~~ | background/Always | ❌ **removed** (app is foreground-only) |
| `NSPhotoLibraryUsageDescription` | pick profile avatar (`image_picker`) | ✅ |
| `NSCameraUsageDescription` | take profile avatar (`image_picker`) | ✅ |
| `UIBackgroundModes` (location) | — | ❌ absent (correct) |

**Not declared (correct):** microphone, contacts, calendar, background location.
Calling the driver uses a `tel:` URL → no CALL_PHONE / no dialer permission.

## Request timing (in-context, verified in code)

- **Notifications** — requested on login only (`PushNotificationService` listens to
  `authControllerProvider`; also re-requests when a stored session is restored).
  Never prompts a logged-out/first-launch user.
- **Location** — requested when the map/home needs the current position, via the
  `location` plugin (`serviceEnabled → hasPermission → requestPermission`). On deny
  the user still proceeds by **typing the address** (search) — location is never a
  hard block.
- **Camera / Photos** — requested by `image_picker` only when the user taps to
  change their profile avatar.

Recommended in-context pattern for any new permission (priming → OS prompt →
settings on hard-deny):
```dart
Future<bool> ensure(Permission p, {required String why}) async {
  var s = await p.status;
  if (s.isGranted) return true;
  if (s.isPermanentlyDenied) { await openAppSettings(); return false; }
  // show a short priming sheet explaining `why` here, then:
  s = await p.request();
  return s.isGranted;
}
```

## Google Play — Data safety form

- **Location:** collected/used, **Approximate + Precise**, purpose *App
  functionality* (find nearby shops, autofill address, track order) — **used while
  app is in use only**. No background location → **no Location Permissions
  declaration form** needed.
- **Photos:** optional, profile avatar only; not shared.
- **Notifications:** POST_NOTIFICATIONS runtime prompt (Android 13+).
- Android 13+ media: prefer the system **Photo Picker** (no broad media permission).

## App Store — App Privacy

- **Location (Precise):** *App Functionality* — not used for tracking, not linked
  to identity for ads. WhenInUse only.
- **Photos:** *App Functionality* (avatar).
- Purpose strings must be specific (they are — see table). **Do not** add
  `NSLocationAlwaysAndWhenInUse` unless a real background-location feature ships.

## Acceptance
- [x] Every permission maps to a feature; none unused (background location absent)
- [x] No background location — Android (merged manifest) + iOS (no Always / no bg mode)
- [x] iOS purpose strings present + specific; asked in-context
- [x] Location deny has a fallback (type the address) — never blocks the user
- [x] Notifications asked after login, not at launch
- [ ] Fill Play Data safety + Apple App Privacy to match this doc at submission
- [ ] permanentlyDenied → route the user to `openAppSettings()` (add if/when a
      hard-deny dead-end appears; current flows fall back to manual entry)
