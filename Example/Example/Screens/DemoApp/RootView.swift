//
//  RootView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-22.
//

import SwiftUI

struct RootTabsView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        TabView(selection: $navigationManager.currentTab) {
            // Live tab
            NavigationStack(path: navigationManager.pathBinding(for: .live)) {
                LiveView()
                    .toolbar(navigationManager.isPushStackEmpty(.live) ? .visible : .hidden, for: .tabBar)
                    .navigationDestination(for: PushDestination.self) { destination in
                        switch destination {
                        case .liveShow(let showId):
                            BambuserVideoView(id: showId)
                                .ignoresSafeArea(edges: .bottom)
                        }
                    }
            }
            .tabItem {
                Label("Live", systemImage: "video")
            }
            .tag(Tab.live)

            // Shoppable videos tab
            feedView
                .tabItem {
                    Label("Feed", systemImage: "video.doorbell")
                }
                .tag(Tab.shoppableVideo)

            // Wishlist tab
            NavigationStack(path: navigationManager.pathBinding(for: .wishlist)) {
                WishlistView()
            }
            .tabItem {
                Label("Wishlist", systemImage: "bookmark")
            }
            .tag(Tab.wishlist)

            // Cart tab
            NavigationStack(path: navigationManager.pathBinding(for: .cart)) {
                CartView()
            }
            .tabItem {
                Label("Cart", systemImage: "cart")
            }
            .tag(Tab.cart)
        }
    }

    @ViewBuilder
    private var feedView: some View {
        let binding = navigationManager.sheetBinding(for: .shoppableVideo)

        let stack = NavigationStack(path: navigationManager.pathBinding(for: .shoppableVideo)) {
            BambuserFeedView()
                .applyBottomSafeAreaRule()
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            stack
                .fullScreenCover(item: binding) { sheet in
                    switch sheet {
                    case .openWebPage(let url):
                        WebPageSheet(url: url)
                            .environmentObject(navigationManager)
                    }
                }
        } else {
            stack
                .sheet(item: binding) { sheet in
                    switch sheet {
                    case .openWebPage(let url):
                        WebPageSheet(url: url)
                            .environmentObject(navigationManager)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.hidden)
                    }
                }
        }
    }
}

private extension View {
    @ViewBuilder
    func applyBottomSafeAreaRule() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.ignoresSafeArea(edges: .bottom)
        } else {
            self
        }
    }
}

#Preview {
    RootTabsView()
        .environmentObject(NavigationManager())
}
