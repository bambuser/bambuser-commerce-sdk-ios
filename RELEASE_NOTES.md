# Release Notes

All notable changes to the Bambuser Commerce SDK for iOS.

---

## Unreleased (3.0.0)

This is a major release with breaking changes. See the [Migration Guide](README.md#migrating-from-2x-to-30) for upgrade instructions.

### Breaking Changes

- `BambuserVideoPlayer` renamed to `BambuserSDK`.
- `BambuserVideoPlayerDelegate` renamed to `BambuserPlayerViewDelegate`.
- `track(event:with:)` moved from player view to `BambuserSDK`.
- `PlayerError` removed — use `BambuserPlayerError`.
- Deprecated playlist API removed — use `componentId`.

### New

- Now requires **Xcode 26+** and **Swift 6.2** toolchain.

### Improvements

- Tracking can now be called from anywhere in your app — cart, product pages, checkout, without a player view.
- Improved error handling with a single, unified error type (`BambuserPlayerError`).
- Network errors now include the HTTP status code for easier debugging.
- Various performance and stability improvements.

---

## 2.3.1

### Bug Fixes

- Fixed a parsing issue when loading a single shoppable video by ID.

---

## 2.3.0

### New

- **Seek API** — Control video playback position with `seek(to:)`.
- Updated Shoppable Video APIs to align with the latest dashboard changes.

---

## 2.2.1

### Improvements

- General bug fixes and performance improvements.

---

## 2.2.0

### New

- **Playback Speed Control** — Adjust video playback rate.

### Improvements

- General bug fixes and performance improvements.

---

## 2.1.4

### Bug Fixes

- Fixed a bug that could cause UI glitches.

### Improvements

- General stability improvements.

---

## 2.1.3

### Improvements

- Added support for player completed state, improving end-of-video handling.

---

## 2.1.2

### Bug Fixes

- Fixed share link URL generation.
- Fixed player not reloading when play is requested after video has stopped.

---

## 2.1.1

### Improvements

- General stability improvements.

---

## 2.1.0

### New

- **Video Preloading** — Call `preload()` on player views to reduce startup latency.

### Improvements

- Bundle ID is no longer required for playlist page identification.

---

## 2.0.1

### New

- **Dynamic Font Sizes** — Player UI now adapts to the system accessibility text size.

### Bug Fixes

- Fixed incorrect sizing in scheduled live shows.
- Fixed issue with pagination

### Improvements

- General stability improvements.

---

## 2.0.0

### New

- **Shoppable Video Support** — Fetch and display shoppable video content from playlists, product SKUs, or individual video IDs.
- **Pagination** — Load shoppable video collections with page-based pagination.
- **Preview and Full-Experience Modes** — Toggle between inline preview and expanded video experience.
- **Video Progress Tracking** — New delegate method for real-time playback progress reporting.
- **SKU-based Video Loading** — Load videos associated with specific product SKUs.
- **Picture-in-Picture for Shoppable Videos** — PiP support extended to shoppable video players.

### Improvements

- Fixed memory leaks.
- Improved video progress reporting accuracy.

---

## 1.0.0

### New

- **Purchase Tracking API** — Track conversions and other events via Bambuser Analytics.

### Bug Fixes

- Fixed scaling issues on iPhones.

---

## 0.4.0

### New

- **Picture-in-Picture** — Full PiP support with callbacks and delegate events.

---

## 0.3.0

### New

- **Player Function Invocation** — Call internal player functions via `invoke(function:arguments:)`.
- **Purchase Tracking** — Initial tracking API and request/response handling.
- **Player Notifications** — Send notifications to the player via `notify(callbackKey:info:)`.

---

## 0.1.0

### Initial Release

- **Live Video Playback** — Play live and on-demand video streams.
- **Native Video Player** — Hardware-accelerated native video playback.
- **Event Communication** — Receive events and errors from the player via delegate callbacks.
