# Merolagani Academy Flutter App

Native Flutter Android app for Merolagani Academy.

## Current Status

- Android app shell, course browsing, learning dashboard, account flows, and embedded lesson playback are implemented in Flutter.
- Protected Bunny lesson playback now uses the Lovable mobile endpoint at `/api/public/bunny/sign-playback`.
- Direct HLS/MP4 lesson URLs use native Flutter `video_player`; Bunny player/embed URLs use an embedded Bunny WebView player inside the native lesson screen.
- Expired Supabase access tokens are refreshed and retried before protected video playback fails.
- Course lessons now open in a Udemy-style learning screen with the player on top and quizzes/curriculum below.
- Lesson quizzes/questions and signed-in quiz attempt submission are wired.
- Android deep links are registered for `merolagani://auth-callback` and `merolagani://reset-password`.
- Release APK and Android App Bundle have been built successfully.
- Local static checks pass with `flutter analyze` and `flutter test`.
- Android Studio can open the project from this folder.
- Protected video playback still needs a real enrolled learner login for final end-to-end validation.

## Build Artifacts

Release outputs are stored outside the project folder:

- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/MerolaganiAcademy-playback-fix-release.apk`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/MerolaganiAcademy-playback-fix-release.aab`

## Common Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

## Android Release Notes

The Android package id is `com.meroverse.merolagani_academy`.

Release signing supports an optional `android/key.properties` file. If it is absent, Flutter's debug signing is used so local release builds still complete. For Play Store upload, add a production keystore before building the final AAB.

See `docs/android-release-readiness.md` for the full implementation and QA handoff.
