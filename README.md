# Social · Feature Finders

An iOS photo community for multi-participant HCI testing on a shared iPhone. Accounts, posts, comment threads, likes, follows, saved posts, private conversations and votes persist in **one SQLite database on that installation**. Passwords are stored separately in the iOS Keychain. A second device has its own independent study dataset.

[video demonstration link](https://www.youtube.com/watch?v=0j9VgdKusfI)

## Sign in, switch or create an account

| Username | Password | Profile |
| --- | --- | --- |
| user1 | password1 | Maya Chen |
| user2 | password2 | Sam Rivera |
| user3 | password3 | Nina Park |
| user4 | password4 | Jordan Lee |
| user5 | password5 | Alex Shah |
| user6 | password6 | Iris Kim |
| user7 | password7 | Taylor Kim |
| user8 | password8 | Casey Brooks |
| user9 | password9 | Robin Ellis |

These public credentials are for the seeded study accounts. At login, enter a username or email, or expand **Study accounts** to fill a sample login. Choose **Create a new account** for a separate identity with its own password and an on-screen study verification code. Profiles use unique handles and emails. Profile → Switch account lets you sign in to another identity or return to one already authenticated on this installation. Log out removes that account from the quick switcher.

**Two-person walkthrough.** Sign in as Maya and publish a photo from the study gallery or iPhone Photos. Switch to Sam, open Maya’s post, comment, follow her, save the post, and send her a message. Switch back to Maya, reply to Sam’s comment, then open Messages → Sam. The post and thread are shared, while Sam’s save stays in his own profile. Tap the author of a post or comment to open their profile. On your own profile you can change your display name, bio and avatar color. Use the menu on an owned post to edit its caption or location, or delete it.

## Vote and experience a universal break

The designated one-hour slots begin at 14:00, 15:00 and 17:00 UTC. The initial slot is 14:00 UTC. Profile → Break displays the current interval in UTC and the account’s selected local zone. Each account gets one standing ballot. Submitting again replaces its choice. Totals are visible in the ballot. At midnight UTC the most popular slot becomes the new day’s schedule. A tie favors the current slot if it is tied, then the earliest tied slot. Skipping days or closing the app does not require a background job. The app resolves the schedule on its next clock check. All profiles on the device lock together even if their display time zones differ.

## Run from NixOS

Use a physical iPhone with iOS 16 or newer and a data-capable USB cable. Enable the host service with `services.usbmuxd.enable = true;` in your NixOS configuration, rebuild, unlock the phone, and tap Trust when prompted. Enable Developer Mode on the phone when iOS requests it.

1. Extract the complete ZIP and enter the Social folder. The shell uses your configured nixpkgs. With a direnv shell hook enabled, run `direnv allow`. Alternatively use `nix-shell`. If your configuration has no nixpkgs channel, use `nix-shell -I nixpkgs=channel:nixos-unstable`.
2. Run `swift --version` and `bin/doctor`. The manifests use Swift tools 5.8 so the Foundation-only tests can run on older compilers. The pinned xtool 1.24.0 Linux iOS workflow calls for Swift 6.4.x and Xcode 27.1. A 5.8 or 6.2 compiler can run the core tests, but choose the container below for deployment if your shell does not provide a matching compiler.
3. Download Xcode 27.1’s .xip from Apple. Run `xtool setup`, authenticate with your Apple development account and enter the archive path. The generated SDK and credentials belong to your local development environment. Verify with `swift sdk list`.
4. Change `bundleID` in xtool.yml to an identifier unique to your team. Run `idevice_id -l` and `xtool dev` from the project directory. Trust the developer profile on the iPhone if prompted, then launch Social. On the first run choose a study login or create an account.

## Fallback when nixpkgs Swift and xtool disagree

The included Dockerfile fixes the host compiler at 6.4.2 and uses the same hash-checked xtool release as shell.nix. This route also avoids Linux binary-loader and AppImage FUSE issues. With Docker running and the host usbmuxd socket present, from Social:

```sh
docker build -t social-xtool .
docker volume create social-swift-home
docker run --rm -it \
  -v "$PWD:/project" -v social-swift-home:/root \
  -v /var/run/usbmuxd:/var/run/usbmuxd \
  -v "$HOME/Downloads:/downloads:ro" social-xtool
```

Inside the container run `xtool setup` (supply `/downloads/<your Xcode archive>.xip`), `bin/doctor`, then `xtool dev`. Reuse the same volume for subsequent sessions. Container builds may create root-owned .build files in the checkout. If USB is missing, check `idevice_id -l` on the host first and recreate the container after the host socket is available. Run setup and build in the same environment so both see the same SDK. If changing compiler versions, run `swift package clean` in the project.

## Walk through the three study tasks

| Task | Steps | Observable result |
| --- | --- | --- |
| Create and verify an account | Enter a name, username, email and password. Type the six digits displayed in the local study inbox. Pick an avatar or a photo, select a region, review and finish. | The profile shows the chosen identity. An incorrect code stays on verification. Logout and login use the stored local credentials. |
| Browse posts | On Home, search for Maya or scroll. Tap a photo, like a comment, add a reply, and go back. Save a post and visit Profile → Saved. | Search, replies, likes and saves update locally. |
| Publish | Open Post → Select photo. Choose the coffee cup → Next. Add a multiline caption and a suggested or custom location → Share post. | The new post appears first on Home and in Profile → My posts, including after relaunch. |

Signup verification uses a simulated inbox. For separate participant identities, create additional accounts. On upgrade, the app imports the previous single-account JSON archive, including posts, saves, comments, messages and the account’s vote. If a legacy username or email already occupies a seed identity, the seeded account receives an adjusted login shown in Study accounts.

## Demonstrate the lock without waiting until afternoon

Use a separate install with a different bundle ID (for example append .study). In Sources/Social/StudyConfiguration.swift set acceleratedBreak to true **before building**. Make the first successful login or finish signup on that installation. It gives the participant 20 seconds of browsing, locks all tabs for 60 seconds, then reopens automatically. The absolute start time persists across app restarts. Delete the demo install and reinstall to reset. The standard build always uses the daily UTC schedule. The accelerated build uses its timed schedule once per fresh install. The clock is device-local; the prototype has no server time authority or system-wide Screen Time enforcement.

## Verification

Run `swift test --package-path Core` and `bin/test-database` on Linux. The latter requires SQLite development headers and checks real database round trips, rollback, account isolation and legacy import. The tests cover exact onset and reopening, two DST-transition dates, two display regions, ballot replacement, UTC rollover, tie handling, and the timed demonstration. The study build should also be checked on the target iPhone:

- Start a draft before lockout. Open the photo picker or a post detail; verify that the lock takes over. Try Back and switching tabs.
- Background and relaunch during the break. Confirm the remaining time decreases and content reopens at the original deadline. Return to Post to recover the draft.
- Exercise onboarding with the keyboard, try an invalid code, then log out and back in. Check portrait photo access on device.
- Run the three flows above with the normal build outside its break and check Dynamic Type and VoiceOver on your test device.

## Sources

- [Team DP3 design](https://www.figma.com/design/UXlUjBbf98qJIeVGzlZASk/DP3?node-id=0-1). Visual references include the cream canvas, sage break banner, green actions, six photo assets, post composer, profile setup, vote and pause screens. DP2 supplied the shared-time concept; DP3 usability observations informed validation, editable multiline captions, location suggestions, search and comment likes.
- [xtool 1.24.0 Linux setup](https://github.com/xtool-org/xtool/blob/1.24.0/Documentation/xtool.docc/Installation-Linux.md) and [release binaries](https://github.com/xtool-org/xtool/releases/tag/1.24.0).
- [Swift](https://www.swift.org/install/linux/), [Apple SDK download](https://developer.apple.com/download/all/?q=Xcode), [SwiftUI](https://developer.apple.com/documentation/swiftui), [PhotosUI](https://developer.apple.com/documentation/photosui) and [Security](https://developer.apple.com/documentation/security).
- [NixOS](https://nixos.org/download/), [direnv](https://direnv.net/) and [Docker’s Swift image](https://hub.docker.com/_/swift). App code has no external Swift package dependencies.

