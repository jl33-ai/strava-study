# Lockin

Strava for studying: an iOS app (SwiftUI, iOS 17+) for school kids and people sitting a big exam like the CFA. You record a study session the way a runner records a run, then share it, earn records and climb your club's leaderboard.

## What works

- **Onboarding**: pick school, a big exam (CFA, CPA, MCAT, the Bar, SAT) or just getting better. Your goals and subjects follow from that.
- **Record**: a focus clock that keeps running in the background and survives the app being killed. Tap "Got it" or "Missed" as you answer questions to get your pace, accuracy and splits every 10 questions. You get 25-minute blocks, pause and resume, and each time you leave the app mid-session counts as a phone pickup. The session can be minimised to a banner above the tab bar.
- **Save**: give it a title and notes, add up to 4 photos, choose who can see it and whether it counts toward club leaderboards. Personal records are worked out when you save.
- **Home feed**: your sessions alongside friends' sessions, with kudos, plus who is locked in right now and your week (hours against your goal, streak, each day).
- **Session detail**: stats, records, a splits chart and table, and delete.
- **You**: an exam countdown with the hours you still need each week (or progress toward your weekly goal), hours a week over 4 weeks, 3 months or 6 months, a 17-week streak calendar, time by subject, personal records, and settings.
- **Clubs**: a monthly 50-hour challenge plus smaller challenges, all tracked from your real sessions. There's a weekly leaderboard sorted by hours, questions or accuracy, and clubs to join, including a teacher's class club.

Everything is stored on the phone (`Documents/lockin.json`, with photos in `Documents/photos`). There is no backend yet, so the friends, live-now row, members and clubs are seeded in `Lockin/Model/Seed.swift`. Your own numbers are all real.

## Build

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate
open Lockin.xcodeproj
```

Tests:

```bash
xcodebuild -project Lockin.xcodeproj -scheme Lockin -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

To run on a device, set your team under Signing & Capabilities.

## Shipping to TestFlight

`./ship.sh` archives, exports, validates and uploads a build to the "Lockin: Study Tracker" record in App Store Connect (app 6823942435, team WR8US6FK26), using the App Store Connect API key in `~/.appstoreconnect/private_keys`. Raise `CURRENT_PROJECT_VERSION` in `project.yml` before each upload.
