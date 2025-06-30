//
//  InitializeVideoViewRepresentable.swift
//  Example
//
//  Created by Saeid Basirnia on 3/11/25.
//

import SwiftUI
import BambuserCommerceSDK

struct InitializeVideoViewRepresentable: UIViewControllerRepresentable {
    let navManager: NavigationManager

    func makeUIViewController(context: Context) -> InitializeVideoViewController {
        InitializeVideoViewController(navManager: navManager)
    }

    func updateUIViewController(_ uiViewController: InitializeVideoViewController, context: Context) {
        // No update needed.
    }
}
