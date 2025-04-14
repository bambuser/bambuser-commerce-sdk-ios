//
//  VariationBuilder.swift
//  Example
//
//  Created by Seemanta on 2025-04-02.
//

import Foundation

extension Variation: Buildable {
    typealias BuilderType = Variation

    func withSku(_ sku: String) -> Self {
        var copy = self
        copy.sku = sku
        return copy
    }


    func withName(_ name: String) -> Self {
        var copy = self
        copy.name = name
        return copy
    }

    func withColorName(_ colorName: String) -> Self {
        var copy = self
        copy.colorName = colorName
        return copy
    }

    func withColorHexCode(_ colorHexCode: String?) -> Self {
        var copy = self
        copy.colorHexCode = colorHexCode
        return copy
    }

    func withImageUrls(_ imageUrls: [URL]) -> Self {
        var copy = self
        copy.imageUrls = imageUrls
        return copy
    }

    func withSizes(_ sizes: [ProductSize]) -> Self {
        var copy = self
        copy.sizes = sizes
        return copy
    }

    func build() throws -> Variation {
        guard !sku.isEmpty else { throw BuilderError.missingRequiredProperty("sku") }
        guard !name.isEmpty else { throw BuilderError.missingRequiredProperty("name") }
        guard !colorName.isEmpty else { throw BuilderError.missingRequiredProperty("colorName") }
        guard !imageUrls.isEmpty else { throw BuilderError.missingRequiredProperty("imageUrls") }
        guard !sizes.isEmpty else { throw BuilderError.missingRequiredProperty("sizes") }

        return self
    }
}
