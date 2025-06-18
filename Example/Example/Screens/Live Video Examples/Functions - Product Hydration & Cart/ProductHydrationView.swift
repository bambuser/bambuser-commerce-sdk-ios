//
//  ProductHydrationView.swift
//  Example
//
//  Created by Saeid Basirnia on 3/18/25.
//

import SwiftUI

struct ProductHydrationViewRepresentable: UIViewControllerRepresentable {
    let navManager: NavigationManager

    func makeUIViewController(context: Context) -> ProductHydrationViewController {
        ProductHydrationViewController(navManager: navManager)
    }

    func updateUIViewController(_ uiViewController: ProductHydrationViewController, context: Context) {
        // No dynamic update needed.
    }
}
