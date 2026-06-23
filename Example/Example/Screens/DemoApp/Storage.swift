//
//  Storage.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-22.
//

final class Storage {
    static let shared = Storage()

    private init() {}

    private(set) var wishlist: [String: Bool] = [:]
    private(set) var cart: [String: Int] = [:]


    func addToWishlist(items: [String: Bool]) {
        wishlist = items
    }

    func addToWishlist(productId: String) {
        wishlist[productId] = true
    }

    func removeFromWishlist(productId: String) {
        wishlist[productId] = nil
    }

    func removeFromCart(productId: String) {
        cart[productId] = nil
    }

    func addToCart(items: [String: Int]) {
        cart = items
    }

    func incrementCart(productId: String, by delta: Int) {
        let newValue = (cart[productId] ?? 0) + delta
        cart[productId] = newValue > 0 ? newValue : nil
    }

    func setCartQuantity(productId: String, quantity: Int) {
        cart[productId] = quantity > 0 ? quantity : nil
    }
}
