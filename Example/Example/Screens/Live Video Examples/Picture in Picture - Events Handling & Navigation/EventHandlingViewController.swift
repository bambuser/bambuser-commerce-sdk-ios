//
//  EventHandlingViewController.swift
//  Example
//
//  Created by Saeid Basirnia on 3/17/25.
//

import UIKit
import BambuserCommerceSDK

/// A view controller responsible for handling events from the Bambuser Commerce SDK.
final class EventHandlingViewController: UIViewController, BambuserVideoPlayerDelegate, BambuserPictureInPictureDelegate {

    /// The player view used for displaying the video.
    var playerView: BambuserPlayerView?

    /// Navigation manager for handling navigation events within the app.
    let navManager: NavigationManager

    /// Navigation manager observer ID to identify view
    var navigationObserverID: UUID?

    init(navManager: NavigationManager) {
        self.navManager = navManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        /// Initializes the Bambuser player instance.
        /// - The `server` parameter determines whether the player connects to the US or EU server.
        let bambuserPlayer = BambuserVideoPlayer(server: .US)

        /// Configures the Bambuser video player.
        /// - `type`: Specifies the video type and requires a valid show ID.
        /// - `events`: Specifies which events app expects to receive from SDK
        /// - `configuration`: Provides additional player settings.
        /// More information: [Bambuser Player API Reference](https://bambuser.com/docs/live/player-api-reference/)
        let config = BambuserVideoConfiguration(
            type: .live(id: "rks6lVf4Xwa9wuuMFaQv"), // Pass the show ID
            events: ["*"], // Pass `["*"]` to receive **all available events** from the SDK.
            configuration: [
                "buttons": [
                    "dismiss": "none",
                    "product": "none" // Override default product tap behavior in Bambuser player; this triggers "should-show-product-view" event so you can handle it in your app.
                ],
                "autoplay": true
            ] // Pass required Bambuser Player configuration
        )

        /// Creates the player view using the `createPlayerView` method of `BambuserVideoPlayer`.
        /// - `videoConfiguration`: The configuration object created earlier, defining the player settings.
        /// - `ignoredSafeAreaEdges`: Determines which safe area edges should be ignored.
        ///   - Use `.init(.all)` to ignore all edges, making the player fullscreen.
        ///   - Use `.init(.bottom)`, `.init(.top)`, etc., to selectively ignore specific edges.
        ///   - Use `.init(.bottom, .top)`, etc., to ignore multiple specific edges.
        let pView = bambuserPlayer.createPlayerView(
            videoConfiguration: config,
            ignoredSafeAreaEdges: .init(.bottom)
        )
        pView.delegate = self // Assigns the delegate to receive BambuserVideoPlayerDelegate events.
        pView.pipController?.delegate = self // Assigns the picture in picture delegate to receive BambuserPictureInPictureDelegate events.
        pView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pView)

        NSLayoutConstraint.activate([
            pView.topAnchor.constraint(equalTo: view.topAnchor),
            pView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        playerView = pView

        /// Setup navigation observe id and pop behavior
        navigationObserverID = navManager.addPopObserver { [weak self] oldPath, newPath in
            guard let self = self else { return }

            if oldPath.last == .eventHandling {
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
                playerView?.cleanup()
            }
        }
    }

    deinit {
        navManager.removePopObserver(navigationObserverID)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stopPiPIfNeeded()
    }

    /**
     Checks whether Picture-in-Picture (PiP) mode is currently active for the specified player.
     */
    func checkIfPipEnabled(for player: BambuserPlayerView) -> Bool {
        player.pipController?.isActive ?? false
    }

    /// Stops Picture-in-Picture mode if it is active. This has no effect if PiP is not active.
    private func stopPiPIfNeeded() {
        playerView?.pipController?.stop()
    }

    /// Handles the event when a product is tapped.
    /// - Parameter data: The product data received from the event.
    private func productTapped(_ data: [String: Any]) {
        guard let product = Product(data: data) else {
            print("Something went wrong with parsing product data!")
            return
        }
        hideProductList()

        /// You have to call this to manually start PiP inside your app **when the player view loses focus**,
        /// e.g., navigating to another screen.
        ///
        /// - If the user has **"Start PiP Automatically"** enabled in iOS settings, PiP will **automatically start**
        ///   when triggered by the OS, requiring no additional work from the app (e.g., when the app goes to the background).
        playerView?.pipController?.start()
        navManager.navigate(to: .productDetail(product))
    }

    /// Hides the product list within the Bambuser player.
    private func hideProductList() {
        Task { @MainActor in
            /// Calling this function dismisses the product list if it's active.
            /// Example: If the user taps on the cart or product list, this will close it.
            try await playerView?.invoke(function: "hideProductList", arguments: "")
        }
    }

    // MARK: - BambuserVideoPlayerDelegate

    /// Handles events received from the Bambuser video player.
    /// - Parameters:
    ///   - id: The ID of the player emitting the event.
    ///   - event: The event payload containing event details.
    func onNewEventReceived(_ id: String, event: BambuserEventPayload) {
        /// This event is emitted when a user taps on a product card during a show.
        if event.type == "should-show-product-view" {
            productTapped(event.data)

            Task {
                let resposne = try? await self.playerView?.track(
                    event: "ecommerce:purchase",
                    with: [
                        "transaction": [
                            "id":"abcd",
                            "subtotal":70.99,
                            "currency":"USD",
                            "total":74.98,
                            "tax":14.2,
                            "shippingCost":3.99,
                            "shippingMethod":"Store pickup",
                            "coupon":"SUMMER_SALE",
                        ],
                        "products": [
                            [
                                "id":"314-7216-102",
                                "name":"Tennis Shoe Classic - Size 10",
                                "image":"https://example.com/images/314-7216-102.jpg",
                                "price":70.99,
                                "currency":"USD",
                                "quantity":1,
                                "brand":"Plausible Co.",
                                "category":"Footwear > Sports > Tennis",
                                "location":"https://example.com/products/314-7216"
                            ]
                        ]
                    ]
                )

                print("✅ tracking sent:", resposne)
            }
        }
        print("EventHandlingViewController received event: \(event)")
    }

    /// Handles errors that occur within the Bambuser video player.
    /// - Parameters:
    ///   - id: The ID of the player where the error occurred.
    ///   - error: The error object containing details about the issue.
    func onErrorOccurred(_ id: String, error: Error) {
        print("EventHandlingViewController error: \(error.localizedDescription)")
    }

    /// Handles changes to the Picture-in-Picture (PiP) state.
    ///
    /// This method is called whenever the PiP mode transitions to a new state. You can use this to respond
    /// appropriately depending on whether PiP was started, stopped, or restored.
    ///
    /// - Parameters:
    ///   - id: The ID of the Bambuser player associated with this state change.
    ///   - state: The new `PlayerPipState`, indicating the current PiP mode.
    ///
    /// You can handle specific states such as:
    /// - `.willStart`: Prepare your UI before PiP begins.
    /// - `.started`: PiP has successfully started—adjust UI and pause unnecessary updates.
    /// - `.willStop`: PiP is about to stop—prepare to restore full-screen UI.
    /// - `.stopped`: PiP has been closed—restore full player view.
    /// - `.restored`: The user tapped "Go to full screen" and PiP has ended—navigate back and resume playback.
    func onPictureInPictureStateChanged(_ id: String, state: PlayerPipState) {
        if state == .restored {
            /// When PiP is restored (e.g. user taps "Go to full screen"), we navigate
            /// back to the video player screen and resume playback.
            /// This ensures the player is visible and active after PiP ends.
            navManager.popTo(.eventHandling)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.playerView?.play()
            }
        }
    }

    func onVideoStatusChanged(_ id: String, state: BambuserCommerceSDK.BambuserVideoState) {
        // TODO: Add proper documentation
        print("EventHandlingViewController video status changed: \(state)")
    }
}
