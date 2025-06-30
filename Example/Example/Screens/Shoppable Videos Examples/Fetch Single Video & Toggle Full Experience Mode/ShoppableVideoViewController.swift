//
//  ShoppableVideoViewController.swift
//  Example
//
//  Created by Seemanta on 2025-04-30.
//

import UIKit
import BambuserCommerceSDK

/// A view controller responsible for fetching and displaying a shoppable video playlist in a horizontal carousel.
///
/// This controller demonstrates how to fetch a playlist from Bambuser,
/// display it in a carousel, and handle video playback with autoplay support.
/// You can build your own custom UI based on this example or use the available APIs
/// to create your desired UI interface or behavior.
final class ShoppableVideoViewController: UIViewController {

    // MARK: - Properties

    /// All shoppable video views fetched from Bambuser.
    private var shoppableVideo: BambuserPlayerView?

    /// Flag to enable or disable autoplay of the next video when the current one ends.
    var isAutoplayEnabled: Bool = true

    /// Navigation manager observer ID to identify view.
    var navigationObserverID: UUID?

    /// Navigation manager for handling navigation events within the app.
    let navManager: NavigationManager

    // MARK: - Layout/Animation State

    /// Track current size state (false = normal, true = expanded)
    private var isExpanded: Bool = false

    /// Constraints to modify during animation
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

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

        fetchShoppableVideo()
        setupNavigationObserver()
    }

    // MARK: - Setup

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
            if oldPath.last == .shoppableVideo {
                shoppableVideo?.cleanup()
            }
        }
    }

    // MARK: - Data Fetching & Layout Setup

    /// Fetches a shoppable video playlist from Bambuser and populates the layout.
    private func fetchShoppableVideo() {
        let bambuserPlayer = BambuserVideoPlayer(server: .US)

        Task {
            do {
                /// Configures the Bambuser video player.
                /// - `type`: Specifies the video type and requires a valid show ID.
                /// - `events`: Specifies which events app expects to receive from SDK
                /// - `configuration`: Provides additional player settings.
                /// More information: [Bambuser Player Integration guide](https://bambuser.com/docs/shoppable-video/bam-playlist-integration/)
                let config = BambuserShoppableVideoConfiguration(
                    type: .videoId("suv_CGjT5hb527wvWLaSqY3XPH"),
                    events: ["*"],
                    configuration: [
                        "thumbnail": [
                            "enabled": true,
                            "showPlayButton": true,
                            "contentMode": "scaleAspectFill",
                            "preview": nil
                        ],
                        /// Configuration for shoppable video player.
                        /// Hide products and title in the player.
                        "previewConfig": ["settings": "products:true; title:false; actions:1;"],
                        "playerConfig": [
                            "buttons": [
                                "dismiss": "event",
                                "product": "none"
                            ],
                            "autoplay": true
                        ]
                    ]
                )

                shoppableVideo = try await bambuserPlayer.createShoppableVideoPlayer(
                    videoConfiguration: config
                )
                shoppableVideo?.delegate = self
                await MainActor.run {
                    setupPlayerView()
                }
            } catch {
                print("Error loading shoppable views: \(error)")
            }
        }
    }

    /// Adds the shoppable video player to the center of the screen,
    /// sized at 1/2 screen width and 2x that width for height.
    private func setupPlayerView() {
        guard let shoppableVideo else { return }

        let width = UIScreen.main.bounds.width / 2
        let height = width * 2

        shoppableVideo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shoppableVideo)

        // Remove old constraints if present
        widthConstraint?.isActive = false
        heightConstraint?.isActive = false

        widthConstraint = shoppableVideo.widthAnchor.constraint(equalToConstant: width)
        heightConstraint = shoppableVideo.heightAnchor.constraint(equalToConstant: height)

        NSLayoutConstraint.activate([
            shoppableVideo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shoppableVideo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            widthConstraint!,
            heightConstraint!
        ])
        isExpanded = false
    }

    func switchMode(to mode: InlinePlayerMode) {
        animatePlayerView(expanded: mode == .fullExperience)
        /// Enable or disable Picture-in-Picture (PiP) mode based on the selected mode.
        shoppableVideo?.pipController?.isEnabled = mode == .fullExperience
        Task { @MainActor in
            try await shoppableVideo?.changeMode(to: mode)
        }
    }

    /// Animate player to expanded or normal size.
    private func animatePlayerView(expanded: Bool) {
        guard let widthConstraint, let heightConstraint else { return }
        let targetWidth = expanded ? UIScreen.main.bounds.width * 0.7 : UIScreen.main.bounds.width / 2
        let targetHeight = targetWidth * 2

        widthConstraint.constant = targetWidth
        heightConstraint.constant = targetHeight

        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        isExpanded = expanded
    }
}

// MARK: - BambuserVideoPlayerDelegate

extension ShoppableVideoViewController: BambuserVideoPlayerDelegate {

    /// Handles events received from the Bambuser video player.
    ///
    /// - Parameters:
    ///   - id: The ID of the player emitting the event.
    ///   - event: The event payload containing event details.
    func onNewEventReceived(_ id: String, event: BambuserCommerceSDK.BambuserEventPayload) {
        print("New event received from player [\(id)]: \(event)")

        // Example: Handle specific events
        /// If "preview-should-expand" event is received, switch to full experience mode.
        if event.type == "preview-should-expand" {
            /// When video is tapped, switch to full experience mode.
            /// This will allow the user to interact with the video in full-screen mode.
            /// Full experience mode is similar experience to the Bambuser Live Shopping player.
            guard shoppableVideo?.currentPlayerMode == .preview else {
                return
            }
            /// Important Note:
            /// To ensure a proper user experience, make sure the player view has a minimum size of 320x320 points for full experience mode.
            /// Otherwise, the player may not display correctly.
            /// Full experience mode is designed to provide a rich interactive experience and requires sufficient space to render the video and controls effectively.
            switchMode(to: .fullExperience)
        }

        /// If "X" button is tapped, switch back to preview mode.
        if event.type == "close" {
            switchMode(to: .preview)
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
        if state == .ended {
            /// When the video is ended, switch back to preview mode, if player is in full experience mode.
            guard shoppableVideo?.currentPlayerMode == .fullExperience else {
                return
            }
            switchMode(to: .preview)
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
    }
}
