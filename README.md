# BambuserCommerceSDK

---

## Overview

BambuserCommerceSDK is a lightweight SDK for integrating Bambuser video player and commerce experience into your iOS applications in order to enhance your app with interactive video commerce features that streamline the video shopping experience.

---

## Getting Started

## Requirements

This SDK is built using **Xcode 16** with the **Swift 6** toolchain but remains **compatible with Swift 5**. Ensure you have the correct version installed for compatibility.

- **Xcode 16** (or later)
- **Swift 5** toolchain
- **iOS 14+** supported

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
    .package(url: "https://github.com/bambuser/bambuser-commerce-sdk-ios", branch: "2.0.0-beta")
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

// Initialize the Bambuser video player with the server region
let videoPlayer = BambuserVideoPlayer(server: .US) // or .EU

let playerView = videoPlayer.createPlayerView(
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
let result = try await bambuserPlayer.createShoppableVideoPlayerCollection(
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
    pageId: "xxx",
    playlistId: "xxx",
    title: "xxx"
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
let result = try await bambuserPlayer.createShoppableVideoPlayerCollection(
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

let view = try await bambuserPlayer.createShoppableVideoPlayer(
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

### Delegate Protocol

The BambuserCommerceSDK provides the `BambuserVideoPlayerDelegate` protocol for handling communications from a Bambuser video player instance. By implementing this protocol, your class can receive callback messages when new events occur or errors are encountered.

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

#### Example Implementation

```swift
class ViewController: BambuserVideoPlayerDelegate {
    func onNewEventReceived(id: String, event: BambuserEventPayload) {
        print("Player \(id) sent event: \(event)")
    }

    func onErrorOccurred(id: String, error: Error) {
        print("Error in player \(id): \(error.localizedDescription)")
    }

    func onVideoStatusChanged(_ id: String, state: BambuserVideoState) {
        print("Player \(id) changed state to: \(state)")
    }

    func onVideoProgress(_ id: String, duration: Double, currentTime: Double) {
        print("Player \(id) progress: \(currentTime)/\(duration) seconds")
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
let pipController = playerView.pictureInPictureController

// Enable PiP (if not already enabled)
pipController.isEnabled = true

// Start PiP
pipController.start()

// Stop PiP
pipController.stop()
```

#### Notes

- PiP is **enabled by default** for **live** and **pre-recorded** videos.
- PiP is **disabled by default** for **shoppable videos**.
- Make sure to set `isEnabled` appropriately before calling `start()` or before PiP mode starts automatically.

### Tracking

To track conversions and other user actions within the BambuserCommerceSDK, utilize the track function provided by the BambuserPlayerView. This function transmits necessary data sets to Bambuser Analytics.

#### Method

#### `track(event: String, with data: [String: Sendable]) -> [String: Sendable]`

- **Parameters:**
  - `event`: *(String)* – The name of the event to track (e.g., `"purchase"`).
  - `data`: *(Dictionary)* – A dictionary containing additional information related to the event.

- **Returns:**  
  A dictionary representing the complete **data payload** sent to **Bambuser tracking**.

#### Example Implementation

```swift
let response = try? await self.playerView.track(
    event: "purchase", // Find events in our https://bambuser.com/docs, 
    with: [
        // Your metadata here
    ]
)
```

#### NOTE

To log an event, you must supply and include additional data as a dictionary with string keys and values of any type (`[String: Sendable]`).\
*Note that the example format is for illustrative purposes only. For the precise data structure required for each event, please refer to our [detailed documentation](https://bambuser.com/docs/live/conversion-tracking/).*

### Documentation

- Player documentation can be found in the [player api reference](https://bambuser.com/docs/live/player-api-reference/)
- Shoppable videos documentation can be found in the [Bambuser Player Integration guide](https://bambuser.com/docs/shoppable-video/bam-playlist-integration/)
- SDK code level documentation is available [here](https://github.com/bambuser/bambuser-commerce-sdk-ios/tree/main/Documentation/BambuserCommerceSDK-Docs.doccarchive)

---
