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
- **iOS 15.6+** supported

### Installation

#### Swift Package Manager (SPM)

You can integrate the SDK using Swift Package Manager. Add the following dependency to your project:

```swift
dependencies: [
    .package(url: "https://github.com/bambuser/bambuser-commerce-sdk-ios", from: "0.1.0")
]
```

#### Manual Installation

If you prefer to integrate the SDK manually, follow these steps:

1. Download BambuserCommerceSDK.xcframework from [releases page](https://github.com/bambuser/bambuser-commerce-sdk-ios/releases/)
2. Drag and drop xcframework file to your project

### Setup

```swift

// Import the SDK
import BambuserCommerceSDK

// Initialize the Bambuser video player with the server region
// You can choose between .US or .EU based on your region
let videoPlayer = BambuserVideoPlayer(server: .US) // or .EU

let playerView = videoPlayer.createPlayerView(
    videoConfiguration: .init(
        type: .live(id: "xxx"),
        
        // List of events to listen to; use ["*"] for all events (currently only option available)
        events: ["*"],
        
        // Configuration settings for the player
        // More options can be found here: 
        // https://bambuser.com/docs/live/player-api-reference/
        configuration: [
            "buttons": [
                "dismiss": "none", // Hides the close button on the player.
                "product": "none", // Clicking on a product requires a listener for the "should-show-product-view" event to handle this interaction.
            ],
            "actionCard": "none", // Clicking on an action card requires a listener for the "action-card-clicked" eventmisformat to handle this interaction.
            "currency": "USD", // Sets the currency format for display.
            "locale": "en-US", // Defines the language and regional settings for the player interface.
            "autoplay": true // player will automatically play video when player is ready
        ]
    )
    playerView.delegate = self
)
```

### Delegate Protocol

The BambuserCommerceSDK provides the `BambuserVideoPlayerDelegate` protocol for handling communications from a Bambuser video player instance. By implementing this protocol, your class can receive callback messages when new events occur or errors are encountered.

#### Methods

- **onNewEventReceived**  
  Called when a new event is received from the video player.  
  **Parameters:**  
  - `playerId`: A unique identifier for the video player.  
  - `event`: A `BambuserEventPayload` containing the event type and associated data.

- **onErrorOccurred**  
  Called when an error occurs within the video player.  
  **Parameters:**  
  - `playerId`: A unique identifier for the video player.  
  - `error`: The error encountered by the video player.

#### Example Implementation

```swift
class ViewController: BambuserVideoPlayerDelegate {
    func onNewEventReceived(playerId: String, _ event: BambuserEventPayload) {
        // Handle the event, e.g., log or update UI
        print("Player \(playerId) sent event: \(event)")
    }

    func onErrorOccurred(playerId: String, _ error: Error) {
        // Handle the error, e.g., display an alert
        print("Error in player \(playerId): \(error.localizedDescription)")
    }
}
```

### Conversion Tracking
To track conversions within the BambuserCommerceSDK, utilize the track function provided by the BambuserPlayerView. This function transmits necessary data sets to Bambuser Analytics.

#### Method
#### `track(event: String, with data: [String: Any]) -> [String: Any]`

- **Parameters:**
  - `event`: *(String)* – The name of the event to track (e.g., `"purchase"`).
  - `data`: *(Dictionary)* – A dictionary containing additional information related to the event.

- **Returns:**  
  A dictionary representing the complete **data payload** sent to **Bambuser tracking**.

#### Example Implementation

```swift
let response = try? await self.playerView.track(
    event: "purchase", 
    with: [
        "orderId": "12345", // the order id (String)
        "orderValue": "12345", // total of all products in the order (Number or String of numbers)
        "orderProductIds": "11,22,33,44,55", // comma-separated string, or array of all product ids in the order
        "currency": "USD"
]
```

#### NOTE
To log an event, you must supply and include additional data as a dictionary with string keys and values of any type ([String: Any?]). Note that the example format is for illustrative purposes only. For the precise data structure required for each event, please refer to our detailed documentation. 


### Documentation

Documentation can be found in [here](https://github.com/bambuser/bambuser-commerce-sdk-ios/tree/main/Documentation/BambuserCommerceSDK-Docs.doccarchive)

---

> **Beta Release:**  
> This SDK is currently in beta, and its APIs may change before the final release.
