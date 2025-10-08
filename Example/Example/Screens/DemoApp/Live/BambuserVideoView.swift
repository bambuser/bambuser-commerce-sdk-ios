//
//  BambuserVideoView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-22.
//

import SwiftUI

struct BambuserVideoView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager
    let id: String

    func makeUIViewController(context: Context) -> BambuserVideoController {
        BambuserVideoController(navManager: navigationManager, showId: id)
    }

    func updateUIViewController(_ uiViewController: BambuserVideoController, context: Context) {
        // No dynamic update needed.
    }
}
