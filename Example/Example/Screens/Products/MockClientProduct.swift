//
//  MockClientProduct.swift
//  Example
//
//  Created by Saeid Basirnia on 4/15/25.
//

import Foundation

/// A mock data model representing a sample client's product structure.
///
/// This model is **not** associated with Bambuser's product hydration data model.
/// It is provided to demonstrate how a custom client-side data model can be converted
/// into a `HydratedProduct` using the provided `productBuilder` utility.
///
/// - Note: This mock structure is useful when testing or showcasing how product hydration
///         can be applied to a custom format before integrating real backend data.
///
/// - See also: You can look into the `hydrateUsingProductBuilder(data:)` method
///             for an example of how to convert this model into a hydrated product.
struct MockClientProduct: Hashable {
    let sku: String
    let productName: String
    let brand: String
    let attributes: [MockClientProduct.Attribute]

    struct Attribute: Hashable{
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
