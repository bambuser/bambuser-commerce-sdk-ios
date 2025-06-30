//
//  ShoppableVideoWithSKUViewController.swift
//  Example
//
//  Created by Seemanta on 2025-04-30.
//

import UIKit
import BambuserCommerceSDK

/// This view controller fetches videos from Bambuser's shoppable video service using a specific SKU.
///
/// The codes and examples presented here are for demonstration how to fetch a shoppable video playlist,
/// display them in a grid layout, and handle video playback.
/// You can build your own custom UI based on this example or use available APIs
/// to create your desired UI interface or behavior.
final class ShoppableVideoWithSKUViewController: UIViewController {

    // MARK: - Properties
    /// All shoppable video views fetched from Bambuser.
    private var shoppableVideos: [BambuserPlayerView] = []

    /// Play status for each video by its ID.
    /// Tracks whether a video is played or not.
    /// This is used to demonstrate how to manage video states for
    /// creating a UI e.g grid and autoplay functionality.
    private var videosStatus: [String: Bool] = [:]

    /// The currently playing video index, or nil if none.
    private var currentIndex: Int?

    /// Navigation manager observer ID to identify view.
    var navigationObserverID: UUID?

    /// Navigation manager for handling navigation events within the app.
    let navManager: NavigationManager

    // MARK: - Layout Constants
    private let stackSpacing: CGFloat = 16
    private let scrollPadding: CGFloat = 20
    private var videoWidth: CGFloat { UIScreen.main.bounds.width * 0.8 }
    private var videoHeight: CGFloat { videoWidth } // or whatever aspect you want

    // MARK: - UI

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.isPagingEnabled = false
        return sv
    }()

    /// StackView that holds all video players horizontally.
    private lazy var videoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = stackSpacing
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

    /// Sets up the scroll view and embeds the horizontal stack view.
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(videoStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            videoStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: stackSpacing),
            videoStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -stackSpacing),
            videoStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: stackSpacing),
            videoStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -stackSpacing),
            videoStack.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -2 * stackSpacing)
        ])
    }

    /// Sets up a navigation observer for the current view controller instance.
    /// When this view is popped from the navigation stack (specifically, when leaving `.productHydration`),
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
            if oldPath.last == .shoppableVideoSKU {
                self.shoppableVideos.forEach { $0.cleanup() }
            }
        }
    }

    // MARK: - Data Fetching & Player Setup

    /// Fetches shoppable videos from Bambuser for a given SKU and builds out the UI playlist.
    private func fetchShoppableVideos() {
        let bambuserPlayer = BambuserVideoPlayer(server: .US)
        /// Video container info for the SKU to fetch.
        /// This should match the SKU you want to display.
        /// This will fetch all videos associated with the SKU.
        let videoContainerInfo = BambuserShoppableVideoSkuInfo(
            orgId: "BdTubpTeJwzvYHljZiy4",
            sku: "b7c5"
        )

        Task {
            do {
                /// Configures the Bambuser video player.
                /// - `type`: Specifies the video type and requires a valid show ID.
                /// - `events`: Specifies which events app expects to receive from SDK
                /// - `configuration`: Provides additional player settings.
                /// More information: [Bambuser Player Integration guide](https://bambuser.com/docs/shoppable-video/bam-playlist-integration/)
                let config = BambuserShoppableVideoConfiguration(
                    type: .sku(videoContainerInfo),
                    events: ["*"],
                    configuration: [
                        "thumbnail": [
                            "enabled": true,
                            "showPlayButton": true,
                            "contentMode": "scaleAspectFill",
                            "preview": nil
                        ],
                        "previewConfig": ["settings": "products:true; title: false; actions: true"],
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
                    setupVideoPlaylist(results.players)
                }
            } catch {
                print("Error loading shoppable views: \(error)")
            }
        }
    }

    /// Lays out the playlist horizontally, setting delegates and tap gestures.
    /// - Parameter videoViews: Array of BambuserPlayerViews to show.
    private func setupVideoPlaylist(_ videoViews: [BambuserPlayerView]) {
        // Remove any existing arrangedSubviews
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
            videoView.heightAnchor.constraint(equalToConstant: videoHeight).isActive = true

            // Assign status tracking if needed
            videosStatus[videoView.id] = false

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            videoView.addGestureRecognizer(tap)

            videoStack.addArrangedSubview(videoView)
        }
    }

    // MARK: - Video Playback Controls

    /// Handles tap gestures to play the tapped video.
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let tapped = gesture.view as? BambuserPlayerView else { return }
        let tappedId = tapped.id
        guard let index = shoppableVideos.firstIndex(where: { $0.id == tappedId }) else { return }
        playVideo(at: index)
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
        scrollToVideo(at: idx + 1)
    }

    /// Scrolls the scrollView to make the selected video visible, with optional padding.
    private func scrollToVideo(at index: Int) {
        guard shoppableVideos.indices.contains(index) else { return }
        let targetView = shoppableVideos[index]
        let targetRect = targetView.frame.insetBy(dx: -scrollPadding, dy: -scrollPadding)
        scrollView.scrollRectToVisible(targetRect, animated: true)
    }
}

// MARK: - BambuserVideoPlayerDelegate

extension ShoppableVideoWithSKUViewController: BambuserVideoPlayerDelegate {

    /// Handles events received from the Bambuser video player.
    ///
    /// - Parameters:
    ///   - id: The ID of the player emitting the event.
    ///   - event: The event payload containing event details.
    func onNewEventReceived(_ id: String, event: BambuserCommerceSDK.BambuserEventPayload) {
        print("New event received from player [\(id)]: \(event)")

        // Example: Handle specific events
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
    /// Use this method to respond to changes such as play, pause, or end events.
    /// In this implementation, when the video reaches the `.ended` state,
    /// the next video in the playlist will automatically begin playing (autoplay behavior).
    func onVideoStatusChanged(_ id: String, state: BambuserVideoState) {
        print("Player status changed to: \(state)")

        /// To build an autoplay behavior, this method can be used to advance to the next video
        /// when current video ends.
        /// You can play next video once the current one ends.
        /// or you can utilize `onVideoProgress` to determine when to play the next video.
        /// Only one approach should be used to avoid conflicts.
        if state == .ended {
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
        /// If 1 second left in the video, play next video.
        /// Uncomment the following lines to enable this behavior.
        /// Note that you should comment out `playNextVideo` method inside `onVideoStatusChanged` to avoid conflicts.
//        let timeLeft = Int(duration - currentTime)
//        guard timeLeft == 1 else { return }
//        playNextVideo(from: id)
    }
}
