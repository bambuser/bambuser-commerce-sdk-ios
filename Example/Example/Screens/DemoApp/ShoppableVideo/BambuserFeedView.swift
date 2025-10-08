//
//  BambuserFeedView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-09-30.
//

import SwiftUI

struct BambuserFeedView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> ShoppableVideoViewController {
        ShoppableVideoViewController(navManager: navigationManager)
    }

    func updateUIViewController(_ uiViewController: ShoppableVideoViewController, context: Context) {
        // No dynamic update needed.
    }
}
