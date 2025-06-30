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
/// The codebase Also incorporates a demonstration of client-derived mock data `MockClientProduc` alongside a defined methodology for its programmatic transformation and mapping into the `HydratedProduct` data structure, which is the designated format supported by the Bambuser platform.
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
            name: "Sunlit Glow Bronzer",
            brandName: "Sunlit",
            introduction: "Get that sun-kissed glow with our Sunlit Glow Bronzer.",
            description: "Get that sun-kissed glow with our Sunlit Glow Bronzer. Effortlessly blendable and available in versatile shades, our finely milled formula enhances your complexion with a natural-looking tan. Embrace radiant warmth and vitality all year round.",
            variations: [
                Variation(
                    sku: "436775-bronzer",
                    name: "Sunlit Glow Bronzer",
                    colorName: "bronzer",
                    imageUrls: [URL(string: "https://cdn.prod.website-files.com/66c31044a23e58e719bc6ffb/66c33d86064576f49e7b792c_Makeup_2.webp")!],
                    sizes: [
                        ProductSize(
                            sku: "436775-Bronzer-medium",
                            current: 999.0,
                            name: "Medium",
                            inStock: 15,
                            original: 1499.0,
                            currency: "SEK",
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
            name: "Shine On Lip Gloss",
            brandName: "Shine",
            introduction: "Elevate your lip game with our high-shine, non-sticky lip gloss.",
            description: "Elevate your lip game with our high-shine, non-sticky lip gloss. Get ready to add a pop of luscious color and irresistible gloss to your pout, while keeping your lips soft, moisturized and kissable.",
            variations: [
                Variation(
                    sku: "614442-gloss",
                    name: "Shine On Lip Gloss",
                    colorName: "gloss",
                    imageUrls: [URL(string: "https://cdn.prod.website-files.com/66c31044a23e58e719bc6ffb/66c33d6271dc1a3f03745c37_Makeup_5.webp")!],
                    sizes: [
                        ProductSize(
                            sku: "614442-gloss-standard",
                            current: 999.0,
                            name: "Standard",
                            inStock: 20,
                            original: 999.0,
                            currency: "SEK",
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
            name: "Lash Amplify Mascara",
            brandName: "Lash",
            introduction: "Efficient electric bike for urban commuting.",
            description: "Efficient electric bike for urban commuting.Achieve voluminous, full lashes that command attention with our game-changing mascara. Get ready to elevate your lash game with our innovative formula that lengthens, lifts and defines each lash to perfection.",
            variations: [
                Variation(
                    sku: "624114-standard",
                    name: "Lash Amplify Mascara",
                    colorName: "default",
                    imageUrls: [URL(string: "https://cdn.prod.website-files.com/66c31044a23e58e719bc6ffb/66c33c0b2e7fa3ab0d3b129d_Makeup_3.png")!],
                    sizes: [
                        ProductSize(
                            sku: "614442-silver-standard",
                            current: 800.0,
                            name: "Standard",
                            inStock: 20,
                            original: 999.0,
                            currency: "SEK",
                            perUnit: nil,
                            unitAmount: nil,
                            unitDisplayName: nil
                        )
                    ]
                )
            ]
        )
    ]

    static let mockClientProducts: [String: MockClientProduct] = [
        "436775": MockClientProduct(
            sku: "436775",
            productName: "Sunlit Glow Bronzer",
            brand: "Sunlit",
            attributes: [
                .init(
                    sku: "436775-bronzer",
                    name: "Sunlit Glow Bronzer",
                    colorName: "black",
                    imageUrls: [URL(string: "https://cdn.prod.website-files.com/66c31044a23e58e719bc6ffb/66c33d86064576f49e7b792c_Makeup_2.webp")!],
                    sizes: [
                        .init(
                            sku: "436775-black-medium",
                            current: 700.0,
                            name: "Medium",
                            inStock: 15
                        ),
                        .init(
                            sku: "436775-black-large",
                            current: 750.0,
                            name: "Large",
                            inStock: 15
                        )
                    ]
                )
            ]
        ),
        "614442": MockClientProduct(
            sku: "614442",
            productName: "Shine On Lip Gloss",
            brand: "Shine",
            attributes: [
                .init(
                    sku: "614442-silver",
                    name: "Cubic Chain Lock - Silver",
                    colorName: "silver",
                    imageUrls: [URL(string: "https://cdn.prod.website-files.com/66c31044a23e58e719bc6ffb/66c33d6271dc1a3f03745c37_Makeup_5.webp")!],
                    sizes: [
                        .init(
                            sku: "614442-silver-standard",
                            current: 600.0,
                            name: "Standard",
                            inStock: 20
                        )
                    ]
                )
            ]
        )
    ]

    static func hydratedProduct(for sku: String) -> HydratedProduct? {
        sampleProducts[sku]
    }

    static func mockClientProduct(for sku: String) -> MockClientProduct? {
        mockClientProducts[sku]
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
