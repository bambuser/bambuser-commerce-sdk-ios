//
//  ShoppableVideoViewController.swift
//  Example
//
//  Created by Seemanta on 2025-04-30.
//

import UIKit
import BambuserCommerceSDK

/// A view controller responsible for fetching and displaying a shoppable video playlist.
///
/// This controller demonstrates how to fetch a playlist from Bambuser,
/// display it in either a grid or carousel, and handle video playback with autoplay support.
/// You can build your own custom UI based on this example or use the available APIs
/// to create your desired UI interface or behavior.
final class ShoppableVideoPlaylistViewController: UIViewController {

    // MARK: - Nested Types

    /// Layout mode for displaying the video playlist.
    enum LayoutMode {
        case grid
        case carousel
    }

    // MARK: - Properties

    /// Determines whether the playlist is shown in a grid or carousel.
    private let layoutMode: LayoutMode = .grid

    /// All shoppable video views fetched from Bambuser.
    private var shoppableVideos: [BambuserPlayerView] = []

    /// Play status for each video by its ID.
    /// Tracks whether a video has been played.
    /// Useful for managing video states for UI and autoplay logic.
    private var videosStatus: [String: Bool] = [:]

    /// Index of the currently playing video, or nil if none.
    private var currentIndex: Int?

    /// Flag to enable or disable autoplay of the next video when the current one ends.
    var isAutoplayEnabled: Bool = true

    /// Navigation manager observer ID to identify view.
    var navigationObserverID: UUID?

    /// Navigation manager for handling navigation events within the app.
    let navManager: NavigationManager

    // MARK: - Layout Constants

    private let gridSpacing: CGFloat = 10
    private let gridColumns: Int = 2
    private let carouselSpacing: CGFloat = 16
    private let sidePadding: CGFloat = 16
    private var videoWidth: CGFloat { UIScreen.main.bounds.width * 0.8 }
    private var videoHeightCarousel: CGFloat { videoWidth * 1.5 }

    // MARK: - UI

    /// Scroll view containing the video grid or carousel.
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.isPagingEnabled = false
        return scrollView
    }()

    /// Container for the grid layout (used in grid mode).
    private lazy var scrollContainerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()

    /// StackView that holds all video players horizontally (used in carousel mode).
    private lazy var videoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = carouselSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    init(navManager: NavigationManager) {
        self.navManager = navManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        navManager.removePopObserver(navigationObserverID)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupScrollView()
        fetchShoppableVideos()
        setupNavigationObserver()
    }

    // MARK: - Setup

    /// Sets up the scroll view and layout for either grid or carousel mode.
    private func setupScrollView() {
        view.addSubview(scrollView)

        switch layoutMode {
        case .grid:
            scrollView.addSubview(scrollContainerView)
            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

                scrollContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                scrollContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                scrollContainerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                scrollContainerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                scrollContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
        case .carousel:
            scrollView.addSubview(videoStack)
            NSLayoutConstraint.activate([
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

                videoStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: sidePadding),
                videoStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -sidePadding),
                videoStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
                videoStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                videoStack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])
        }
    }

    /// Sets up a navigation observer for the current view controller instance.
    /// When this view is popped from the navigation stack (specifically, when leaving the playlist),
    /// it ensures all shoppable video players are cleaned up and memory is released.
    ///
    /// This prevents memory leaks and ensures that no video continues playing in the background.
    /// The observer is removed once cleanup is performed to prevent duplicate calls or retain cycles.
    private func setupNavigationObserver() {
        navigationObserverID = navManager.addPopObserver { [weak self] oldPath, newPath in
            guard let self = self else { return }
            /// Cleans up the player view and releases associated resources.
            ///
            /// - Important: This **must** be called when the player view is no longer needed to ensure
            /// proper deinitialization and removal from memory. This includes stopping playback,
            /// releasing any retained resources, and unregistering navigation observers or other listeners.
            ///
            /// This method should be called at the appropriate point in the view lifecycle—typically
            /// when the view is being deallocated or is no longer visible. The exact timing depends
            /// on your project’s architecture. In UIKit, you might call this from `deinit`
            /// or `viewWillDisappear` and in SwiftUI, maybe the `.onDisappear` modifier.
            ///
            /// In this project, we have custom navigation flow and
            /// the `NavigationManager`, so it’s important to ensure `cleanup()` is called
            /// when the view is removed from the navigation stack.
            if oldPath.last == .shoppableVideoPlaylist {
                self.shoppableVideos.forEach { $0.cleanup() }
            }
        }
    }

    // MARK: - Data Fetching & Layout Setup

    /// Fetches a shoppable video playlist from Bambuser and populates the layout.
    private func fetchShoppableVideos() {
        let bambuserPlayer = BambuserVideoPlayer(server: .US)
        /// Configure the playlist fetch parameters.
        /// Mandatory parameters:
        /// - `orgId`: Your Bambuser organization ID.
        /// - `pageId`: The page ID where the playlist is hosted.
        /// - `playlistId`: The ID of the playlist you want to fetch.
        ///
        /// Note: If playlist is not found, a new playlist will be created with the given values.
        let videoContainerInfo = BambuserShoppableVideoPlaylistInfo(
            orgId: "uy7jqRQBEfP91orbvbB5",
            pageId: "mobile-playlist",
            playlistId: "best-of-the-year",
            title: "Mobile SDK"
        )

        Task {
            do {
                /// Configures the Bambuser video player.
                /// - `type`: Specifies the video type and requires a valid show ID.
                /// - `events`: Specifies which events app expects to receive from SDK
                /// - `configuration`: Provides additional player settings.
                /// More information: [Bambuser Player Integration guide](https://bambuser.com/docs/shoppable-video/bam-playlist-integration/)
                let config = BambuserShoppableVideoConfiguration(
                    type: .playlist(videoContainerInfo),
                    events: ["*"],
                    configuration: [
                        "thumbnail": [
                            "enabled": true,
                            "showPlayButton": layoutMode == .carousel,
                            "contentMode": "scaleAspectFill",
                            "preview": nil
                        ],
                        /// Configuration for shoppable video player.
                        /// Hide products and title in the player.
                        "previewConfig": ["settings": "products:false; title: false"],
                        "playerConfig": [
                            "buttons": [
                                "dismiss": "event",
                                "product": "none"
                            ],
                            "autoplay": true
                        ]
                    ]
                )

                /// Default page size is 15, you can change it by passing `pageSize` parameter.
                /// You can also pass `page` parameter to fetch specific page of videos.
                let results = try await bambuserPlayer.createShoppableVideoPlayerCollection(
                    videoConfiguration: config
                )
                /// Pagination info can be used to fetch more videos if available.
                print(results.pagination)
                await MainActor.run {
                    switch layoutMode {
                    case .grid:
                        setupGrid(results.players, columns: gridColumns)
                    case .carousel:
                        setupCarousel(results.players)
                    }
                }
            } catch {
                print("Error loading shoppable views: \(error)")
            }
        }
    }

    /// Arranges shoppable video views in a grid layout.
    /// - Parameters:
    ///   - videoViews: The video views to lay out.
    ///   - columns: Number of columns in the grid.
    private func setupGrid(_ videoViews: [BambuserPlayerView], columns: Int) {
        scrollContainerView.subviews.forEach { $0.removeFromSuperview() }
        guard !videoViews.isEmpty, columns > 0 else { return }
        shoppableVideos = videoViews
        videosStatus = [:]
        currentIndex = nil

        let spacing = gridSpacing
        let totalHorizontalSpacing = CGFloat(columns - 1) * spacing
        let availableWidth = view.bounds.width - 2 * sidePadding - totalHorizontalSpacing
        let itemWidth = availableWidth / CGFloat(columns)
        let itemHeight = itemWidth * 2

        for (index, videoView) in videoViews.enumerated() {
            videoView.delegate = self
            videoView.backgroundColor = .black
            videoView.translatesAutoresizingMaskIntoConstraints = false
            scrollContainerView.addSubview(videoView)

            let row = index / columns
            let column = index % columns

            NSLayoutConstraint.activate([
                videoView.widthAnchor.constraint(equalToConstant: itemWidth),
                videoView.heightAnchor.constraint(equalToConstant: itemHeight),
                videoView.topAnchor.constraint(
                    equalTo: scrollContainerView.topAnchor,
                    constant: CGFloat(row) * (itemHeight + spacing) + spacing
                ),
                videoView.leadingAnchor.constraint(
                    equalTo: scrollContainerView.leadingAnchor,
                    constant: sidePadding + CGFloat(column) * (itemWidth + spacing)
                )
            ])

            videosStatus[videoView.id] = false

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            videoView.addGestureRecognizer(tap)
        }

        let rows = Int(ceil(Double(videoViews.count) / Double(columns)))
        let contentHeight = CGFloat(rows) * itemHeight + CGFloat(rows + 1) * spacing

        NSLayoutConstraint.activate([
            scrollContainerView.heightAnchor.constraint(equalToConstant: contentHeight)
        ])
    }

    /// Arranges shoppable video views horizontally as a carousel.
    /// - Parameter videoViews: The video views to show in the carousel.
    private func setupCarousel(_ videoViews: [BambuserPlayerView]) {
        videoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !videoViews.isEmpty else { return }
        shoppableVideos = videoViews
        videosStatus = [:]
        currentIndex = nil

        for videoView in videoViews {
            videoView.delegate = self
            videoView.backgroundColor = .black
            videoView.translatesAutoresizingMaskIntoConstraints = false
            videoView.widthAnchor.constraint(equalToConstant: videoWidth).isActive = true
            videoView.heightAnchor.constraint(equalToConstant: videoHeightCarousel).isActive = true

            videosStatus[videoView.id] = false

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            videoView.addGestureRecognizer(tap)
            videoStack.addArrangedSubview(videoView)
        }
    }

    // MARK: - Video Playback Controls

    /// Handles tap gestures on a video view and starts playback.
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let tapped = gesture.view as? BambuserPlayerView else { return }
        let tappedId = tapped.id
        guard let index = shoppableVideos.firstIndex(where: { $0.id == tappedId }) else { return }
        playVideo(at: index)

        if layoutMode == .carousel {
            scrollToVideo(at: index)
        }
    }

    /// Pauses all videos and starts playing the one at the given index.
    private func playVideo(at index: Int?) {
        shoppableVideos.forEach { $0.pause() }
        if let index, shoppableVideos.indices.contains(index) {
            shoppableVideos[index].play()
            currentIndex = index
        } else {
            currentIndex = nil
        }
    }

    /// Plays the next video in the playlist, if any.
    private func playNextVideo(from currentId: String) {
        guard let idx = shoppableVideos.firstIndex(where: { $0.id == currentId }),
              shoppableVideos.indices.contains(idx + 1) else { return }
        playVideo(at: idx + 1)
        if layoutMode == .carousel {
            scrollToVideo(at: idx + 1)
        }
    }

    /// Scrolls the scrollView to make the selected video visible as a carousel:
    /// - 16pt left for the first video
    /// - 16pt right for the last video
    /// - Others: video aligns left, 16pt from left edge
    private func scrollToVideo(at index: Int) {
        guard shoppableVideos.indices.contains(index) else { return }

        let targetView = shoppableVideos[index]
        let visibleWidth = scrollView.bounds.width
        let totalContentWidth = CGFloat(shoppableVideos.count) * (videoWidth + carouselSpacing) - carouselSpacing

        var xOffset: CGFloat = 0
        if index == 0 {
            xOffset = 0
        } else if index == shoppableVideos.count - 1 {
            xOffset = max(totalContentWidth + sidePadding * 2 - visibleWidth, 0)
        } else {
            xOffset = targetView.frame.minX - sidePadding
        }

        scrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
    }
}

// MARK: - BambuserVideoPlayerDelegate

extension ShoppableVideoPlaylistViewController: BambuserVideoPlayerDelegate {

    /// Handles events received from the Bambuser video player.
    ///
    /// - Parameters:
    ///   - id: The ID of the player emitting the event.
    ///   - event: The event payload containing event details.
    func onNewEventReceived(_ id: String, event: BambuserCommerceSDK.BambuserEventPayload) {
        print("New event received from player [\(id)]: \(event)")

        // Example: Handle specific events (from your grid controller)
        if event.type == "preview-should-expand" {
            /// Pause player if player is playing, otherwise pause it.
            if let player = shoppableVideos.first(where: { $0.id == id }) {
                if player.currentPlayerState == .playing {
                    player.pause()
                } else {
                    player.play()
                }
            }
        }
    }

    /// Handles errors that occur within the Bambuser video player.
    ///
    /// - Parameters:
    ///   - id: The ID of the player where the error occurred.
    ///   - error: The error object containing details about the issue.
    func onErrorOccurred(_ id: String, error: any Error) {
        print("Player error [\(id)]: \(error.localizedDescription)")
    }

    /// Called whenever the playback status of a video changes.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the video.
    ///   - state: The new playback state for the video.
    ///
    /// When a video reaches the `.ended` state and autoplay is enabled,
    /// this method will start the next video in the playlist or carousel.
    func onVideoStatusChanged(_ id: String, state: BambuserVideoState) {
        print("Player status changed to: \(state)")
        guard isAutoplayEnabled else { return }
        if state == .ended {
            /// To build an autoplay behavior, this method can be used to advance to the next video
            /// when current video ends.
            /// You can play next video once the current one ends.
            /// or you can utilize `onVideoProgress` to determine when to play the next video.
            /// Only one approach should be used to avoid conflicts.
            playNextVideo(from: id)
        }
    }

    /// Reports the playback progress of a video.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the video.
    ///   - duration: The total duration of the video, in seconds.
    ///   - currentTime: The current playback time, in seconds.
    ///
    /// This is an **optional** delegate method.
    /// You can implement this if you want to monitor the progress of the playing video,
    /// for example to update a UI progress bar or trigger custom actions when certain thresholds are reached.
    ///
    /// In this implementation, the method checks if there is exactly 1 second left in the video and,
    /// if so, automatically advances to play the next video in the playlist.
    func onVideoProgress(_ id: String, duration: Double, currentTime: Double) {
        print("Video progress for player [\(id)]: duration=\(duration), currentTime=\(currentTime)")

        /// If 1 second left in the video, play next video.
        /// Uncomment the following lines to enable this behavior.
        /// Note that you should comment out `playNextVideo` method inside `onVideoStatusChanged` to avoid conflicts.
//        let timeLeft = Int(duration - currentTime)
//        guard timeLeft == 1 else { return }
//        guard let index = shoppableVideos.firstIndex(where: { $0.id == id }) else { return }
//
//        if layoutMode == .carousel {
//            scrollToVideo(at: index + 1)
//        }
//        playNextVideo(from: id)
    }
}

private extension Array {
    /// Returns the next element in the array after the one matching the predicate, or nil if at the end.
    func next(where predicate: (Element) -> Bool) -> Element? {
        guard let index = self.firstIndex(where: predicate),
              index + 1 < self.count else {
            return nil
        }
        return self[index + 1]
    }
}
