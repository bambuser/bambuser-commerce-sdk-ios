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
                    title: "Live Video Features",
                    subtitle: "Explore features related to live video streaming, including player initialization and event handling."
                ) {
                    navManager.navigate(
                        to: .liveVideosExamples
                    )
                }
                
                NavigationRow(
                    title: "Shoppable Video Features",
                    subtitle: "Explore features related to shoppable video, including product hydration and cart implementation."
                ) {
                    navManager.navigate(
                        to: .shoppableVideosExamples
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
        .environmentObject(NavigationManager())
}
