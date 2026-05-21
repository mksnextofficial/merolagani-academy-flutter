# Merolagani Academy Android QA Handoff

Prepared on 2026-05-21.

## Current Status

The Android app is now a native Flutter app, not a WebView wrapper. The latest build includes native navigation, course browsing, course detail, a Udemy-style learning screen, protected Bunny playback handling, lesson quizzes, resources, watch-session heartbeats, lesson completion calls, and signed-in quiz attempt submission.

Release APK and AAB builds complete successfully. The release APK was installed and smoke-tested on the `Merolagani_API36` Android emulator.

## Major Changes

- Replaced the old separate/blank video page with `CourseLearningScreen`: video stays at the top, and lesson summary, resources, quiz, and curriculum stay below it.
- Direct HLS/MP4 playback uses Flutter `video_player`; Bunny player/embed URLs use `webview_flutter` inside the native lesson screen.
- Bunny playback now calls `POST https://merolaganiacademy.com/api/public/bunny/sign-playback`, prefers direct HLS/MP4 URLs when available, and falls back to Bunny embed/player URLs.
- Added protected-video states: signed-out learners see a clear sign-in prompt; expired sessions are refreshed/retried before showing an auth failure.
- Fixed the signed-out course detail action so `Sign in to start` opens the Account tab instead of dropping users into a failed lesson screen.
- Added video progress tracking through `video_watch_sessions` create/update calls.
- Added `POST /api/public/lessons/mark-complete` after completed playback progress.
- Added quizzes/questions from Supabase and lesson-level quiz counts in the curriculum.
- Added signed-in quiz attempt submission to `quiz_attempts`.
- Added responsive player-state messaging so the video area no longer shows Flutter overflow warnings.

## Verification Completed

Commands run successfully:

```sh
dart format lib/main.dart
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

Release artifacts:

- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/MerolaganiAcademy-playback-fix-release.apk`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/MerolaganiAcademy-playback-fix-release.aab`

Emulator QA:

- Installed release APK on Android API 36 emulator.
- Opened Home and Courses.
- Opened `Credit Course` course detail.
- Verified signed-out `Sign in to start` routes to Account instead of opening the lesson screen.
- Verified the app launches after adding `webview_flutter`.
- Checked logcat after navigation for Flutter render overflow, Android fatal exception, and ANR patterns.

Latest screenshots:

- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/17-release-home.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/18-release-courses.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/19-release-course-detail.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/20-release-learning.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/21-release-quiz-actions.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/22-playback-fix-signed-out-account.png`

## Important Remaining Blockers

Protected Bunny playback still needs one real enrolled learner test. All published Credit Course lessons currently require a signed-in/enrolled user, and the emulator is not signed in with an enrolled learner account. Without that, the app can verify the signed-out flow, release build, WebView/native player compilation, and app stability, but not successful protected playback with the real user entitlement.

## Build Notes

- Package id: `com.meroverse.merolagani_academy`
- Version: `1.0.0+1`
- Minimum SDK: `24`
- Target SDK: `36`
- Cleartext traffic: disabled
- Android backup: disabled
- Release builds use the debug signing config if `android/key.properties` is absent. Add a production keystore before Play Store upload.

Flutter currently warns that `shared_preferences_android`, `video_player_android`, and `webview_flutter_android` apply the Kotlin Gradle Plugin. This is a future Flutter compatibility warning, not a current build failure.
