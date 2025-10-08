//
//  DataModels.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-10-03.
//

import Foundation

struct LiveVideo: Identifiable, Hashable {
    let id: String
    let title: String
    let preview: URL?
    let duration: Int?
    let startedAt: Date?
}

struct ChannelDTO: Decodable {
    let playlists: [PlaylistDTO]
}

struct PlaylistDTO: Decodable {
    let shows: [ShowDTO]
}

struct ShowDTO: Decodable {
    let showId: String
    let image: String?
    let title: String
    let duration: Int?
    let startedAt: Int?
}
