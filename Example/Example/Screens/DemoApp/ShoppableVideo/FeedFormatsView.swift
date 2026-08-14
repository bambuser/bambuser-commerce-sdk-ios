//
//  FeedFormatsView.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI

struct FeedFormatsView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        List {
            Section {
                ForEach(ShoppableVideoFormat.allCases) { format in
                    NavigationLink(value: PushDestination.shoppableFormat(format)) {
                        HStack(spacing: 12) {
                            Image(systemName: format.systemImage)
                                .font(.title2)
                                .frame(width: 32)
                                .foregroundStyle(.tint)
                            Text(format.title).font(.headline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } footer: {
                Text("Each row showcases a different way to render the same playlist using BambuserCommerceSDK.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        FeedFormatsView()
            .environmentObject(NavigationManager())
    }
}
