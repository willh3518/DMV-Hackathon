# accessibility_frontend

This directory contains the Flutter client for Android and iOS.

`accessibility_frontend` is an internal package identifier. The final product name has not been selected.

## Run the quality gates

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Run on a device

```bash
flutter devices
flutter emulators
flutter run -d <device-id>
```

Read the repository-level [frontend workflow](../docs/FRONTEND_WORKFLOW.md) before implementing UI.
