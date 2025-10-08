//
//  CartViewModel.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-10-03.
//

import Foundation

@MainActor
final class CartViewModel: ObservableObject {
    @Published private(set) var items: [CartItem] = []

    var currency: String {
        items.first?.currency ?? "SEK"
    }

    var subtotal: Double {
        items.reduce(0) {
            $0 + $1.lineTotal
        }
    }

    func reloadFromStorage() {
        let entries = Storage.shared.cart
        let newItems: [CartItem] = entries.compactMap { (productId, qty) in
            guard qty > 0 else { return nil }
            let parent = parentSKU(from: productId)
            guard let product = ProductHydrationDataSource.hydratedProduct(for: parent) else { return nil }

            let priceInfo = Self.priceInfo(for: productId, in: product)
            let imageURL = product.variations.first?.imageUrls.first

            return CartItem(
                id: productId,
                parentSKU: parent,
                title: product.name,
                brand: product.brandName,
                imageURL: imageURL,
                sizeName: priceInfo.sizeName,
                unitPrice: priceInfo.price,
                original: priceInfo.original,
                currency: priceInfo.currency,
                quantity: qty
            )
        }
        self.items = newItems.sorted {
            ($0.title, $0.id) < ($1.title, $1.id)
        }
    }

    func updateQuantity(productId: String, quantity: Int) {
        Storage.shared.updateCart(productId: productId, quantity: quantity)
        reloadFromStorage()
    }

    func remove(productId: String) {
        Storage.shared.removeFromCart(productId: productId)
        reloadFromStorage()
    }

    func remove(at offsets: IndexSet) {
        let ids = offsets.map { items[$0].id }
        ids.forEach {
            Storage.shared.removeFromCart(productId: $0)
        }
        reloadFromStorage()
    }

    func clearAll() {
        Storage.shared.cart.keys.forEach {
            Storage.shared.removeFromCart(productId: $0)
        }
        reloadFromStorage()
    }

    // MARK: - Helpers
    static func priceInfo(
        for fullSKU: String,
        in product: HydratedProduct
    ) -> (
        price: Double,
        original: Double?,
        currency: String,
        sizeName: String?
    ) {
        for variation in product.variations {
            for size in variation.sizes {
                if size.sku == fullSKU {
                    return (size.current, size.original, size.currency ?? "SEK", size.name)
                }
            }
        }
        let size = product.variations.first?.sizes.first
        return (size?.current ?? 0, size?.original, size?.currency ?? "SEK", size?.name)
    }
}
