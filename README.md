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
        
        // Pass ["*"] to receive all events from the player
        events: ["*"],
        
        // Configuration settings for the player
        // More options can be found here: 
        // https://bambuser.com/docs/live/player-api-reference/
        configuration: [
            "buttons": ["dismiss": "none"], // Hides the dismiss button
            "autoplay": true // Enables autoplay when the player loads
        ]
    )
)
```

### Documentation

Documentation can be found in [here](https://github.com/bambuser/bambuser-commerce-sdk-ios/tree/main/Documentation/BambuserCommerceSDK-Docs.doccarchive)

---

> **Beta Release:**  
> This SDK is currently in beta, and its APIs may change before the final release.

> **Note:**  
> SwiftUI is not supported out of the box in this beta version; support will be added in the final release.
