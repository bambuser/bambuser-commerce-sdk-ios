//
//  WishlistViewController.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-18.
//

import UIKit
import BambuserCommerceSDK

/// A view controller responsible for handling **wishlist** interactions
/// using the Bambuser Commerce SDK.
final class WishlistViewController: UIViewController, BambuserVideoPlayerDelegate {

    /// The player view used for displaying the video.
    var playerView: BambuserPlayerView?

    /// Navigation manager for handling navigation events within the app.
    let navManager: NavigationManager

    /// Navigation manager observer ID to identify view
    var navigationObserverID: UUID?

    /// Local dictionary to track wishlist status for SKUs
    /// - Key: SKU (product reference)
    /// - Value: Boolean indicating if the product is in the wishlist
    var wishlistStatus: [String: Bool] = [:]

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
        /// - `events`: Specifies which events app expects to receive from SDK.
        /// - `configuration`: Provides additional player settings.
        ///
        /// **Note:** Product hydration functionality **will not work** without `"currency"` and `"locale"` correctly set up.
        ///
        /// More information: [Bambuser Player API Reference](https://bambuser.com/docs/live/player-api-reference/)
        let config = BambuserVideoConfiguration(
            type: .live(id: Show.ShowsWithId.liveFunctions.id), // Pass the show ID
            events: ["*"], // Pass `["*"]` to receive **all available events** from the SDK.
            configuration: [
                "buttons": [
                    "dismiss": "none"
                ],
                "autoplay": true,
                "currency": "USD", // Defines the currency for product hydration
                "locale": "en-US" // Defines the locale for content formatting
            ]
        )

        /// Creates a player view with the specified configuration and adds it to the view hierarchy.
        let pView = bambuserPlayer.createPlayerView(
            videoConfiguration: config,
            ignoredSafeAreaEdges: .init(.bottom)
        )
        pView.delegate = self // Assigns the delegate to receive BambuserVideoPlayerDelegate events.
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

            if oldPath.last == .wishlist {
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

        /// Initialize wishlistStatus for all SKUs in ProductHydrationDataSource
        /// Mocking wishlist status for demonstration purposes.
        /// In a real application, this data would typically be fetched from a backend service or local
        for sku in ProductHydrationDataSource.sampleProducts.keys {
            if sku == "436775" {
                wishlistStatus[sku] = true
            } else {
                wishlistStatus[sku] = false
            }
        }
    }

    deinit {
        navManager.removePopObserver(navigationObserverID)
    }

    // MARK: - BambuserVideoPlayerDelegate

    /// Handles events received from the **Bambuser video player**.
    /// - This method is part of `BambuserVideoPlayerDelegate`.
    /// - Parameters:
    ///   - id: The ID of the player emitting the event.
    ///   - event: The event payload containing event details.
    func onNewEventReceived(_ id: String, event: BambuserEventPayload) {
        print("WishlistViewController received event: \(event)")

        /// Wishlist event types determines the action to take.
        let openWishlist = "open-wishlist"
        let openWishlistLogin = "open-wishlist-login"
        let removeFromWishlist = "remove-from-wishlist"
        let provideWishlistStatus = "provide-wishlist-status"
        let addToWishlist = "add-to-wishlist"

        switch event.type {
        case provideWishlistStatus:
            /// Handles the `provide-wishlist-status` event from the player.
            ///
            /// The event payload contains a list of products for which the player requests wishlist status.
            /// The app should respond by providing a JSON string mapping product SKUs to their wishlist status.
            var statusDict: [String: Bool] = [:]
            if let eventDict = event.data["event"] as? [String: Any],
               let products = eventDict["products"] as? [[String: Any]] {
                for product in products {
                    if let sku = product["ref"] as? String {
                        statusDict[sku] = wishlistStatus[sku] ?? false
                    }
                }
            }
            do {
                /// Encode the wishlist status dictionary to JSON
                /// and send it to the player view using `invoke` to update the wishlist status on products.
                let wrapped = ["statuses": statusDict]
                let data = try JSONEncoder().encode(wrapped)
                if let jsonString = String(data: data, encoding: .utf8) {
                    Task {
                        try? await playerView?.invoke(
                            function: "updateWishlistStatus",
                            arguments: jsonString
                        )
                    }
                }
            } catch {
                print("Failed to encode wishlist status: \(error)")
            }
        case addToWishlist:
            /// Handles the `add-to-wishlist` event from the player.
            ///
            /// The event payload contains the SKU to add to the wishlist. The app should update its local
            /// wishlist status and notify the player of success.
            guard let callbackKey = event.data["callbackKey"] as? String,
                  let eventDict = event.data["event"] as? [String: Sendable],
                  let sku = eventDict["sku"] as? String else { return }
            wishlistStatus[sku] = true

            /// Simulate a network call or processing delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.playerView?.notify(
                    callbackKey: callbackKey,
                    info: "{success: true, sku:'\(sku)'}"
                )
            }
        case removeFromWishlist:
            /// Handles the `remove-from-wishlist` event from the player.
            ///
            /// The event payload contains the SKU to remove from the wishlist. The app should update its local
            /// wishlist status and notify the player of success.
            guard let callbackKey = event.data["callbackKey"] as? String,
                  let eventDict = event.data["event"] as? [String: Sendable],
                  let sku = eventDict["sku"] as? String else { return }
            wishlistStatus[sku] = false

            /// Once host app finished processing the request, e.g a network call,
            /// it should notify the player of the result.
            self.playerView?.notify(
                callbackKey: callbackKey,
                info: "{success: true, sku:'\(sku)'}"
            )
        case openWishlist:
            /// Handles the `open-wishlist` event from the player.
            ///
            /// The app can use this event to present its own wishlist UI when the player requests it.
            let alert = UIAlertController(title: "Wishlist", message: "Open Wishlist UI", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        case openWishlistLogin:
            /// Handles the `open-wishlist-login` event from the player.
            ///
            /// The app should present a login UI if required, and notify the player of the result.
            guard let callbackKey = event.data["callbackKey"] as? String else { return }
            let alert = UIAlertController(title: "Login Required", message: "Please log in to use wishlist.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.playerView?.notify(
                    callbackKey: callbackKey,
                    info: "{ success: true }"
                )
            }
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        default:
            break
        }
    }

    /// Handles errors that occur within the **Bambuser video player**.
    /// - This method is part of `BambuserVideoPlayerDelegate`.
    /// - Parameters:
    ///   - id: The ID of the player where the error occurred.
    ///   - error: The error object containing details about the issue.
    func onErrorOccurred(_ id: String, error: Error) {
        print("WishlistViewController error: \(error.localizedDescription)")
    }

    /// Handles video status changes from the Bambuser player.
    /// - Parameters:
    ///   - id: The ID of the player.
    ///   - state: The new video state.
    func onVideoStatusChanged(_ id: String, state: BambuserVideoState) {
        print("WishlistViewController video status changed: \(state)")
    }
}
