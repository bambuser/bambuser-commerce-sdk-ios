//
//  InitializeVideoViewController.swift
//  Example
//
//  Created by Saeid Basirnia on 3/17/25.
//

import UIKit
import BambuserCommerceSDK

/// A view controller responsible for initializing and displaying a Bambuser Commerce SDK.
final class InitializeVideoViewController: UIViewController {

    /// The player view used for displaying the video.
    var playerView: BambuserPlayerView?

    /// Navigation manager for handling navigation events within the app.
    let navManager: NavigationManager

    /// Navigation manager observer ID to identify view
    var navigationObserverID: UUID?

    init(navManager: NavigationManager) {
        self.navManager = navManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        /// Initializes the Bambuser player instance.
        /// - The `server` parameter determines whether the player connects to the US or EU server.
        let bambuserPlayer = BambuserVideoPlayer(server: .US) // Select organization server (US or EU)

        /// Configures the Bambuser video player.
        /// - `type`: Specifies the video type and requires a valid show ID.
        /// - `events`: Specifies which events app expects to receive from SDK
        /// - `configuration`: Provides additional player settings.
        /// More information: [Bambuser Player API Reference](https://bambuser.com/docs/live/player-api-reference/)
        let config = BambuserVideoConfiguration(
            type: .live(id: "aHT8jNIYeDbh8vrNJ8ju"), // Pass the show ID
            events: ["*"], // Pass `["*"]` to receive **all available events** from the SDK.
            configuration: [
                "buttons": ["dismiss": "none"],
                "autoplay": true
            ] // Pass required Bambuser Player configuration
        )

        /// Creates the player view using the `createPlayerView` method of `BambuserVideoPlayer`.
        /// - `videoConfiguration`: The configuration object created earlier, defining the player settings.
        /// - `ignoredSafeAreaEdges`: Determines which safe area edges should be ignored.
        ///   - Use `.init(.all)` to ignore all edges, making the player fullscreen.
        ///   - Use `.init(.bottom)`, `.init(.top)`, etc., to selectively ignore specific edges.
        ///   - Use `.init(.bottom, .top)`, etc., to ignore multiple specific edges.
        let pView = bambuserPlayer.createPlayerView(
            videoConfiguration: config,
            ignoredSafeAreaEdges: .init(.bottom)
        )
        pView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pView)

        NSLayoutConstraint.activate([
            pView.topAnchor.constraint(equalTo: view.topAnchor),
            pView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        playerView = pView

        /// Setup navigation observe id and pop behavior
        navigationObserverID = navManager.addPopObserver { [weak self] oldPath, newPath in
            guard let self = self else { return }

            if oldPath.last == .initializingShow {
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
                playerView?.cleanup()
            }
        }
    }

    deinit {
        navManager.removePopObserver(navigationObserverID)
    }
}
