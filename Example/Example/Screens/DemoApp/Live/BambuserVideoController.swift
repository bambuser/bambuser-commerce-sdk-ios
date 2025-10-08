//
//  BambuserVideoController.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-22.
//

import UIKit
import BambuserCommerceSDK

/// A view controller responsible for handling **product hydration** and cart interactions
/// using the Bambuser Commerce SDK.
final class BambuserVideoController: UIViewController, BambuserVideoPlayerDelegate, BambuserPictureInPictureDelegate {

    /// The player view used for displaying the video.
    var playerView: BambuserPlayerView?

    /// Navigation manager for handling navigation events within the app.
    let navManager: NavigationManager

    /// Navigation manager observer ID to identify view
    var navigationObserverID: UUID?

    /// The show ID for the live video.
    var showId: String

    init(navManager: NavigationManager, showId: String) {
        self.navManager = navManager
        self.showId = showId

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
            type: .live(id: showId), // Pass the show ID
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
        navigationObserverID = navManager.addPopObserver { [weak self] _, oldPath, newPath in
            guard let self = self else { return }

            if case .liveShow? = oldPath.last {
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

    /// This method demonstrates how to hydrate products and send product hydration info to the player.
    /// It retrieves product data and updates the player accordingly.
    func hydrate(data: [String: Sendable]) async throws {
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
            try await playerView?.invoke(
                function: "updateProductWithData",
                arguments: hydrationString
            )
        }
    }

    /// Hides the product list within the Bambuser player.
    private func hideProductList() {
        Task { @MainActor in
            /// Calling this function dismisses the product list if it's active.
            /// Example: If the user taps on the cart or product list, this will close it.
            try await playerView?.invoke(function: "hideProductList", arguments: "")
        }
    }

    /// Handles the event when a product is tapped.
    /// - Parameter data: The product data received from the event.
    private func productTapped(_ data: [String: Sendable]) {
        guard let _ = Product(data: data) else {
            print("Something went wrong with parsing product data!")
            return
        }
        hideProductList()
    }

    // MARK: - BambuserVideoPlayerDelegate

    /// Handles events received from the **Bambuser video player**.
    /// - This method is part of `BambuserVideoPlayerDelegate`.
    /// - Parameters:
    ///   - id: The ID of the player emitting the event.
    ///   - event: The event payload containing event details.
    func onNewEventReceived(_ id: String, event: BambuserEventPayload) {
        print("ProductHydrationViewController received event: \(event)")

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
            guard let callbackKey = event.data["callbackKey"] as? String,
                    let event = event.data["event"] as? [String: Sendable],
                  let sku = event["sku"] as? String else {
                return
            }
            var quantity = 1
            if let value = event["quantity"] as? Int {
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
                    self.playerView?.notify(
                        callbackKey: callbackKey,
                        info: "{ success: false, reason: 'out-of-stock' }"
                    )
                } else {
                    Storage.shared.updateCart(productId: sku, quantity: quantity)
                    /// Confirm the item was successfully added to the cart.
                    self.playerView?.notify(
                        callbackKey: callbackKey,
                        info: true
                    )
                }
            }
        }

        /// - The `"goto-checkout"` event is emitted when the user taps the **Checkout** button.
        /// - In this example, an alert is displayed to simulate the action.
        if event.type == "goto-checkout" {
            playerView?.pipController?.start()
            hideProductList()
            navManager.switchTo(.cart)
        }

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
                        let base = String(sku.prefix { $0 != "-" }).trimmingCharacters(in: .whitespaces)
                        statusDict[sku] = Storage.shared.wishlist[base] ?? false
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
            let base = String(sku.prefix { $0 != "-" }).trimmingCharacters(in: .whitespaces)
            Storage.shared.addToWishlist(productId: base)

            /// Simulate a network call or processing delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                Storage.shared.addToWishlist(productId: base)
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
            let base = String(sku.prefix { $0 != "-" }).trimmingCharacters(in: .whitespaces)
            Storage.shared.removeFromWishlist(productId: base)

            /// Once host app finished processing the request, e.g a network call,
            /// it should notify the player of the result.
            self.playerView?.notify(
                callbackKey: callbackKey,
                info: "{success: true, sku:'\(sku)'}"
            )
        case openWishlist:
            playerView?.pipController?.start()
            hideProductList()
            navManager.switchTo(.wishlist)
            /// Update here to present wishlist view
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
                print("Track response: \(String(describing: resposne))")
            }
        }
    }

    /// Handles errors that occur within the **Bambuser video player**.
    /// - This method is part of `BambuserVideoPlayerDelegate`.
    /// - Parameters:
    ///   - id: The ID of the player where the error occurred.
    ///   - error: The error object containing details about the issue.
    func onErrorOccurred(_ id: String, error: Error) {
        print("ProductHydrationViewController error: \(error.localizedDescription)")
    }

    func onVideoStatusChanged(_ id: String, state: BambuserCommerceSDK.BambuserVideoState) {
        print("Video state changed to: \(state)")
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
        print("PiP state changed to: \(state)")

        if state == .restored {
            /// When PiP is restored (e.g. user taps "Go to full screen"), we navigate
            /// back to the video player screen and resume playback.
            /// This ensures the player is visible and active after PiP ends.
            navManager.switchTo(.live)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.playerView?.play()
            }
        }
    }
}
