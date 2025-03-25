//
//  Product.swift
//  Example
//
//  Created by Saeid Basirnia on 3/12/25.
//

import Foundation

struct Product: Hashable {
    let id: String
    let sku: String
    let title: String
    let url: URL

    init?(data: [String: Any]) {
        guard let event = data["event"] as? [String: Any],
              let id = event["id"] as? String,
              let sku = event["sku"] as? String,
              let title = event["title"] as? String,
              let urlString = event["url"] as? String,
              let url = URL(string: urlString) else {
            return nil
        }
        self.id = id
        self.sku = sku
        self.title = title
        self.url = url
    }

    var hydrated: HydratedProduct? {
        ProductHydrationDataSource.hydratedProduct(for: sku)
    }
}

struct HydratedProduct: Hashable, Codable {
    let sku: String
    let name: String
    let brandName: String
    let introduction: String
    let description: String
    let variations: [Variation]
}

struct Variation: Hashable, Codable {
    let sku: String
    let name: String
    let colorName: String
    let imageUrls: [URL]
    let sizes: [ProductSize]
}

struct ProductSize: Hashable, Codable {
    let sku: String
    let currency: String
    let current: Double
    let original: Double
    let name: String
    let inStock: Int
    let perUnit: Double?
    let unitAmount: Int?
    let unitDisplayName: String?
}
