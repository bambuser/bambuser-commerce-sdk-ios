//
//  LiveView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-22.
//

import SwiftUI

struct LiveView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel = LiveViewModel()

    var body: some View {
        Group {
            if viewModel.videos.isEmpty && viewModel.isLoading {
                ProgressView()
            } else if viewModel.videos.isEmpty {
                ContentUnavailableView(
                    "No videos",
                    systemImage: "play.rectangle",
                    description: Text("Check back soon.")
                )
            } else {
                List(viewModel.videos) { video in
                    Button(action: {
                        navigationManager.push(.liveShow(video.id))
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Thumbnail(
                                imageURL: video.preview,
                                durationText: viewModel.durationText(video.duration)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text(video.title)
                                .font(.headline)
                                .lineLimit(2)
                        }
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .padding()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

private struct Thumbnail: View {
    let imageURL: URL?
    let durationText: String

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()

                    case .failure:
                        placeholder

                    @unknown default:
                        placeholder
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                placeholder
            }

            Text(durationText)
                .font(.caption2)
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(8)
        }
    }

    private var placeholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "photo")
                .imageScale(.large)
                .foregroundStyle(.secondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    LiveView()
}
