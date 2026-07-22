//
//  ShoppableVideoEventRouter.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import UIKit
import BambuserCommerceSDK

@MainActor
final class ShoppableVideoEventRouter: NSObject {
    private weak var navManager: NavigationManager?
    private var players: [BambuserPlayerView] = []

    weak var presenter: UIViewController?

    var onStateChanged: ((String, BambuserVideoState) -> Void)?
    var onProgress: ((String, Double, Double) -> Void)?
    var onThumbnailTapped: ((String) -> Void)?
    var onPreviewShouldExpand: ((String) -> Void)?

    init(navManager: NavigationManager) {
        self.navManager = navManager
    }

    func bind(_ players: [BambuserPlayerView]) {
        self.players = players
        for p in players {
            p.delegate = self
            p.pipController?.isEnabled = true
            p.pipController?.delegate = self
        }
    }

    private func player(with id: String) -> BambuserPlayerView? {
        players.first { $0.id == id }
    }

    private func hydrate(data: [String: Sendable], for player: BambuserPlayerView) async throws {
        guard let event = data["event"] as? [String: Sendable],
              let products = event["products"] as? [[String: Sendable]] else { return }
        for product in products {
            guard let ref = product["ref"] as? String,
                  let id = product["id"] as? String,
                  let jsonString = ProductHydrationDataSource.jsonObjectString(for: ref) else { continue }
            let hydrationString = "'\(id)', \(jsonString)"
            try await player.invoke(function: "updateProductWithData", arguments: hydrationString)
        }
    }

    private func hideProductList(on player: BambuserPlayerView) {
        Task { @MainActor in
            try? await player.invoke(function: "hideProductList", arguments: "")
        }
    }

    private func handleProvideWishlistStatus(player: BambuserPlayerView, data: [String: Sendable]) {
        var statusDict: [String: Bool] = [:]
        if let eventDict = data["event"] as? [String: Any],
           let products = eventDict["products"] as? [[String: Any]] {
            for product in products {
                if let sku = product["ref"] as? String {
                    let base = String(sku.prefix { $0 != "-" }).trimmingCharacters(in: .whitespaces)
                    statusDict[sku] = Storage.shared.wishlist[base] ?? false
                }
            }
        }
        do {
            let wrapped = ["statuses": statusDict]
            let data = try JSONEncoder().encode(wrapped)
            if let jsonString = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    try? await player.invoke(function: "updateWishlistStatus", arguments: jsonString)
                }
            }
        } catch {
            print("Failed to encode wishlist status: \(error)")
        }
    }

    private func handleAddToWishlist(player: BambuserPlayerView, data: [String: Sendable]) {
        guard let callbackKey = data["callbackKey"] as? String,
              let eventDict = data["event"] as? [String: Sendable],
              let sku = eventDict["sku"] as? String else { return }
        let base = String(sku.prefix { $0 != "-" }).trimmingCharacters(in: .whitespaces)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            Storage.shared.addToWishlist(productId: base)
            player.notify(callbackKey: callbackKey, info: "{success: true, sku:'\(sku)'}")
        }
    }

    private func handleRemoveFromWishlist(player: BambuserPlayerView, data: [String: Sendable]) {
        guard let callbackKey = data["callbackKey"] as? String,
              let eventDict = data["event"] as? [String: Sendable],
              let sku = eventDict["sku"] as? String else { return }
        let base = String(sku.prefix { $0 != "-" }).trimmingCharacters(in: .whitespaces)
        Storage.shared.removeFromWishlist(productId: base)
        player.notify(callbackKey: callbackKey, info: "{success: true, sku:'\(sku)'}")
    }

    private func handleOpenWishlistLogin(player: BambuserPlayerView, data: [String: Sendable]) {
        guard let callbackKey = data["callbackKey"] as? String, let presenter else { return }
        let alert = UIAlertController(
            title: "Login Required",
            message: "Please log in to use wishlist.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            player.notify(callbackKey: callbackKey, info: "{ success: true }")
        })
        presenter.present(alert, animated: true)
    }

    private func switchTab(to tab: Tab, from player: BambuserPlayerView) {
        player.pipController?.start()
        hideProductList(on: player)
        navManager?.switchTo(tab)
    }
}

extension ShoppableVideoEventRouter: BambuserPlayerViewDelegate {
    func onNewEventReceived(_ id: String, event: BambuserEventPayload) {
        guard let player = player(with: id) else { return }

        switch event.type {
        case "action-card-clicked", "open-url":
            if let eventDict = event.data["event"] as? [String: Sendable],
               let urlString = eventDict["url"] as? String,
               let url = URL(string: urlString) {
                navManager?.present(sheet: .openWebPage(url), in: .shoppableVideo)
            }

        case "should-add-item-to-cart", "should-update-item-in-cart":
            guard let callbackKey = event.data["callbackKey"] as? String else { return }
            let inner = event.data["event"] as? [String: Sendable]
            let sku = (inner?["sku"] as? String) ?? (event.data["sku"] as? String)
            let quantity: Int = {
                if let q = inner?["quantity"] as? Int { return q }
                if let q = inner?["quantity"] as? Double { return Int(q) }
                if let s = inner?["quantity"] as? String, let i = Int(s) { return i }
                return 1
            }()
            guard let sku else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if quantity > 3 {
                    player.notify(callbackKey: callbackKey, info: "{ success: false, reason: 'out-of-stock' }")
                } else {
                    Storage.shared.setCartQuantity(productId: sku, quantity: quantity)
                    player.notify(callbackKey: callbackKey, info: true)
                }
            }

        case "provide-product-data":
            Task { try await self.hydrate(data: event.data, for: player) }

        case "goto-checkout":
            switchTab(to: .cart, from: player)

        case "open-wishlist":
            switchTab(to: .wishlist, from: player)

        case "provide-wishlist-status":
            handleProvideWishlistStatus(player: player, data: event.data)

        case "add-to-wishlist":
            handleAddToWishlist(player: player, data: event.data)

        case "remove-from-wishlist":
            handleRemoveFromWishlist(player: player, data: event.data)

        case "open-wishlist-login":
            handleOpenWishlistLogin(player: player, data: event.data)

        case "preview-should-expand":
            onPreviewShouldExpand?(id)

        default:
            break
        }
    }

    func onVideoStatusChanged(_ id: String, state: BambuserVideoState) {
        onStateChanged?(id, state)
    }

    func onErrorOccurred(_ id: String, error: any Error) {
        print("Player error [\(id)]: \(error)")
    }

    func onVideoProgress(_ id: String, duration: Double, currentTime: Double) {
        onProgress?(id, duration, currentTime)
    }

    func onThumbnailTapped(_ id: String) {
        onThumbnailTapped?(id)
    }
}

extension ShoppableVideoEventRouter: BambuserPictureInPictureDelegate {
    func onPictureInPictureStateChanged(_ id: String, state: PlayerPipState) {
        if state == .restored {
            navManager?.switchTo(.shoppableVideo)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.player(with: id)?.play()
            }
        }
    }
}
