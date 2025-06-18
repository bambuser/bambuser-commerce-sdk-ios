//
//  ShoppableVideoWithSKUViewRepresentable.swift
//  Example
//
//  Created by Seemanta on 2025-04-30.
//

import SwiftUI

struct ShoppableVideoWithSKUViewRepresentable: UIViewControllerRepresentable {
    let navManager: NavigationManager

    func makeUIViewController(context: Context) -> ShoppableVideoWithSKUViewController {
        ShoppableVideoWithSKUViewController(navManager: navManager)
    }

    func updateUIViewController(_ uiViewController: ShoppableVideoWithSKUViewController, context: Context) {
        // No dynamic update needed.
    }
}
