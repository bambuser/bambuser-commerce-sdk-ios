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
            // Main entry points for live and shoppable videos examples
        case .liveVideosExamples:
            LiveVideoViews()
        case .shoppableVideosExamples:
            ShoppableVideoViews()
            
            // Live video examples
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
        case .wishlist:
            WishlistViewRepresentable(navManager: navManager)
                .ignoresSafeArea()

            // Shoppable video examples
        case .shoppableVideoPlaylist:
            ShoppableVideoPlaylistViewRepresentable(navManager: navManager)
        case .shoppableVideo:
            ShoppableVideoViewRepresentable(navManager: navManager)
        case .shoppableVideoSKU:
            ShoppableVideoWithSKUViewRepresentable(navManager: navManager)
        }
    }
}
