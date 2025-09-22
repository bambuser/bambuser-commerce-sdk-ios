//
//  ShoppableVideoViewController.swift
//  Example
//
//  Created by Seemanta on 2025-04-30.
//

import UIKit
import BambuserCommerceSDK

/// A view controller responsible for fetching and displaying a shoppable video playlist in a horizontal carousel.
///
/// This controller demonstrates how to fetch a playlist from Bambuser,
/// display it in a carousel, and handle video playback with autoplay support.
/// You can build your own custom UI based on this example or use the available APIs
/// to create your desired UI interface or behavior.
final class ShoppableVideoViewController: UIViewController {

    // MARK: - Properties

    private var shoppableVideo: BambuserPlayerView?
    var isAutoplayEnabled: Bool = true
    var navigationObserverID: UUID?
    let navManager: NavigationManager

    // MARK: - Layout/Animation State

    private var isExpanded = false
    private var compactConstraints: [NSLayoutConstraint] = []
    private var expandedConstraints: [NSLayoutConstraint] = []

    // MARK: - Initialization

    init(navManager: NavigationManager) {
        self.navManager = navManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        navManager.removePopObserver(navigationObserverID)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        fetchShoppableVideo()
        setupNavigationObserver()
    }

    // MARK: - Setup

    /// Sets up a navigation observer for the current view controller instance.
    /// When this view is popped from the navigation stack (specifically, when leaving the playlist),
    /// it ensures all shoppable video players are cleaned up and memory is released.
    ///
    /// This prevents memory leaks and ensures that no video continues playing in the background.
    /// The observer is removed once cleanup is performed to prevent duplicate calls or retain cycles.
    private func setupNavigationObserver() {
        navigationObserverID = navManager.addPopObserver { [weak self] oldPath, newPath in
            guard let self = self else { return }
            /// Cleans up the player view and releases associated resources.
            ///
            /// - Important: This **must** be called when the player view is no longer needed to ensure
            /// proper deinitialization and removal from memory. This includes stopping playback,
            /// releasing any retained resources, and unregistering navigation observers or other listeners.
            ///
            /// This method should be called at the appropriate point in the view lifecycle—typically
            /// when the view is being deallocated or is no longer visible. The exact timing depends
            /// on your project’s architecture. In UIKit, you might call this from `deinit`
            /// or `viewWillDisappear` and in SwiftUI, maybe the `.onDisappear` modifier.
            ///
            /// In this project, we have custom navigation flow and
            /// the `NavigationManager`, so it’s important to ensure `cleanup()` is called
            /// when the view is removed from the navigation stack.
            if oldPath.last == .shoppableVideo {
                shoppableVideo?.cleanup()
            }
        }
    }

    // MARK: - Data Fetching & Layout Setup

    /// Fetches a shoppable video playlist from Bambuser and populates the layout.
    private func fetchShoppableVideo() {
        let bambuserPlayer = BambuserVideoPlayer(server: .US)

        Task {
            do {
                /// Configures the Bambuser video player.
                /// - `type`: Specifies the video type and requires a valid show ID.
                /// - `events`: Specifies which events app expects to receive from SDK
                /// - `configuration`: Provides additional player settings.
                /// More information: [Bambuser Player Integration guide](https://bambuser.com/docs/shoppable-video/bam-playlist-integration/)
                let config = BambuserShoppableVideoConfiguration(
                    type: .videoId(Show.ShowsWithId.shoppableVideoSingleVideo.id),
                    events: ["*"],
                    configuration: [
                        "preload": false,
                        "thumbnail": [
                            "enabled": true,
                            "showPlayButton": true,
                            "contentMode": "scaleAspectFill",
                            "preview": nil
                        ],
                        /// Configuration for shoppable video player.
                        /// Hide products and title in the player.
                        "previewConfig": ["settings": "products:false; title:false; actions:1;"],
                        "playerConfig": [
                            "buttons": [
                                "dismiss": "event"
                            ],
                            "currency": "USD", // Defines the currency for product hydration
                            "locale": "en-US", // Defines the locale for content formatting
                            "autoplay": true
                        ]
                    ]
                )

                shoppableVideo = try await bambuserPlayer.createShoppableVideoPlayer(
                    videoConfiguration: config
                )
                shoppableVideo?.delegate = self
                /// Preloads the video content to prepare for playback.
                /// This step is important to ensure smooth playback when the user starts the video.
                /// Only use this if you have disabled `preload` in the configuration above.
                /// Otherwise, the video will be preloaded automatically.
                shoppableVideo?.preload()
                await MainActor.run {
                    setupPlayerView()
                }
            } catch {
                print("Error loading shoppable views: \(error)")
            }
        }
    }

    /// Adds the player and prepares two constraint sets:
    /// - compact: centered, 50% of safe-area width & height
    /// - expanded: pinned to safe-area edges (full screen)
    private func setupPlayerView() {
        guard let shoppableVideo else { return }

        let safe = view.safeAreaLayoutGuide

        shoppableVideo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shoppableVideo)

        // Compact constraints (centered, proportional size)
        let compact = [
            shoppableVideo.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            shoppableVideo.centerYAnchor.constraint(equalTo: safe.centerYAnchor),
            shoppableVideo.widthAnchor.constraint(equalTo: safe.widthAnchor, multiplier: 0.5),
            shoppableVideo.heightAnchor.constraint(equalTo: safe.heightAnchor, multiplier: 0.5)
        ]

        // Expanded constraints (full-screen within safe area)
        let expanded = [
            shoppableVideo.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            shoppableVideo.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            shoppableVideo.topAnchor.constraint(equalTo: safe.topAnchor),
            shoppableVideo.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ]

        compactConstraints = compact
        expandedConstraints = expanded

        NSLayoutConstraint.activate(compactConstraints)
        isExpanded = false
        view.layoutIfNeeded()
    }

    func switchMode(to mode: InlinePlayerMode) {
        animatePlayerView(expanded: mode == .fullExperience)
        shoppableVideo?.pipController?.isEnabled = mode == .fullExperience
        Task { @MainActor in
            try await shoppableVideo?.changeMode(to: mode)
        }
    }

    /// Toggle between compact and expanded constraint sets.
    private func animatePlayerView(expanded: Bool) {
        guard shoppableVideo != nil else { return }

        if expanded == isExpanded { return }

        NSLayoutConstraint.deactivate(expanded ? compactConstraints : expandedConstraints)
        NSLayoutConstraint.activate(expanded ? expandedConstraints : compactConstraints)

        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)

        isExpanded = expanded
    }

    /// This method demonstrates how to hydrate products and send product hydration info to the player.
    /// It retrieves product data and updates the player accordingly.
    private func hydrate(data: [String: Sendable]) async throws {
        guard let event = data["event"] as? [String: Sendable],
              let products = event["products"] as? [[String: Sendable]] else { return }
        for product in products {
            guard let sku = product["ref"] as? String,
                  let id = product["id"] as? String,
                  let jsonString = ProductHydrationDataSource.jsonObjectString(for: sku) else { continue }
            let hydrationString = "'\(id)', \(jsonString)"

            /// This is how to invoke **player functions**.
            /// - For example, to send **product hydration data** to the player, the `"updateProductWithData"` function is used.
            /// - This method requires:
            ///   - A **player function name** (e.g., `"updateProductWithData"`).
            ///   - **Arguments** required by the function.
            /// - More information: [Bambuser Player API Reference](https://bambuser.com/docs/live/player-api-reference/)
            ///
            /// **For product hydration, please refer to the format used in this function and `hydrationString`.**
            try await shoppableVideo?.invoke(
                function: "updateProductWithData",
                arguments: hydrationString
            )
        }
    }
}

// MARK: - BambuserVideoPlayerDelegate

extension ShoppableVideoViewController: BambuserVideoPlayerDelegate {

    /// Handles events received from the Bambuser video player.
    ///
    /// - Parameters:
    ///   - id: The ID of the player emitting the event.
    ///   - event: The event payload containing event details.
    func onNewEventReceived(_ id: String, event: BambuserCommerceSDK.BambuserEventPayload) {
        print("New event received from player [\(id)]: \(event)")

        // Example: Handle specific events
        /// If "preview-should-expand" event is received, switch to full experience mode.
        if event.type == "preview-should-expand" {
            /// When video is tapped, switch to full experience mode.
            /// This will allow the user to interact with the video in full-screen mode.
            /// Full experience mode is similar experience to the Bambuser Live Shopping player.
            guard shoppableVideo?.currentPlayerMode == .preview else {
                return
            }
            /// Important Note:
            /// To ensure a proper user experience, make sure the player view has a minimum size of 320x320 points for full experience mode.
            /// Otherwise, the player may not display correctly.
            /// Full experience mode is designed to provide a rich interactive experience and requires sufficient space to render the video and controls effectively.
            switchMode(to: .fullExperience)
            shoppableVideo?.play()
        }

        /// If "X" button is tapped, switch back to preview mode.
        if event.type == "close" {
            switchMode(to: .preview)
        }

        /// When the show starts, this event is triggered by the player.
        /// The event provides information on **all available products** during the show.
        /// The app can use this event to perform product hydration.
        ///
        /// **Check the `hydrate(data:)` method for an example of how to handle this.**
        if event.type == "provide-product-data" {
            Task {
                try await self.hydrate(data: event.data)
            }
        }

        /// Handles cart interactions such as adding or updating items.
        ///
        /// - The `"should-add-item-to-cart"` event is emitted when the **Buy** button is tapped and the product is **not already in the cart**.
        /// - The `"should-update-item-in-cart"` event is emitted when:
        ///   - The **Buy** button is tapped while the product is already in the cart.
        ///   - The product quantity is changed from the **cart page**.
        if event.type == "should-add-item-to-cart" || event.type == "should-update-item-in-cart" {
            guard let callbackKey = event.data["callbackKey"] as? String else {
                return
            }
            var quantity = -1
            if let event = event.data["event"] as? [String: Sendable],
               let value = event["quantity"] as? Int {
                quantity = value
            }

            /// Simulates a delay in processing the cart action.
            ///
            /// This mimics an asynchronous operation, such as an API call from the app to:
            /// - Send cart-related data to the backend.
            /// - Validate product availability, pricing, or other constraints.
            /// - Receive a response before updating the **Bambuser player**.
            ///
            /// Once the operation is complete, the app **must** update the player using the `notify` API.
            ///
            /// - Two scenarios are demonstrated here:
            ///   1. **Error Case**: If the requested quantity exceeds the limit (e.g., `> 3`),
            ///      the app simulates an "out-of-stock" error and notifies the player of failure.
            ///   2. **Success Case**: If the quantity is valid, the app confirms the item was added to the cart
            ///      and sends a success response to the player.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if quantity > 3 {
                    /// If the requested quantity is too high, simulate an out-of-stock error.
                    self.shoppableVideo?.notify(
                        callbackKey: callbackKey,
                        info: "{ success: false, reason: 'out-of-stock' }"
                    )
                } else {
                    /// Confirm the item was successfully added to the cart.
                    self.shoppableVideo?.notify(
                        callbackKey: callbackKey,
                        info: true
                    )
                }
            }
        }
    }

    /// Handles errors that occur within the Bambuser video player.
    ///
    /// - Parameters:
    ///   - id: The ID of the player where the error occurred.
    ///   - error: The error object containing details about the issue.
    func onErrorOccurred(_ id: String, error: any Error) {
        print("Player error [\(id)]: \(error.localizedDescription)")
    }

    /// Called whenever the playback status of a video changes.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the video.
    ///   - state: The new playback state for the video.
    ///
    /// When a video reaches the `.ended` state and autoplay is enabled,
    /// this method will start the next video in the playlist or carousel.
    func onVideoStatusChanged(_ id: String, state: BambuserVideoState) {
        print("Player status changed to: \(state)")
        if state == .ended {
            /// When the video is ended, switch back to preview mode, if player is in full experience mode.
            guard shoppableVideo?.currentPlayerMode == .fullExperience else {
                return
            }
            switchMode(to: .preview)
        }
    }

    /// Reports the playback progress of a video.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the video.
    ///   - duration: The total duration of the video, in seconds.
    ///   - currentTime: The current playback time, in seconds.
    ///
    /// This is an **optional** delegate method.
    /// You can implement this if you want to monitor the progress of the playing video,
    /// for example to update a UI progress bar or trigger custom actions when certain thresholds are reached.
    ///
    /// In this implementation, the method checks if there is exactly 1 second left in the video and,
    /// if so, automatically advances to play the next video in the playlist.
    func onVideoProgress(_ id: String, duration: Double, currentTime: Double) {
//        print("Video progress for player [\(id)]: duration=\(duration), currentTime=\(currentTime)")
    }
}
