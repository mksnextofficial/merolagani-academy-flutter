# Merolagani Academy Android QA Handoff

Prepared on 2026-05-21.

## Current Status

The Android app is now a native Flutter app, not a WebView wrapper. The latest build includes native navigation, course browsing, course detail, a Udemy-style learning screen, protected Bunny playback handling, lesson quizzes, resources, watch-session heartbeats, lesson completion calls, and signed-in quiz attempt submission.

Release APK and AAB builds complete successfully. The release APK was installed and smoke-tested on the `Merolagani_API36` Android emulator.

## Major Changes

- Replaced the old separate/blank video page with `CourseLearningScreen`: video stays at the top, and lesson summary, resources, quiz, and curriculum stay below it.
- Signed Bunny playback calls `POST https://merolaganiacademy.com/api/public/bunny/sign-playback`, loads the signed embed response, extracts the tokenized MP4/HLS media URL, and plays it through Flutter `video_player` with the required `Referer` header.
- The Bunny WebView player remains only as a fallback when a direct signed media URL cannot be extracted.
- Added native fullscreen controls and Android picture-in-picture through a Flutter platform channel.
- Added Previous/Next controls and lesson-switch scroll reset so selecting another lesson immediately returns the learner to the player, summary, and quiz.
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
- Signed in with a learner account and reproduced the earlier native HLS failure: the signed endpoint returned both `embedUrl` and `hlsUrl`, but Android ExoPlayer received HTTP 403 from the HLS URL.
- Updated playback selection to extract the tokenized media URL from the signed Bunny embed HTML and use native `video_player` with the required `Referer` header.
- Installed the final release APK, opened `Credit Course`, loaded native video playback, tapped play, and verified the frame advanced during playback.
- Verified `Next` switches to lesson 2, returns to the player/quiz area, and loads the next lesson's quiz.
- Verified fullscreen opens in landscape mode.
- Verified Android PiP enters pinned mode from the video player.
- Verified the app launches after adding `webview_flutter`.
- Checked logcat after navigation for Flutter render overflow, Android fatal exception, and ANR patterns.

Latest screenshots:

- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/17-release-home.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/18-release-courses.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/19-release-course-detail.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/20-release-learning.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/21-release-quiz-actions.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/22-playback-fix-signed-out-account.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/login-test/15-start-multi-tap.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/login-test/16-embed-after-play-5s.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/login-test/17-embed-after-play-13s.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/login-test/22-final-player-loaded.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/login-test/23-final-after-play-5s.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/login-test/24-final-after-play-13s.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/native-learning-flow/03-native-after-wait.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/native-learning-flow/04-native-after-play.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/native-learning-flow/06-native-next-ready-after-wait.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/player-controls/03-after-wait.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/player-controls/05-fullscreen-dismissed.png`
- `/Users/manish/Documents/Codex Project 1/outputs/merolagani-academy-apk/screenshots/player-controls/06-after-pip-tap.png`

## Important Remaining Blockers

No release-blocking playback issue is currently open after the native signed-media extraction change. Final Play Store upload still needs a production signing keystore instead of the local debug signing fallback.

## Build Notes

- Package id: `com.meroverse.merolagani_academy`
- Version: `1.0.0+1`
- Minimum SDK: `24`
- Target SDK: `36`
- Cleartext traffic: disabled
- Android backup: disabled
- Android PiP: enabled on `MainActivity`
- Release builds use the debug signing config if `android/key.properties` is absent. Add a production keystore before Play Store upload.

Flutter currently warns that `shared_preferences_android`, `video_player_android`, and `webview_flutter_android` apply the Kotlin Gradle Plugin. This is a future Flutter compatibility warning, not a current build failure.
