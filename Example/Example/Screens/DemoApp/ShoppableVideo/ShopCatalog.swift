//
//  ShopCatalog.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI

enum ShopCatalog {
    struct Product: Identifiable, Hashable {
        let id: String
        let name: String
        let category: String
        let price: Double
        let currency: String
        let symbol: String
        let tint: Color
    }

    static let featuredProducts: [Product] = [
        Product(id: "p-001", name: "Cloud Runner Sneakers", category: "Sports", price: 129, currency: "USD", symbol: "shoe.fill", tint: .green),
        Product(id: "p-002", name: "Linen Wide Pants", category: "Fashion", price: 79, currency: "USD", symbol: "tshirt.fill", tint: .pink),
        Product(id: "p-003", name: "Smart Speaker Mini", category: "Tech", price: 59, currency: "USD", symbol: "hifispeaker.fill", tint: .blue),
        Product(id: "p-004", name: "Glow Serum", category: "Beauty", price: 34, currency: "USD", symbol: "drop.fill", tint: .purple),
        Product(id: "p-005", name: "Aroma Diffuser", category: "Home", price: 49, currency: "USD", symbol: "wind", tint: .orange),
        Product(id: "p-006", name: "Wireless Earbuds Pro", category: "Tech", price: 149, currency: "USD", symbol: "earbuds", tint: .blue),
        Product(id: "p-007", name: "Yoga Block Set", category: "Sports", price: 24, currency: "USD", symbol: "figure.yoga", tint: .green),
        Product(id: "p-008", name: "Soft Knit Sweater", category: "Fashion", price: 89, currency: "USD", symbol: "scribble.variable", tint: .pink)
    ]
}
