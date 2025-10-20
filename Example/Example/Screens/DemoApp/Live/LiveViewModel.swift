//
//  LiveViewModel.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-22.
//

import Foundation


@MainActor
final class LiveViewModel: ObservableObject {
    @Published private(set) var videos: [LiveVideo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var request = URLRequest(url: Show.WidgetUrl)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoder = JSONDecoder()
            let channel = try decoder.decode(ChannelDTO.self, from: data)

            let shows = channel.playlists.flatMap { $0.shows }

            var mapped: [LiveVideo] = shows.map { s in
                LiveVideo(
                    id: s.showId,
                    title: s.title,
                    preview: URL(string: s.image ?? ""),
                    duration: s.duration,
                    startedAt: Date.fromMillis(s.startedAt)
                )
            }

            mapped.sort {
                let l = $0.startedAt ?? .distantPast
                let r = $1.startedAt ?? .distantPast
                if l != r { return l > r }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

            self.videos = mapped
        } catch {
            self.errorMessage = error.localizedDescription
            self.videos = []
        }
    }

    func durationText(_ seconds: Int?) -> String {
        guard let seconds, seconds >= 0 else { return "—:—" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
}

private extension Date {
    static func fromMillis(_ ms: Int?) -> Date? {
        guard let ms else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
    }
}
