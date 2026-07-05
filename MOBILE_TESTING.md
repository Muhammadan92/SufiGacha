# Mobile Device Testing Guide — Kareem's Manual Steps

Getting Seven Springs onto a real phone. **Android first** (no paid account
needed, ~30 minutes of setup); iOS after (requires the Apple Developer
enrollment from BACKEND_IMPLEMENTATION.md §0.1). Export templates are
already installed on this Mac (done 2026-07-05).

## Part A — Android (do this one first)

### A1. One-time setup (~30 min, mostly downloads)
1. Install Android Studio: `brew install --cask android-studio`, open it
   once, let the setup wizard install the default SDK.
2. In Android Studio: **Settings → Languages & Frameworks → Android SDK →
   SDK Tools tab** → check **Android SDK Command-line Tools**, **NDK (side
   by side)**, and **CMake** → Apply. Note the "Android SDK Location" path
   at the top (usually `~/Library/Android/sdk`).
3. Create the debug keystore (terminal):
   ```
   keytool -keyalg RSA -genkeypair -alias androiddebugkey \
     -keypass android -keystore ~/.android/debug.keystore \
     -storepass android -dname "CN=Android Debug" -validity 9999
   ```
   (If it says the file exists, you're already done.)
4. Tell Godot where everything is: open the editor (`godot -e --path .`),
   **Editor → Editor Settings → Export → Android**: set *Android SDK Path*
   to the SDK location from step 2 and *Debug Keystore* to
   `~/.android/debug.keystore` (user `androiddebugkey`, password `android`).

### A2. Phone setup (~2 min)
1. On the phone: **Settings → About phone → tap "Build number" 7 times**
   (unlocks Developer options).
2. **Settings → Developer options → enable "USB debugging."**
3. Plug the phone into the Mac; tap **Allow** on the phone's USB-debugging
   prompt.

### A3. Build & install (tell me when A1–A2 are done — I script the rest)
Once the SDK exists, I can add the Android export preset and build the APK
headlessly; installing is one command:
```
godot --headless --path . --export-debug "Android" build/android/sevensprings.apk
adb install -r build/android/sevensprings.apk
```
If `adb` isn't on PATH: `~/Library/Android/sdk/platform-tools/adb`.

### A4. What we're testing on device (the point of all this)
- **Touch**: every button reachable and comfortably tappable? Battle
  target-selection precise enough with a thumb?
- **Layout**: does the battle screen fit? Is text readable at arm's length?
- **Performance**: battle animations smooth? Any heat/battery drain?
- **Feel**: does a 20-minute couch session feel right?
Report findings raw — they become the mobile-polish backlog.

## Part B — iOS (later; needs the $99 Apple enrollment)
1. Install Xcode from the App Store (large download) and run
   `sudo xcodebuild -license accept`.
2. Complete BACKEND_IMPLEMENTATION.md §0.1 (Apple Developer Program).
3. In Xcode: **Settings → Accounts → add your Apple ID** (the enrolled one).
4. Tell me — I add the iOS export preset (bundle id from §0.1), export the
   Xcode project headlessly, and you open it in Xcode, select your phone,
   and press Run. First run requires trusting the developer profile on the
   phone (**Settings → General → VPN & Device Management**).

## Part C — Instant fallback (zero setup, works today)
The web build plays on the phone RIGHT NOW over your local network:
```
cd ~/sufiGacha && python3 -m http.server 8000 -d build/web
```
Then on the phone's browser: `http://<your-Mac's-IP>:8000` (find the IP in
System Settings → Wi-Fi → Details). Not a substitute for native testing
(no performance truth), but it answers the touch-layout questions
immediately.
