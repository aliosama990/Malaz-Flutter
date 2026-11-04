# Malaz
### Ongoing graduation project · Flutter client

Malaz is an ongoing graduation project for child monitoring. **Ali Osama developed the complete Flutter client**, including its interface, application state and client-side integrations for child profiles, safe zones, chat, notifications and live device events.

This repository contains the Arabic-first Flutter client. The backend and device firmware are separate components.

## Implemented in the client

- Authentication screens and provider-based session handling.
- Child profile creation, retrieval, update and removal through REST endpoints.
- Safe-zone creation, retrieval, editing and deletion, with map/location dependencies.
- API-backed chat sessions, message history and optimistic message display.
- Notification preferences and Firebase/local-notification integration.
- SignalR subscriptions for device readings, alerts and emergency audio events, including reconnection and resubscription.
- Response parsing, loading/error states and automated tests for several providers and models.

**Current boundaries:** backend availability, credentials, Firebase configuration and device events are external dependencies. The reports screen combines live emergency audio events with sample report entries; it is not a fully live reporting system. Platform scaffold folders do not establish feature parity across platforms.

## Technology

Flutter/Dart, Provider (`ChangeNotifier`), HTTP/JSON REST calls, SignalR, Firebase Core/Messaging, local notifications, SharedPreferences, flutter_map, Geolocator and just_audio.

## Structure

| Path | Purpose |
| --- | --- |
| `lib/screens/` | Screens and user interaction |
| `lib/widgets/` | Reusable interface components |
| `lib/providers/` | Application state and asynchronous operations |
| `lib/services/` | REST, chat, device hub and push-notification integrations |
| `lib/models/` | Typed data and response parsing |
| `lib/helpers/` | Preference and helper utilities |
| `test/` | Provider, parsing, model and widget tests |

The code uses a screen/provider/service structure. It should not be described as a complete Clean Architecture implementation.

## Local setup

1. Install Flutter with a Dart SDK satisfying `>=3.0.0 <4.0.0`, and the Android toolchain. Run `flutter doctor`.
2. Clone and enter the repository:

   ```sh
   git clone https://github.com/aliosama990/Malaz-Flutter.git
   cd Malaz-Flutter
   flutter pub get
   ```

3. Review the backend configuration in `lib/services/api_service.dart` and `lib/services/device_hub_service.dart`. Access to a compatible API, valid test account and device data is needed for integrated flows.
4. For your own Android deployment, supply Firebase configuration matching your application ID. The Android app applies the Google Services plugin; Firebase is initialized for Android in `lib/main.dart`. Configure Google sign-in and notification permissions as required for the environment.
5. Start an Android emulator or connect a device:

   ```sh
   flutter run
   ```

The repository does not pin a Flutter release; dependency resolution may require a newer Flutter SDK than the lower Dart bound suggests. Android asset declarations currently contain Windows-style separators; review them if asset loading fails on another development OS.

## Checks

```sh
flutter analyze
flutter test
```

These are the project check commands, not a claim that they passed in every environment. Live backend, push delivery and device integrations require separate integration verification.

## Development status

Release signing is still configured with debug keys in the Android build file. Treat the project as development code until deployment configuration and end-to-end validation are complete.

## Attribution and licensing

Flutter client development: **Ali Osama**. Existing contributor credits and Git history are preserved. No license file is currently included; contact the repository owner about reuse.
