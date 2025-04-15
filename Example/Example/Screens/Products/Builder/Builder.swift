//
//  Builder.swift
//
//  Example
//  Created by Seemanta on 2025-04-02.
//

import Foundation

protocol Buildable {
    associatedtype BuilderType
    func build() throws -> BuilderType
}

enum BuilderError: Error {
    case missingRequiredProperty(String)
    case invalidRequiredProperty(String)
}

extension Encodable {
    /// Converting object to postable JSON
    func toJSON(_ encoder: JSONEncoder = JSONEncoder()) throws -> String {
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}
