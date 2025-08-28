//
//  WishlistView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-18.
//

import SwiftUI

struct WishlistViewRepresentable: UIViewControllerRepresentable {
    let navManager: NavigationManager

    func makeUIViewController(context: Context) -> WishlistViewController {
        WishlistViewController(navManager: navManager)
    }

    func updateUIViewController(_ uiViewController: WishlistViewController, context: Context) {
        // No dynamic update needed.
    }
}
