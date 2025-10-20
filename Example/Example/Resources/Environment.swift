//
//  Environment.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-07-03.
//

enum Environment {
    case staging
    case prod

    static var current: Environment {
#if STAGING
        return .staging
#else
        return .prod
#endif
    }
}
