//
//  BambuserFeedView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-09-30.
//

import SwiftUI

struct ReelsFeedView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager
    var startIndex: Int = 0

    func makeUIViewController(context: Context) -> ReelsFeedViewController {
        ReelsFeedViewController(navManager: navigationManager, startIndex: startIndex)
    }

    func updateUIViewController(_ uiViewController: ReelsFeedViewController, context: Context) {}
}
