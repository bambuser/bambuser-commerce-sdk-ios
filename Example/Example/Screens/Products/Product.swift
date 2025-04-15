//
//  Product.swift
//  Example
//
//  Created by Saeid Basirnia on 3/12/25.
//

import Foundation

/// This model is structured to align with the data format returned from Bambuser's product configuration.
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
