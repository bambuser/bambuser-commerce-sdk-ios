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


struct MockClientProduct: Hashable {
    let sku: String
    let productName: String
    let brand: String
    let variations: [MockClientProduct.Variation]

    struct Variation: Hashable{
        let sku: String
        let name: String
        let colorName: String
        let imageUrls: [URL]
        let sizes: [MockClientProduct.Size]
    }

    struct Size: Hashable {
        let sku: String
        let current: Double
        let name: String
        let inStock: Int
    }
}
