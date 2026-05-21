# Merolagani Academy Android QA Handoff

Prepared on 2026-05-21.

## Current Status

The Android app is now a native Flutter app, not a WebView wrapper. The latest build includes native navigation, course browsing, course detail, a Udemy-style learning screen, native Bunny/HLS playback wiring, lesson quizzes, resources, watch-session heartbeats, lesson completion calls, and signed-in quiz attempt submission.

Release APK and AAB builds complete successfully. The release APK was installed and smoke-tested on the `Merolagani_API36` Android emulator.

## Major Changes

- Replaced the old separate/blank video page with `CourseLearningScreen`: video stays at the top, and lesson summary, resources, quiz, and curriculum stay below it.
- Replaced WebView playback with Flutter `video_player` native playback.
- Bunny playback now calls `POST https://merolaganiacademy.com/api/public/bunny/sign-playback` and prefers `hlsUrl` for native playback.
- Added protected-video states: signed-out learners see a clear sign-in prompt; enrolled learners should receive the signed Bunny HLS URL.
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

- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/MerolaganiAcademy-release-ready-android.apk`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/MerolaganiAcademy-release-ready-android.aab`

Emulator QA:

- Installed release APK on Android API 36 emulator.
- Opened Home and Courses.
- Opened `Credit Course` course detail.
- Entered the learning screen.
- Verified the video area is embedded at top, not a separate blank page.
- Verified lesson summary, quiz, quiz questions/options, and curriculum render below the player.
- Verified curriculum lesson switching updates the selected lesson.
- Checked logcat after navigation for Flutter render overflow, Android fatal exception, and ANR patterns.

Latest screenshots:

- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/17-release-home.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/18-release-courses.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/19-release-course-detail.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/20-release-learning.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/21-release-quiz-actions.png`

## Important Remaining Blockers

Protected Bunny playback still needs one real enrolled learner test. All published Credit Course lessons currently require a signed-in/enrolled user, and the emulator is not signed in with an enrolled learner account. Without that, the app can only verify the signed-out state and the native player wiring, not successful HLS playback.

GitHub push is still blocked by environment setup:

```text
fatal: not a git repository
gh is not authenticated
no GitHub app repository was available to Codex
```

To complete the final push, provide the target repository URL or initialize this folder as the intended repo, then authenticate GitHub/`gh`.

## Build Notes

- Package id: `com.meroverse.merolagani_academy`
- Version: `1.0.0+1`
- Minimum SDK: `24`
- Target SDK: `36`
- Cleartext traffic: disabled
- Android backup: disabled
- Release builds use the debug signing config if `android/key.properties` is absent. Add a production keystore before Play Store upload.

Flutter currently warns that `shared_preferences_android` and `video_player_android` apply the Kotlin Gradle Plugin. This is a future Flutter compatibility warning, not a current build failure.
