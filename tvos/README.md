# oneAnime tvOS Host

This folder is a tvOS host scaffold copied from the iOS host so Apple TV work can happen without removing the existing iOS project.

Important details:

- `Runner.xcodeproj` targets `appletvos`, `TARGETED_DEVICE_FAMILY = 3`, and bundle id `com.example.oneanime.tvos`.
- `Flutter/Debug.xcconfig` and `Flutter/Release.xcconfig` pass `ONEANIME_TVOS=true` through `DART_DEFINES`.
- Dart code reads that flag through `AppPlatform.isTvOS` and avoids phone-only UI behavior such as portrait reset.
- The scaffold keeps the same Flutter entry point (`lib/main.dart`) and app features.

Before App Store packaging, replace the copied iOS icon catalog with proper layered tvOS app icon and top shelf assets.
