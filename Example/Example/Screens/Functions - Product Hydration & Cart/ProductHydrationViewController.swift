//
//  ProductHydrationViewController.swift
//  Example
//
//  Created by Saeid Basirnia on 3/18/25.
//

import UIKit
import BambuserCommerceSDK

/// A view controller responsible for handling **product hydration** and cart interactions
/// using the Bambuser Commerce SDK.
final class ProductHydrationViewController: UIViewController, BambuserVideoPlayerDelegate {

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
        /// - `events`: Specifies which events app expects to receive from SDK.
        /// - `configuration`: Provides additional player settings.
        ///
        /// **Note:** Product hydration functionality **will not work** without `"currency"` and `"locale"` correctly set up.
        ///
        /// More information: [Bambuser Player API Reference](https://bambuser.com/docs/live/player-api-reference/)
        let config = BambuserVideoConfiguration(
            type: .live(id: "rks6lVf4Xwa9wuuMFaQv"), // Pass the show ID
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

            if oldPath.last == .productHydration {
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
    func hydrate(data: [String: Any]) async throws {
        guard let event = data["event"] as? [String: Any],
              let products = event["products"] as? [[String: Any]] else { return }
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

    /// This method demonstrates how to hydrate products and send product hydration info to the player.
    /// The provided Builder function facilitates the programmatic construction of product data, enabling developers to structure information according to the specifications of the Bambuser SDK hydration format. This mechanism allows for the controlled and compliant assembly of product entities for integration with the Bambuser platform.
    /// The provided implementation of the client product model serves solely as a demonstrative example. Developers are instructed to adapt and reconstruct the codebase to align precisely with the specific requirements and intricacies of their unique client-side data structures and integration needs.
    func hydrateUsingProductBuilder(data: [String: Any]) async throws {
        guard let event = data["event"] as? [String: Any],
              let products = event["products"] as? [[String: Any]] else { return }
        for product in products {
            guard let sku = product["ref"] as? String,
                  let id = product["id"] as? String else { continue }

            // Fetch your own product details
            // Dummy function to fetch the details
            // - More information: [Bambuser Player API Reference](https://bambuser.com/docs/live/player-api-reference/)
            guard let productDetails = ProductHydrationDataSource.mockClientProduct(for: sku)
            else { continue}

            let hydratedProduct = try HydratedProduct(sku: productDetails.sku)
                .withName(productDetails.productName)
                .withBrandName(productDetails.brand)
                .withVariations(
                        productDetails.variations.map { variation in
                            try Variation()
                                .withSku(variation.sku)
                                .withColorName(variation.colorName)
                                .withName(variation.name)
                                .withImageUrls(variation.imageUrls)
                                .withSizes(
                                    variation.sizes.map { size in
                                        try ProductSize()
                                            .withSku(size.sku)
                                            .withCurrentPrice(size.current)
                                            .withInStock(size.inStock)
                                            .withName(size.name)
                                            .build()
                                    }
                                )
                                .build()
                        }
                )
                .build()
             //
            let hydrationString = "'\(id)', \(try hydratedProduct.toJSON())"


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
                try await self.hydrateUsingProductBuilder(data: event.data)
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
            if let event = event.data["event"] as? [String: Any],
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
                    self.playerView?.notify(
                        callbackKey: callbackKey,
                        info: "{ success: false, reason: 'out-of-stock' }"
                    )
                } else {
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
            let alert = UIAlertController(title: "", message: "Navigate to checkout screen!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
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
}
