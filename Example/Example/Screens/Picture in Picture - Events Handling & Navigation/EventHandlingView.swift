//
//  EventHandlingViewRepresentable.swift
//  Example
//
//  Created by Saeid Basirnia on 3/12/25.
//

import SwiftUI
import BambuserCommerceSDK

struct EventHandlingViewRepresentable: UIViewControllerRepresentable {
    let navManager: NavigationManager

    func makeUIViewController(context: Context) -> EventHandlingViewController {
        EventHandlingViewController(navManager: navManager)
    }

    func updateUIViewController(_ uiViewController: EventHandlingViewController, context: Context) {
        // No dynamic update needed.
    }
}
