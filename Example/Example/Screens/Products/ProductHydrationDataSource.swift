//
//  ProductHydrationDataSource.swift
//  Example
//
//  Created by Saeid Basirnia on 3/17/25.
//

import Foundation

/// `ProductHydrationDataSource` is a mock data source that provides hydrated product information.
///
/// This struct contains sample product data, which can be accessed using SKU identifiers.
/// The data includes product details such as name, brand, description, variations, images, and pricing information,
/// which are mandatory for hydrating products in the built-in Bambuser player.
///
/// ## Bambuser Integration:
/// If your app uses the Bambuser player's built-in product pages and cart functionality,
/// these data fields are required to ensure proper hydration and display of product details.
///
/// ## Custom Implementations:
/// If your app does **not** use the Bambuser player's built-in product pages and cart,
/// you can decide which product data is necessary based on your specific requirements.
struct ProductHydrationDataSource {
    static let sampleProducts: [String: HydratedProduct] = [
        "436775": HydratedProduct(
            sku: "436775",
            name: "Livall Cykelhjälm L – Evopurl Large",
            brandName: "Livall",
            introduction: "High-performance cycling helmet offering superior protection and style.",
            description: "Designed for urban cyclists, this helmet features advanced impact protection, excellent ventilation, and an ergonomic design to keep you safe and comfortable.",
            variations: [
                Variation(
                    sku: "436775-black",
                    name: "Black Livall Helmet",
                    colorName: "black",
                    imageUrls: [URL(string: "https://www.elgiganten.se/_next/image?url=https%3A%2F%2Fmedia.elkjop.com%2Fassets%2Fimage%2Fdv_web_D180001002952050&w=1200&q=75")!],
                    sizes: [
                        ProductSize(
                            sku: "436775-black-medium",
                            currency: "SEK",
                            current: 999.0,
                            original: 1499.0,
                            name: "Medium",
                            inStock: 15,
                            perUnit: nil,
                            unitAmount: nil,
                            unitDisplayName: nil
                        )
                    ]
                )
            ]
        ),
        "614442": HydratedProduct(
            sku: "614442",
            name: "Pro-Tect Cubic Kedjecykellås",
            brandName: "Pro-Tect",
            introduction: "Secure your bike with this heavy-duty chain lock.",
            description: "Robust and durable, this chain lock is designed for maximum security in urban environments, keeping your bike safe day and night.",
            variations: [
                Variation(
                    sku: "614442-silver",
                    name: "Cubic Chain Lock - Silver",
                    colorName: "silver",
                    imageUrls: [URL(string: "https://www.elgiganten.se/_next/image?url=https%3A%2F%2Fmedia.elkjop.com%2Fassets%2Fimage%2Fdv_web_D1800010021483116&w=1200&q=75")!],
                    sizes: [
                        ProductSize(
                            sku: "614442-silver-standard",
                            currency: "SEK",
                            current: 999.0,
                            original: 999.0,
                            name: "Standard",
                            inStock: 20,
                            perUnit: nil,
                            unitAmount: nil,
                            unitDisplayName: nil
                        )
                    ]
                )
            ]
        ),
        "624114": HydratedProduct(
            sku: "624114",
            name: "Bird A-Frame Elcykel VA00056",
            brandName: "Bird",
            introduction: "Efficient electric bike for urban commuting.",
            description: "<div><h2>Modern Electric Bike</h2><p>Experience a modern electric bike featuring cutting-edge technology and a stylish design, perfect for daily commuting.</p></div>",
            variations: [
                Variation(
                    sku: "624114-standard",
                    name: "Standard Bird A-Frame Elcykel",
                    colorName: "default",
                    imageUrls: [URL(string: "https://www.elgiganten.se/_next/image?url=https%3A%2F%2Fmedia.elkjop.com%2Fassets%2Fimage%2Fdv_web_D1800012698969&w=1200&q=75")!],
                    sizes: [
                        ProductSize(
                            sku: "614442-silver-standard",
                            currency: "SEK",
                            current: 800.0,
                            original: 999.0,
                            name: "Standard",
                            inStock: 20,
                            perUnit: nil,
                            unitAmount: nil,
                            unitDisplayName: nil
                        )
                    ]
                )
            ]
        )
    ]

    static func hydratedProduct(for sku: String) -> HydratedProduct? {
        sampleProducts[sku]
    }

    static func jsonObjectString(for sku: String) -> String? {
        guard let product = sampleProducts[sku] else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(product)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding product \(sku): \(error)")
            return nil
        }
    }
}
