# BlueApp

Bluetooth debug tool (Flutter). First version is for local use only — not for App Store / Play Store release.

## Prerequisites

- Flutter SDK with constraint `>=3.32.0` (local install used for this repo: 3.44.5 stable).
- This machine must have LaserPecker Flutter sources at:

  `/Users/feixiang/Desktop/work/laserpecker-flutter`

- Feasy Bluetooth SDK is a **path dependency** pointing at:

  `../../work/laserpecker-flutter/lp_plugins/feasy_blue_sdk`

  relative to this `BlueApp` folder. If that path is missing, `flutter pub get` / builds will fail. Do not vendor-copy the SDK jars/so into this repo.

## Run

```bash
cd BlueApp
flutter pub get
flutter test
flutter run
```
