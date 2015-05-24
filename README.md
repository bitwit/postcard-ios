#Postcard for iOS

This is an abandoned project that was formerly on the iOS App Store.
Changes from iOS7 to iOS8 had large impacts on the storyboard layouts and this the final state of the project as it was being ported to work with iOS8 layouts.
It is currently in a non-functional state.

## Configuration and building

1. `pod install`
2. Copy `keys.sample.h` to `keys.h` and enter your own credentials
3. Build

### Other notes

- Since this was a rewiring and reorganization of the project after iOS8, not everything is wired up
- The OAuth1 library used for Tumblr has issues. It really needed replacing
- There is also a pre-iOS8 version of this project that reflects that last built version in stores not provided here. I decided to share this version instead because:
    1. Not even the old version builds well when targeting the latest SDK
    2. I felt this version would be more useful to anyone who might actually be interested in trying to move it forward
    3. iOS8 is on a much more flexible layout system and had potential to become resolution agnostic

