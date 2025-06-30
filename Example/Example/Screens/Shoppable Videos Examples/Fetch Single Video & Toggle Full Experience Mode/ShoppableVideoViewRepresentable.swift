//
//  ShoppableVideoCarouselViewRepresentable.swift
//  Example
//
//  Created by Seemanta on 2025-04-30.
//

import SwiftUI

struct ShoppableVideoViewRepresentable: UIViewControllerRepresentable {
    let navManager: NavigationManager

    func makeUIViewController(context: Context) -> ShoppableVideoViewController {
        ShoppableVideoViewController(navManager: navManager)
    }

    func updateUIViewController(_ uiViewController: ShoppableVideoViewController, context: Context) {
        // No dynamic update needed.
    }
}
