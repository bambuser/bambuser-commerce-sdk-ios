//
//  StoriesPlayerCache.swift
//  Example
//

import BambuserCommerceSDK

@MainActor
final class StoriesPlayerCache {
    static let shared = StoriesPlayerCache()
    private init() {}
    var players: [BambuserPlayerView] = []
}
