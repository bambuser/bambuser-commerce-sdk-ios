//
//  FeedViewController.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-09-30.
//

import UIKit
import BambuserCommerceSDK

final class ReelsFeedViewController: UIViewController {
    private let navManager: NavigationManager
    private let startIndex: Int
    private lazy var router = ShoppableVideoEventRouter(navManager: navManager)

    private var players: [BambuserPlayerView] = []
    private var currentIndex: Int = 0
    private var didLayoutOnce = false
    private var didAppearOnce = false
    private var didStartInitialScroll = false

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

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
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(navManager: NavigationManager, startIndex: Int = 0) {
        self.navManager = navManager
        self.startIndex = max(0, startIndex)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupScrollView()
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        activityIndicator.startAnimating()

        router.presenter = self
        router.onStateChanged = { [weak self] id, state in self?.handleStateChange(id: id, state: state) }
        load()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppearOnce = true
        tryAlignInitialPage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLayoutOnce, scrollView.bounds.height > 0 {
            didLayoutOnce = true
            tryAlignInitialPage()
        }
    }

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

    private func load() {
        let sdk = BambuserSDK(server: .US)
        Task {
            do {
                let result = try await sdk.createShoppableVideoPlayerCollection(
                    videoConfiguration: ShoppableVideoConfigs.reels()
                )
                await MainActor.run {
                    setupVideoPlaylist(result.players)
                    tryAlignInitialPage()
                }
            } catch {
                print("Reels load error: \(error)")
            }
        }
    }

    private func setupVideoPlaylist(_ videoViews: [BambuserPlayerView]) {
        videoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !videoViews.isEmpty else { return }

        players = videoViews
        currentIndex = min(startIndex, videoViews.count - 1)
        router.bind(videoViews)

        for videoView in videoViews {
            videoView.backgroundColor = .clear
            videoView.translatesAutoresizingMaskIntoConstraints = false

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
        }
    }

    private func currentPage() -> Int {
        let h = max(scrollView.bounds.height, 1)
        return max(0, min(players.count - 1, Int(round(scrollView.contentOffset.y / h))))
    }

    private func activatePage(_ index: Int) {
        guard players.indices.contains(index) else { return }
        currentIndex = index
        for (i, p) in players.enumerated() where i != index {
            p.pause()
        }
        expandCurrentIfReady()
    }

    private func expandCurrentIfReady() {
        guard players.indices.contains(currentIndex) else { return }
        let active = players[currentIndex]
        guard active.currentPlayerState != .idle,
              active.currentPlayerState != .loading,
              active.currentPlayerState != .error else { return }
        if active.currentPlayerMode == .fullExperience {
            active.play()
        } else {
            Task { @MainActor in
                try? await active.changeMode(to: .fullExperience)
            }
        }
    }

    private func scrollToPage(_ index: Int, animated: Bool = true) {
        guard players.indices.contains(index) else { return }
        let h = scrollView.bounds.height
        scrollView.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * h), animated: animated)
    }

    private func tryAlignInitialPage() {
        guard !didStartInitialScroll, didAppearOnce, didLayoutOnce, !players.isEmpty else { return }
        didStartInitialScroll = true
        scrollToPage(currentIndex, animated: false)
        activatePage(currentIndex)
    }

    private func handleStateChange(id: String, state: BambuserVideoState) {
        if state == .ready {
            activityIndicator.stopAnimating()
            if players.indices.contains(currentIndex),
               players[currentIndex].id == id,
               didStartInitialScroll {
                expandCurrentIfReady()
            }
        }

        if state == .completed {
            guard let idx = players.firstIndex(where: { $0.id == id }) else { return }
            let next = idx + 1
            if players.indices.contains(next) {
                scrollToPage(next)
            }
        }
    }
}

extension ReelsFeedViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if players.indices.contains(currentIndex) {
            players[currentIndex].pause()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        activatePage(currentPage())
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        activatePage(currentPage())
    }
}
