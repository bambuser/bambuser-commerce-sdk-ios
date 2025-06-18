//
//  ShoppableVideoPlaylistView.swift
//  Example
//
//  Created by Seemanta on 2025-04-30.
//

import SwiftUI

struct ShoppableVideoPlaylistViewRepresentable: UIViewControllerRepresentable {
    let navManager: NavigationManager

    func makeUIViewController(context: Context) -> ShoppableVideoPlaylistViewController {
        ShoppableVideoPlaylistViewController(navManager: navManager)
    }

    func updateUIViewController(_ uiViewController: ShoppableVideoPlaylistViewController, context: Context) {
        // No dynamic update needed.
    }
}
