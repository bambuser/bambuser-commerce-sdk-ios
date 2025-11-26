//
//  FeedViewController.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-09-30.
//

import UIKit
import BambuserCommerceSDK

/// A view controller that fetches and displays a vertically paged shoppable video playlist.
///
/// This example shows how to:
/// - Request a playlist from Bambuser
/// - Render one video per full-screen page with vertical paging
/// - Autoplay the visible page and advance to the next on end
///
final class ShoppableVideoViewController: UIViewController {

    // MARK: - Dependencies
    let navManager: NavigationManager

    // MARK: - Data
    private var shoppableVideos: [BambuserPlayerView] = []
    private var videosStatus: [String: Bool] = [:]
    private var currentIndex: Int?

    // MARK: - First-play coordination
    private var pendingInitialPlay = false
    private var firstPlayerReady = false
    private var didLayoutOnce = false
    private var didAppearOnce = false

    // MARK: - UI
    private let stackSpacing: CGFloat = 0

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.isPagingEnabled = true
        sv.decelerationRate = .fast
        sv.delegate = self
        return sv
    }()

    private lazy var videoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = stackSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init
    init(navManager: NavigationManager) {
        self.navManager = navManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        /// Similar to example in BambuserVideoController, it's important to call `cleanup()` on each player view,
        /// to ensure proper resource deallocation when they're no longer needed to avoid memory leaks.
        /// If you don't call this, the player views retain resources and not be deallocated properly.
        /// You can call this in `deinit`, or when you're removing the views from the view hierarchy.
        /// In this example, it's not called since the views are kept for the lifetime of this view controller.
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupScrollView()
        fetchShoppableVideos()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        didAppearOnce = true
        tryStartFirstPlayback()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didLayoutOnce, scrollView.bounds.height > 0 {
            didLayoutOnce = true
            tryStartFirstPlayback()
        }
    }

    // MARK: - Setup
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(videoStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            videoStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            videoStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            videoStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            videoStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            videoStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Fetch Data
    private func fetchShoppableVideos() {
        let bambuserPlayer = BambuserVideoPlayer(server: .US)
        let videoContainerInfo = Show.PlaylistConfig

        Task {
            do {
                let config = BambuserShoppableVideoConfiguration(
                    type: .playlist(videoContainerInfo),
                    events: ["*"],
                    configuration: [
                        "preload": true,
                        "thumbnail": [
                            "enabled": false,
                            "showPlayButton": false,
                            "contentMode": "scaleAspectFill",
                            "preview": nil,
                            "showLoadingIndicator": false
                        ],
                        "previewConfig": [
                            "productAction": "modal",
                            "closedCaptions": "original",
                            "settings": "products:true; title:false; actions:true; productCardMode: thumbnail; autoplay:true",
                        ],
                        "playerConfig": [
                            "buttons": ["product": "inline"],
                            "enableTrackingPoint": false,
                        ]
                    ]
                )

                let results = try await bambuserPlayer.createShoppableVideoPlayerCollection(
                    videoConfiguration: config
                )

                await MainActor.run {
                    setupVideoPlaylist(results.players)
                    pendingInitialPlay = true
                    tryStartFirstPlayback()
                }
            } catch {
                print("Error loading shoppable views: \(error)")
            }
        }
    }

    // MARK: - Build UI
    private func setupVideoPlaylist(_ videoViews: [BambuserPlayerView]) {
        videoStack.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        guard !videoViews.isEmpty else { return }

        shoppableVideos = videoViews
        videosStatus.removeAll()
        currentIndex = nil

        for (index, videoView) in videoViews.enumerated() {
            videoView.delegate = self
            videoView.backgroundColor = .clear
            videoView.translatesAutoresizingMaskIntoConstraints = false
            videoView.pipController?.isEnabled = true
            videoView.pipController?.delegate = self
            videoView.pause()

            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = .clear

            videoStack.addArrangedSubview(container)

            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                container.widthAnchor.constraint(equalTo: videoStack.widthAnchor)
            ])

            container.addSubview(videoView)
            NSLayoutConstraint.activate([
                videoView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                videoView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                videoView.widthAnchor.constraint(equalTo: view.widthAnchor),
                videoView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])

            videosStatus[videoView.id] = false
        }
    }

    // MARK: - Paging helpers
    private func currentPage() -> Int {
        let h = max(scrollView.bounds.height, 1)
        return max(0, min(shoppableVideos.count - 1, Int(round(scrollView.contentOffset.y / h))))
    }

    private func activatePage(_ index: Int) {
        guard shoppableVideos.indices.contains(index) else { return }
        for (i, p) in shoppableVideos.enumerated() {
            if i == index {
                p.play()
            } else {
                p.pause()
            }
        }
        currentIndex = index
    }

    private func scrollToPage(_ index: Int, animated: Bool = true) {
        guard shoppableVideos.indices.contains(index) else { return }
        let h = scrollView.bounds.height
        let offset = CGPoint(x: 0, y: CGFloat(index) * h)
        scrollView.setContentOffset(offset, animated: animated)
    }

    // MARK: - First-play coordinator
    private func tryStartFirstPlayback() {
        guard pendingInitialPlay,
              didAppearOnce,
              didLayoutOnce,
              firstPlayerReady,
              currentIndex == nil || currentIndex == 0,
              !shoppableVideos.isEmpty
        else { return }

        // Ensure we're at page 0 before playing
        scrollToPage(0, animated: false)

        // Defer one runloop to avoid internal transition races
        DispatchQueue.main.async { [weak self] in
            self?.activatePage(0)
        }
        pendingInitialPlay = false
    }
}

// MARK: - UIScrollViewDelegate
extension ShoppableVideoViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        activatePage(currentPage())
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            activatePage(currentPage())
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        activatePage(currentPage())
    }
}

// MARK: - BambuserVideoPlayerDelegate
extension ShoppableVideoViewController: BambuserVideoPlayerDelegate {

    func onNewEventReceived(_ id: String, event: BambuserCommerceSDK.BambuserEventPayload) {
        /// This event is sent when user taps the video.
        /// You can use it to toggle playback or expand/collapse the preview to full experience mode.
        /// or any other custom action you want to trigger on tap.
        if event.type == "preview-should-expand",
           let player = shoppableVideos.first(where: { $0.id == id }) {
            if player.currentPlayerState == .playing {
                player.pause()
            } else {
                player.play()
            }
        }

        /// These events are sent when user taps an action card or a link in the player, e.g a product link.
        if (event.type == "action-card-clicked" || event.type == "open-url"),
           let eventDict = event.data["event"] as? [String: Sendable],
           let urlString = eventDict["url"] as? String,
           let url = URL(string: urlString) {
            navManager.present(sheet: .openWebPage(url), in: .shoppableVideo)
        }
    }

    func onVideoStatusChanged(_ id: String, state: BambuserVideoState) {
        // Track ready state of the first video to coordinate initial playback.
        if shoppableVideos.first?.id == id,
           state == .ready {
            firstPlayerReady = true
            tryStartFirstPlayback()
        }

        if state == .completed {
            // Advance to next video when current ends.
            guard let idx = shoppableVideos.firstIndex(where: { $0.id == id }) else { return }
            let next = idx + 1
            if shoppableVideos.indices.contains(next) {
                scrollToPage(next)
            }
        }
    }

    func onErrorOccurred(_ id: String, error: any Error) {
        print("Player error [\(id)]: \(error.localizedDescription)")
    }

    func onVideoProgress(_ id: String, duration: Double, currentTime: Double) {
        print("Player progress [\(id)]: \(currentTime) / \(duration) seconds")
    }
}

// MARK: - BambuserPictureInPictureDelegate
extension ShoppableVideoViewController: BambuserPictureInPictureDelegate {
    func onPictureInPictureStateChanged(_ id: String, state: BambuserCommerceSDK.PlayerPipState) {
        print("PIP state changed [\(id)]: \(state)")
    }
}
