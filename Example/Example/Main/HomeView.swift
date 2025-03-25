//
//  HomeView.swift
//  Example
//
//  Created by Saeid Basirnia on 3/11/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                NavigationRow(
                    title: "Initializing a Live/Pre-Recorded Show",
                    subtitle: "Set up and start a live or pre-recorded video stream."
                ) {
                    navManager.navigate(
                        to: .initializingShow
                    )
                }
                NavigationRow(
                    title: "PiP, Navigation & Event Handling",
                    subtitle: "Programmatically enable Picture-in-Picture (PiP) and handle events by reacting to Player events."
                ) {
                    navManager.navigate(
                        to: .eventHandling
                    )
                }
                NavigationRow(
                    title: "API Interactions, Product Hydration & Cart Implementation",
                    subtitle: "Interact with Bambuser Player APIs, utilize built-in product hydration, and integrate cart"
                ) {
                    navManager.navigate(
                        to: .productHydration
                    )
                }
            }
        }
        .padding()
        .navigationTitle("Home")
    }
}

#Preview {
    HomeView()
}
