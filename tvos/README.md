# oneAnime Native tvOS

Flutter does not provide an official Apple tvOS target, so this folder contains a native Swift/tvOS companion project.

The project intentionally mirrors the tvOS direction from `yichengchen/ATV-Bilibili-demo`:

- tab-based TV navigation
- focusable collection grid cards
- large 10-foot typography
- AVKit playback

The data contracts come from this Flutter app:

- anime list: `https://d1zquzjgwo9yb.cloudfront.net/`
- anime detail page: `https://anime1.me/?cat=<id>`
- video source API: `POST https://v.anime1.me/api` with form body `d=<data-apireq>`
- playback headers: `User-Agent`, `Referer`, and filtered video cookies

Open `tvos/OneAnimeTV.xcodeproj` in Xcode and run the `OneAnimeTV` scheme on an Apple TV simulator or device.
