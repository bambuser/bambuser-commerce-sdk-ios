//
//  ContentView.swift
//  Example
//
//  Created by Saeid Basirnia on 3/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var navManager = NavigationManager()

    var body: some View {
        NavigationStack(
            path: $navManager.path
        ) {
            HomeView()
                .navigationDestination(
                    for: Destination.self
                ) { destination in
                    destinationView(
                        for: destination
                    )
                }

        }
        .environmentObject(navManager)
        .background(Color.gray.opacity(0.3))
    }

    @ViewBuilder
    func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .initializingShow:
            InitializeVideoViewRepresentable(navManager: navManager)
                .ignoresSafeArea()
        case .eventHandling:
            EventHandlingViewRepresentable(navManager: navManager)
                .ignoresSafeArea()
        case .productHydration:
            ProductHydrationViewRepresentable(navManager: navManager)
                .ignoresSafeArea()
        case .productDetail(let product):
            ProductDetailView(
                product: product
            )
        }
    }
}

#Preview {
    ContentView(navManager: NavigationManager())
}
