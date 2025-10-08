//
//  WishlistViews.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-10-03.
//

import Foundation

@MainActor
final class WishlistViewModel: ObservableObject {
    @Published private(set) var items: [WishlistItem] = []

    func reloadFromStorage() {
        let skus = Storage.shared.wishlist.compactMap { $0.value ? $0.key : nil }
        items = skus.compactMap { sku in
            guard let p = ProductHydrationDataSource.findHydratedProduct(for: sku) else { return nil }
            return WishlistItem(product: p)
        }
    }

    func remove(sku: String) {
        Storage.shared.removeFromWishlist(productId: sku)
        reloadFromStorage()
    }

    func remove(at offsets: IndexSet) {
        let toRemove = offsets.map { items[$0].sku }
        toRemove.forEach { Storage.shared.removeFromWishlist(productId: $0) }
        reloadFromStorage()
    }

    func clearAll() {
        Storage.shared.wishlist.keys.forEach { Storage.shared.removeFromWishlist(productId: $0) }
        reloadFromStorage()
    }

    func addToCart(sku: String, quantity: Int = 1) {
        Storage.shared.updateCart(productId: sku, quantity: quantity)
    }
}
