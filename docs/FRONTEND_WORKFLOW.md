# Frontend workflow

This frontend uses subagent-driven development for every feature. The parent agent coordinates the work; specialist agents plan, implement bounded slices, review accessibility, review Flutter code, and resolve concrete build failures.

## Role map

| Role | Responsibility | Write access |
| --- | --- | --- |
| Parent coordinator | Scope, ownership, integration, final verification | Shared integration surfaces |
| Planner or explorer | Trace the repository and propose a bounded plan | None |
| Flutter UI builder | Implement one assigned UI slice and focused tests | Explicitly assigned files |
| Accessibility reviewer | Review semantics, focus, scaling, contrast, targets, and motion | None |
| Flutter reviewer | Review the final Dart/Flutter diff | None |
| Dart build resolver | Fix a concrete analyzer, dependency, or build failure | Explicitly assigned failing files |

For Claude Code, use the project-local `flutter-ui-builder` plus the installed Everything Claude Code `planner`, `tdd-guide`, `a11y-architect`, `flutter-reviewer`, and `dart-build-resolver` agents.

For Codex, project-local role translations live under `.codex/agents/`. Upstream Everything Claude Code does not currently ship Flutter-specific Codex TOML agents, so these translations preserve the relevant role boundaries without installing its experimental Codex plugin.

## Feature loop

### 1. Frame the experience

Before implementation, record:

- **User goal:** what the person must accomplish
- **Visual thesis:** the mood, material, contrast, and energy of the screen
- **Content plan:** the information order and primary action
- **Interaction thesis:** two or three meaningful transitions or feedback moments
- **States:** loading, empty, error, unknown evidence, and success
- **Accessibility behavior:** semantics, focus order, text scaling, touch targets, contrast, input methods, and reduced motion

### 2. Assign ownership

Give each builder a concrete output and exclusive paths. Do not let parallel agents edit the same file.

Default coordinator-owned integration surfaces:

- `frontend/lib/app/`
- `frontend/lib/domain/`
- `frontend/lib/contracts/`

Parallel-friendly slices:

- Individual feature directories
- Design-system components with separate files
- Synthetic fixtures
- Independent widget tests
- Read-only research and review

### 3. Implement and integrate

Builders work against typed contracts and synthetic fixtures. Flutter renders match scores, evidence, and explanations supplied by a contract; it does not calculate them.

The coordinator reviews each handoff, resolves integration, and runs:

```bash
cd frontend
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

If a command fails, capture the full output and delegate the narrow failure to the Dart build resolver. After the checks pass, delegate the final diff to the Flutter reviewer.

## Mobile iteration loop

The project targets Android and iOS. List the available devices before starting:

```bash
cd frontend
flutter devices
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d <device-id>
```

While `flutter run` is active:

- Press `r` for hot reload.
- Press `R` for hot restart.
- Use DevTools and the Flutter Inspector to inspect layout, widget boundaries, and source.

### Physical iPhone from this workspace

macOS FileProvider adds metadata that breaks Apple code signing when Flutter builds inside this repository's Documents path. Use a temporary generated-build directory:

```bash
cd frontend
mkdir -p /tmp/dmv-hackathon-flutter-build
flutter config --build-dir=../../../../../tmp/dmv-hackathon-flutter-build
flutter run -d <iphone-device-id> --debug --no-color
```

Wait for the Dart VM Service, then press `d` to detach while leaving the app running. Restore the global Flutter setting afterward:

```bash
flutter config --build-dir=
```

The `/tmp/dmv-hackathon-flutter-build` directory is disposable and can be reused for faster repeat builds.

For isolated, mostly pure UI widgets, Flutter 3.44 supports the experimental Widget Previewer:

```bash
flutter widget-preview start
```

The previewer is web-based and does not support native plugins, `dart:io`, or `dart:ffi`. Use a device or emulator for those paths.

## Testing strategy

- **Widget tests:** meaningful controls, validation, state rendering, focus, and semantics
- **Accessibility guidelines:** Android and iOS target size, tap labels, and text contrast
- **Golden tests:** only stable, design-critical components; update on one canonical machine and Flutter version
- **Integration tests:** the critical mocked discovery flow once the first feature lands
- **Manual pass:** TalkBack on Android and VoiceOver on iOS before the demo when the platform is available

Useful checks:

```bash
flutter test
flutter test --update-goldens
flutter test integration_test/app_test.dart
```

New code should use `TextScaler` and `MediaQuery.textScalerOf(context)`. Animations must respect `MediaQueryData.disableAnimations`.

## Current environment

Verified on 2026-07-25:

- Flutter 3.44.8 stable
- Dart 3.12.2
- Android SDK 36.1 with accepted licenses
- Android debug APK build verified
- iOS 26.5 platform and simulator runtime installed
- Physical iPhone signing, installation, launch, and Dart VM Service verified
- Claude Code 2.1.178
- Everything Claude Code 1.10.0 enabled in Claude Code

The empty app uses Flutter's local Swift packages, so the current CocoaPods warning does not block this build. Revisit CocoaPods only if a future native plugin requires it.

## Sources

- [Everything Claude Code repository](https://github.com/affaan-m/ECC)
- [ECC Flutter reviewer](https://github.com/affaan-m/ECC/blob/main/agents/flutter-reviewer.md)
- [ECC Dart build resolver](https://github.com/affaan-m/ECC/blob/main/agents/dart-build-resolver.md)
- [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli)
- [Flutter DevTools Inspector](https://docs.flutter.dev/tools/devtools/inspector)
- [Flutter Widget Previewer](https://docs.flutter.dev/tools/widget-previewer)
- [Flutter testing overview](https://docs.flutter.dev/testing/overview)
- [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)
- [Flutter focus system](https://docs.flutter.dev/ui/interactivity/focus)
