//
//  FABShopView.swift
//  Example
//

import SwiftUI

struct FABShopView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = FABShopViewController(navManager: navigationManager)
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
