# Debug UI Notes

## Removed debug buttons

The visible debug token buttons were implemented in `lib/main.dart` as a
debug-only `MaterialApp.builder` overlay:

- `Debug: Copy Auth Token`
- `Debug: Copy FCM Token`

The visible `Debug: Subscribe what89` button was implemented in
`lib/screens/reports_screen.dart` as a debug-only Reports screen helper.

These visible controls were removed so they do not appear on Web, Android, or
any other platform. The normal app UI and non-debug navigation remain unchanged.

## Re-enabling safely

If these tools are needed again, re-add them behind an explicit debug-only guard
such as `kDebugMode`, keep them out of release builds, and verify every target
platform with `flutter analyze`, `flutter test`, and a real app run. For FCM
token access, keep Android-only calls guarded with `!kIsWeb` and the Android
platform check before calling Firebase Messaging APIs.
