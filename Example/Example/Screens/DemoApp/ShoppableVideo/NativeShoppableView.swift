//
//  NativeShoppableView.swift
//  Example
//

import SwiftUI

struct NativeShoppableView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = NativeShoppableViewController(navManager: navigationManager)
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
