//
//  ShoppableVideoViews.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-06-13.
//

import SwiftUI

struct ShoppableVideoViews: View {
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        VStack(spacing: 8) {
            NavigationRow(
                title: "Single Shoppable Video",
                subtitle: "Fetch and Display Single Shoppable Video"
            ) {
                navManager.navigate(to: .shoppableVideo)
            }

            NavigationRow(
                title: "Shoppable Video - Playlist",
                subtitle: "Fetch and Display a Shoppable Video Playlist"
            ) {
                navManager.navigate(to: .shoppableVideoPlaylist)
            }

            NavigationRow(
                title: "Shoppable Videos - SKU",
                subtitle: "Fetch and Display all Shoppable Videos bind to a product SKU"
            ) {
                navManager.navigate(to: .shoppableVideoSKU)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ShoppableVideoViews()
        .environmentObject(NavigationManager())

}
