//
//  SizeBuilder.swift
//  Example
//
//  Created by Seemanta on 2025-04-02.
//


extension ProductSize: Buildable {
    typealias BuilderType = ProductSize

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

    func withInStock(_ inStock: Int) -> Self {
        var copy = self
        copy.inStock = inStock
        return copy

    }

    func withCurrentPrice(_ current: Double) -> Self {
        var copy = self
        copy.current = current
        return copy
    }

    func withOriginal(_ original: Double?) -> Self {
        var copy = self
        copy.original = original
        return copy
    }

    func withCurrency(_ currency: String?) -> Self {
        var copy = self
        copy.currency = currency
        return copy
    }

    func withPerUnit(_ perUnit: Double?) -> Self {
        var copy = self
        copy.perUnit = perUnit
        return copy
    }

    func withUnitAmount(_ unitAmount: Int?) -> Self {
        var copy = self
        copy.unitAmount = unitAmount
        return copy
    }

    func withUnitDisplayName(_ unitDisplayName: String?) -> Self {
        var copy = self
        copy.unitDisplayName = unitDisplayName
        return copy
    }


    func build() throws -> ProductSize {
        guard !sku.isEmpty else { throw BuilderError.missingRequiredProperty("sku") }
        guard !name.isEmpty else { throw BuilderError.missingRequiredProperty("name") }
        guard current > 0.0 else { throw BuilderError.invalidRequiredProperty("currency") }
        guard inStock > 0 else { throw BuilderError.invalidRequiredProperty("inStock") }

        return self
    }
}
