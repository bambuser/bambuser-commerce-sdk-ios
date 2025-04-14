//
//  ProductBuilder.swift
//  Example
//
//  Created by Seemanta on 2025-04-02.
//

import Foundation

extension HydratedProduct: Buildable {

    typealias BuilderType = HydratedProduct

    func withName(_ name: String) -> Self {
            var copy = self
            copy.name = name
            return copy
        }

        func withBrandName(_ brandName: String) -> Self {
            var copy = self
            copy.brandName = brandName
            return copy
        }

        func withIntroduction(_ introduction: String?) -> Self {
            var copy = self
            copy.introduction = introduction
            return copy
        }

        func withDescription(_ description: String?) -> Self {
            var copy = self
            copy.description = description
            return copy
        }

        func withVariations(_ variations: [Variation]) -> Self {
            var copy = self
            copy.variations = variations
            return copy
        }

        func build() throws -> HydratedProduct {
            guard !name.isEmpty else { throw BuilderError.missingRequiredProperty("name") }
            guard !brandName.isEmpty else { throw BuilderError.missingRequiredProperty("brandName") }
            return self
        }
}
