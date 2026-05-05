# BambuserCommerceSDK

---

## Overview

BambuserCommerceSDK is a lightweight SDK for integrating Bambuser video player and commerce experience into your iOS applications in order to enhance your app with interactive video commerce features that streamline the video shopping experience.

---

## Getting Started

## Requirements

The Bambuser Commerce SDK for iOS supports all [Apple-supported](https://developer.apple.com/news/upcoming-requirements/) Xcode versions and is compatible with apps targeting iOS 15 or above.

> **Important: Version 3.0.0 contains breaking changes.** If you are upgrading from v2.x, see the [Migration Guide](#migrating-from-2x-to-30) below.

### Important

To ensure full functionality of the SDK, **you must add the `-ObjC` flag** to your app target:

1. Open your project in **Xcode**
2. Go to your target's **Build Settings**
3. Search for **"Other Linker Flags"**
4. Add `-ObjC` to the list of flags (if it's not already there)

> Failing to include this flag may result in missing functionality or runtime issues related to Objective-C symbol resolution.

### Installation

#### Swift Package Manager (SPM)

You can integrate the SDK using Swift Package Manager. Add the following dependency to your project:

```swift
dependencies: [
    .package(url: "https://github.com/bambuser/bambuser-commerce-sdk-ios", from: "3.0.0")
]
```

#### Manual Installation

If you prefer to integrate the SDK manually, follow these steps:

1. Download BambuserCommerceSDK.xcframework from [releases page](https://github.com/bambuser/bambuser-commerce-sdk-ios/releases/)
2. Drag and drop xcframework file to your project

### Player Initialization

The SDK provides flexible setup options so you can configure the player dynamically based on your needs � supporting **live**, **pre-recorded**, and **shoppable video**.

For complete examples and working integrations, check out our **example app** and the official **SDK documentation**.

#### Live / Pre-recorded Video

```swift
// Import the SDK
import BambuserCommerceSDK

// Initialize the Bambuser SDK with the server region
let bambuser = BambuserSDK(server: .US) // or .EU

let playerView = bambuser.createPlayerView(
    videoConfiguration: .init(
        type: .live(id: "xxx"),
        events: ["*"],
        configuration: [
            "buttons": [
                "dismiss": "none",
                "product": "none"
            ],
            "actionCard": "none",
            "currency": "USD",
            "locale": "en-US",
            "autoplay": true
        ]
    )
)
playerView.delegate = self
```

#### Shoppable Videos (SKU)

```swift
let videoContainerInfo = BambuserShoppableVideoSkuInfo(
    orgId: "xxx",
    sku: "xxx"
)

let config = BambuserShoppableVideoConfiguration(
    type: .sku(videoContainerInfo),
    events: ["*"],
    configuration: [
        "thumbnail": [
            "enabled": true,
            "showPlayButton": true,
            "showLoadingIndicator": false,
            "contentMode": "scaleAspectFill",
            "preview": nil // You can pass a custom image URL to use as thumbnail. Default thumbnail set in dashboard is used otherwise.
        ],
        "previewConfig": [:],
        "playerConfig": [
            "buttons": [
                "dismiss": "event",
                "product": "none"
            ]
        ]
    ]
)

// Load the first page of videos (default page = 1, pageSize = 15)
let result = try await bambuser.createShoppableVideoPlayerCollection(
    videoConfiguration: config,
    page: 1, // Pass value of page to fetch
    pageSize: 15
)

// Bind views to your UI
setupUI(for: result.players)

// Access pagination info
let currentPage = result.pagination.page
let totalPages = result.pagination.totalPages
let pageSize = result.pagination.pageSize
let totalItems = result.pagination.total
```

#### Shoppable Videos (Playlist)

```swift
let videoContainerInfo = BambuserShoppableVideoPlaylistInfo(
    orgId: "xxx",
    componentId: "xxx"
)

let config = BambuserShoppableVideoConfiguration(
    type: .playlist(videoContainerInfo),
    events: ["*"],
    configuration: [
        "thumbnail": [
            "enabled": true,
            "showPlayButton": true,
            "showLoadingIndicator": true,
            "contentMode": "scaleAspectFill",
            "preview": nil // You can pass a custom image URL to use as thumbnail. Default thumbnail set in dashboard is used otherwise.
        ],
        "previewConfig": ["settings": "products:false; title: false"],
        "playerConfig": [
            "buttons": [
                "dismiss": "event",
                "product": "none"
            ]
        ]
    ]
)

// Load the first page of videos (default page = 1, pageSize = 15)
let result = try await bambuser.createShoppableVideoPlayerCollection(
    videoConfiguration: config,
    page: 1, // Pass value of page to fetch
    pageSize: 15
)

// Bind views to your UI
setupUI(for: result.players)

// Access pagination info
let currentPage = result.pagination.page
let totalPages = result.pagination.totalPages
let pageSize = result.pagination.pageSize
let totalItems = result.pagination.total
```

#### Shoppable Video (Single Video ID)

```swift
let config = BambuserShoppableVideoConfiguration(
    type: .videoId("your_video_id"),
    events: ["*"],
    configuration: [
        "thumbnail": [
            "enabled": true,
            "showPlayButton": true,
            "showLoadingIndicator": true,
            "contentMode": "scaleAspectFill",
            "preview": nil // You can pass a custom image URL to use as thumbnail. Default thumbnail set in dashboard is used otherwise.
        ],
        "previewConfig": [:],
        "playerConfig": [
            "buttons": [
                "dismiss": "event",
                "product": "none"
            ]
        ]
    ]
)

let view = try await bambuser.createShoppableVideoPlayer(
    videoConfiguration: config
)

// Bind the returned view to your UI
setupUI(for: view)
```

#### Thumbnail Configuration

The `thumbnail` dictionary in the video configuration controls how the video placeholder (thumbnail) behaves before playback begins.

```swift
"thumbnail": [
    "enabled": true,                // If false, no thumbnail will be added at all.
    "showPlayButton": true,         // Displays a play button overlay. Hidden once the video is tapped to play.
    "showLoadingIndicator": true,   // Shows an activity spinner while the video is loading. Hidden when playback starts.
    "contentMode": "scaleAspectFill", // Defines how the thumbnail image fits inside the view.
    "preview": nil                  // Optional custom image URL. Defaults to the thumbnail set in the Bambuser dashboard if nil.
]
```

**contentMode values:**

- `"scaleToFill"` – Stretches the image to completely fill the view. May distort the aspect ratio.
- `"scaleAspectFit"` – Scales the image to fit within the view while maintaining its aspect ratio. May leave padding.
- `"scaleAspectFill"` – Scales the image to fill the view while maintaining aspect ratio. May crop edges.

### Player Configuration

The `previewConfig` and `playerConfig` sections allow you to customize the appearance and behavior of both the video preview and the player itself.

#### `previewConfig`

Controls how the player behaves and looks when the video is playing in **inline mode** (e.g. product visibility, action card visibility, etc.).

#### `playerConfig`

Defines in-player UI behavior such as buttons, actions, and overlays during **maximized mode**.

> For full details on all available options, refer to the [Documentation](#documentation) section below.

### Player Controls

The `BambuserPlayerView` provides methods for controlling video playback:

- **`play()`** – Starts or resumes video playback.
- **`pause()`** – Pauses the currently playing video.
- **`seek(to: TimeInterval)`** – Seeks to a specific time position in seconds. Only supported for shoppable and archived videos (no effect on live broadcasts).
- **`resetPlayer()`** – Resets the player to its initial state, stopping playback, seeking to the beginning, and re-initializing the thumbnail view.
- **`changeMode(to: InlinePlayerMode)`** – Changes the display mode of the player. Only applicable for shoppable video players.
- **`preload()`** – Preloads player resources to reduce startup latency.
- **`cleanup()`** – Releases resources associated with the video player and performs necessary cleanup.

#### Player Mode

Shoppable video players support two display modes via `InlinePlayerMode`:

- **`.preview`** – The player shows a thumbnail/preview state.
- **`.fullExperience`** – The player shows the full interactive video experience.

```swift
// Check the current mode
let mode = playerView.currentPlayerMode

// Switch to full experience
try await playerView.changeMode(to: .fullExperience)

// Reset back to preview
playerView.resetPlayer()
```

### Delegate Protocol

The BambuserCommerceSDK provides the `BambuserPlayerViewDelegate` protocol for handling communications from a Bambuser video player instance. By implementing this protocol, your class can receive callback messages when new events occur or errors are encountered.

#### Methods

- **onNewEventReceived**  
  Called when a new event is received from the video player.  
  **Parameters:**  
  - `id`: A unique identifier for the video player.  
  - `event`: A `BambuserEventPayload` containing the event type and associated data.

- **onErrorOccurred**  
  Called when an error occurs within the video player.  
  **Parameters:**  
  - `id`: A unique identifier for the video player.  
  - `error`: The error encountered by the video player.

- **onVideoStatusChanged**  
  Called when the playback state of the video changes (e.g., playing, paused, ended).  
  **Parameters:**  
  - `id`: A unique identifier for the video player.  
  - `state`: A `BambuserVideoState` enum value indicating the current playback state.

- **onVideoProgress**  
  Called to report playback progress of the video.  
  **Parameters:**  
  - `id`: A unique identifier for the video player.  
  - `duration`: The total duration of the video in seconds.  
  - `currentTime`: The current playback time in seconds.

- **onThumbnailTapped**  
  Called when the video thumbnail is tapped.  
  **Parameters:**  
  - `id`: A unique identifier for the video player associated with the tapped thumbnail.

#### Example Implementation

```swift
class ViewController: BambuserPlayerViewDelegate {
    func onNewEventReceived(_ id: String, event: BambuserEventPayload) {
        print("Player \(id) sent event: \(event)")
    }

    func onErrorOccurred(_ id: String, error: Error) {
        print("Error in player \(id): \(error.localizedDescription)")
    }

    func onVideoStatusChanged(_ id: String, state: BambuserVideoState) {
        print("Player \(id) changed state to: \(state)")
    }

    func onVideoProgress(_ id: String, duration: Double, currentTime: Double) {
        print("Player \(id) progress: \(currentTime)/\(duration) seconds")
    }

    func onThumbnailTapped(_ id: String) {
        print("Thumbnail tapped for player \(id)")
    }
}
```

### Picture-in-Picture (PiP)

The **BambuserCommerceSDK** provides Picture-in-Picture (PiP) support through the `PictureInPictureController` interface, available via each `BambuserPlayerView` instance. PiP allows video content to continue playing in a floating overlay while users interact with other parts of the app or their device.

#### Overview

The `PictureInPictureController` lets you control and monitor PiP mode.

- **`isEnabled`**  
  A `Bool` indicating whether PiP is allowed for the video container.  

- **`isActive`**  
  A `Bool` indicating whether PiP is currently active.

- **`delegate`**  
  An optional `BambuserPictureInPictureDelegate` to receive PiP state change callbacks.

#### Methods

- **`start()`**  
  Starts PiP mode programmatically, enabling the video to continue in a floating overlay.

- **`stop()`**  
  Stops PiP mode and removes the floating overlay.

#### Example

```swift
// Access the controller from your player view
let pipController = playerView.pipController

// Enable PiP (if not already enabled)
pipController?.isEnabled = true

// Start PiP
pipController?.start()

// Stop PiP
pipController?.stop()
```

#### Notes

- PiP is **enabled by default** for **live** and **pre-recorded** videos.
- PiP is **disabled by default** for **shoppable videos**.
- Make sure to set `isEnabled` appropriately before calling `start()` or before PiP mode starts automatically.

### Preloading

By default, the SDK **preloads videos** to reduce startup time when playback begins. This ensures a smoother user experience by minimizing delays when calling `play` on a video.

If you prefer to **disable automatic preloading**, you can set the `preload` flag to `false` in your video configuration:

```swift
"preload": false
```

When preloading is disabled, you can still manually preload specific videos by calling the `preload()` method on individual player instances. This is useful for cases like preloading only the next video in a sequence.

```swift
// Disable automatic preloading in configuration
let config = BambuserShoppableVideoConfiguration(
    type: .videoId("your_video_id"),
    events: ["*"],
    configuration: [
        "preload": false
    ]
)

let playerView = try await bambuser.createShoppableVideoPlayer(
    videoConfiguration: config
)

// Manually preload this video later
playerView.preload()
```

#### Notes
Once preloading is complete, the SDK will trigger the `onVideoStatusChanged` callback with the state `BambuserVideoState.ready`.
This means the video is fully preloaded and ready to start playing.

### Tracking

To track conversions and other user actions, use the `track` method on `BambuserSDK`. This can be called from anywhere in your app — no player view is required.

#### Method

#### `track(event: String, with data: [String: Sendable]) async throws -> [String: Sendable]?`

- **Parameters:**
  - `event`: *(String)* – The name of the event to track (e.g., `"purchase"`).
  - `data`: *(Dictionary)* – A dictionary containing additional information related to the event.

- **Returns:**  
  An optional dictionary representing the complete **data payload** sent to **Bambuser tracking**.

- **Throws:**  
  `BambuserPlayerError.failedToTrack` if the tracking operation fails.

#### Example Implementation

```swift
let bambuser = BambuserSDK(server: .US)

let response = try? await bambuser.track(
    event: "purchase", // Find events in our https://bambuser.com/docs, 
    with: [
        // Your metadata here
    ]
)
```

#### NOTE

To log an event, you must supply and include additional data as a dictionary with string keys and values of any type (`[String: Sendable]`).\
*Note that the example format is for illustrative purposes only. For the precise data structure required for each event, please refer to our [detailed documentation](https://bambuser.com/docs/live/conversion-tracking/).*

### Migrating from 2.x to 3.0

Version 3.0.0 is a major release with breaking changes. Follow the steps below to update your integration.

#### 1. Renamed Types

| Before (v2.x) | After (v3.0) |
|----------------|--------------|
| `BambuserVideoPlayer` | `BambuserSDK` |
| `BambuserVideoPlayerDelegate` | `BambuserPlayerViewDelegate` |
| `PlayerError` | `BambuserPlayerError` |

#### 2. Tracking API Moved

`track(event:with:)` has moved from `BambuserPlayerView` to `BambuserSDK`. You no longer need a player view to track events — call it directly on the SDK instance from anywhere in your app.

```swift
// Before (v2.x)
let response = try await playerView.track(event: "purchase", with: data)

// After (v3.0)
let bambuser = BambuserSDK(server: .US)
let response = try await bambuser.track(event: "purchase", with: data)
```

#### 3. Deprecated Playlist API Removed

The `pageId`, `playlistId`, `title`, and `packageName` parameters have been removed from `BambuserShoppableVideoPlaylistInfo`. Use `componentId` instead.

```swift
// Before (v2.x)
let info = BambuserShoppableVideoPlaylistInfo(
    orgId: "xxx", pageId: "xxx", playlistId: "xxx", title: "xxx"
)

// After (v3.0)
let info = BambuserShoppableVideoPlaylistInfo(
    orgId: "xxx", componentId: "xxx"
)
```

---

### Documentation

- Player documentation can be found in the [player api reference](https://bambuser.com/docs/live/player-api-reference/)
- Shoppable videos documentation can be found in the [Bambuser Player Integration guide](https://bambuser.com/docs/shoppable-video/bam-playlist-integration/)
- SDK code level documentation is available [here](https://github.com/bambuser/bambuser-commerce-sdk-ios/tree/main/Documentation/BambuserCommerceSDK-Docs.doccarchive)

---
