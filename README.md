# Social: HCI Design Project, Team 9 (Feature Finders)

A social media app that helps people spend less time on their phones. The app is only open for one hour a day, at the same time for everyone in a region. Everyone is online together, and the rest of the day nobody is posting, so there's nothing to miss.

Built with **SwiftUI** and run on iPhone with **[xtool](https://github.com/xtool-org/xtool)**.

## Progress check status

| Task | Status |
|---|---|
| Simple: scroll the feed and open a post | ✅ Working |
| Moderate: create a post | 🔜 Next |
| Complex: create and verify an account | 🔜 Next |

**Working now:** home feed, post detail (photo carousel, like, save, follow, comments, reply, like comments), profile with posts and saved grid, open hour info, and the open hour itself: the feed banner counts down the hour, and when it ends the whole app locks with a "Time for a pause" screen that counts down to the next open hour. For the demo, the open hour starts when the app launches; tap the *Open hour* banner to close it early and see the lock screen.

**Hardcoded data:** five sample users (Maya, Sam, Alex, Nina, Jordan) and their posts, comments, like counts, six bundled photos, the current user's profile, and the 2:00–3:00 PM open hour. Nothing is saved between launches.

## Running it on an iPhone

1. Install xtool by following the installation steps on its [GitHub page](https://github.com/xtool-org/xtool) (Linux, Windows via WSL, or macOS).
2. Run `xtool setup` once and sign in with your Apple ID.
3. Plug in the iPhone, unlock it, and tap **Trust**.
4. From this folder, run:
   ```
   xtool dev
   ```
   This builds the app and installs it on the phone.
5. The first time, on the iPhone go to **Settings → General → VPN & Device Management**, trust your Apple ID, and turn on **Developer Mode** if iOS asks for it.

## Project layout

```
Package.swift                  SwiftPM package (iOS 17+)
xtool.yml                      xtool config (bundle ID)
Sources/SocialApp/
  SocialApp.swift              App entry point and tab bar
  Theme.swift                  Colors from Figma, photo loading, shared UI pieces
  Model/Models.swift           Data types, FeedStore, hardcoded sample data
  Views/FeedView.swift         Home feed (simple task)
  Views/PostDetailView.swift   Post detail and comments
  Views/ProfileView.swift      Profile, saved posts, open hour info
  Views/OtherViews.swift       Lock screen (app closed), "coming next" placeholder tabs
  Resources/*.jpg              Sample photos
```

## Replacing the photos

The photos in `Resources/` are low-resolution stand-ins cropped from Figma screenshots. For sharper images, export the originals from Figma (select image → Export → JPG at 2x) and save them over the files with the **same names**: `park`, `coffee`, `pottery`, `picnic`, `coast`, `flowers`.
