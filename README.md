# BambuserCommerceSDK

> **Beta Release:**  
> This SDK is currently in beta, and its APIs may change before the final release.

> **Note:**  
> SwiftUI is not supported out of the box in this beta version; support will be added in the final release.

---

## Overview

BambuserCommerceSDK is a lightweight SDK for integrating Bambuser video player and commerce experience into your iOS applications in order to enhance your app with interactive video commerce features that streamline the video shopping experience.

---

## Getting Started

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

1. **Delegate Implementation:**  
   Conform to `BambuserVideoPlayerDelegate` in your class to handle player events and errors.

2. **Initialize the Video Player:**  
   Create an instance of `BambuserVideoPlayer` with your `OrganizationServer` configuration.

3. **Create a Player View:**  
   Generate a player view using the `createPlayerView(videoConfiguration:ignoredSafeAreaEdges:)` method and embed it into your app’s UI.

```swift
// Example Usage
let organizationServer = OrganizationServer(/* Your configuration */)
let videoPlayer = BambuserVideoPlayer(server: organizationServer)
let videoConfiguration = BambuserVideoConfiguration(/* Your configuration */)
let playerView = videoPlayer.createPlayerView(videoConfiguration: videoConfiguration)
```

### Documentation

Documentation can be found in [here](https://github.com/bambuser/bambuser-commerce-sdk-ios/tree/main/Documentation/BambuserCommerceSDK-Docs.doccarchive)
