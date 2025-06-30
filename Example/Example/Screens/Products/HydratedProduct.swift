//
//  HydratedProduct.swift
//  Example
//
//  Created by Saeid Basirnia on 4/15/25.
//

import Foundation

/// Represents a hydrated product model used by the Bambuser Commerce SDK.
///
/// This structure is required when using **product hydration**, which allows the SDK to display
/// enriched product data during live or recorded shopping experiences.
///
/// > Important: The Bambuser SDK does **not** explicitly require this exact data structure in Swift.
/// > Instead, it expects a **JSON-compatible representation** of this format (e.g., a `[String: Sendable]` dictionary).
///
/// You can refer to:
/// - `hydrateUsingProductBuilder(data:)
/// or`
/// - `hydrate(data:)`
/// for examples of how to convert custom product data into this format.
///
struct HydratedProduct: Hashable, Codable {
    let sku: String
    var name: String
    var brandName: String
    var introduction: String?
    var description: String?
    var variations: [Variation]

    init(
        sku: String,
        name: String = "",
        brandName: String = "",
        introduction: String? = nil,
        description: String? = nil,
        variations: [Variation] = []
    ) {
        self.sku = sku
        self.name = name
        self.brandName = brandName
        self.introduction = introduction
        self.description = description
        self.variations = variations
    }
}

struct Variation: Hashable, Codable {
    var sku: String  = ""
    var name: String  = ""
    var colorName: String  = ""
    var colorHexCode: String?
    var imageUrls: [URL] = []
    var sizes: [ProductSize] = []
}

struct ProductSize: Hashable, Codable {
    var sku: String = ""
    var current: Double = 0.0
    var name: String = ""
    var inStock: Int = 0
    var original: Double?
    var currency: String?
    var perUnit: Double?
    var unitAmount: Int?
    var unitDisplayName: String?
}
