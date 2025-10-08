//
//  ExampleApp.swift
//  Example
//
//  Created by Saeid Basirnia on 3/11/25.
//

import SwiftUI

@main
struct ExampleApp: App {
    @StateObject var navigationManager = NavigationManager()

    var body: some Scene {
        WindowGroup {
            RootTabsView()
                .environmentObject(navigationManager)
        }
    }
}
