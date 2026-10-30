//
//  StoriesFeed.swift
//  Example
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct StoriesFeedView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager
    var startIndex: Int = 0

    func makeUIViewController(context: Context) -> StoriesFeedViewController {
        StoriesFeedViewController(navManager: navigationManager, startIndex: startIndex)
    }

    func updateUIViewController(_ uiViewController: StoriesFeedViewController, context: Context) {}
}

final class StoriesFeedViewController: ShoppableFormatViewController {
    private let startIndex: Int
    private var currentIndex: Int = 0
    private var didAlignInitial = false
    private var didStartPlayback = false
    private var didAppearOnce = false

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.decelerationRate = .fast
        sv.alwaysBounceVertical = false
        sv.alwaysBounceHorizontal = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.delegate = self
        return sv
    }()

    private lazy var pageStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var progressBar: StoriesProgressBar = {
        let p = StoriesProgressBar()
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()

    init(navManager: NavigationManager, startIndex: Int = 0) {
        self.startIndex = max(0, startIndex)
        super.init(navManager: navManager)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(pageStack)
        view.addSubview(progressBar)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            pageStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            pageStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            pageStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            pageStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            pageStack.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressBar.heightAnchor.constraint(equalToConstant: 3)
        ])

        router.onStateChanged = { [weak self] id, state in self?.handleState(id: id, state: state) }
        router.onProgress = { [weak self] id, duration, current in self?.handleProgress(id: id, duration: duration, current: current) }
        router.onPreviewShouldExpand = { [weak self] id in self?.togglePlayback(id: id) }

        load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didAppearOnce = true
        tryStartFirstPlayback()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        alignInitialPageIfNeeded()
    }

    private func alignInitialPageIfNeeded() {
        guard !didAlignInitial,
              scrollView.bounds.width > 0,
              !players.isEmpty else { return }
        didAlignInitial = true
        let target = min(startIndex, players.count - 1)
        currentIndex = target
        progressBar.setActiveSegment(target)
        scrollView.setContentOffset(
            CGPoint(x: CGFloat(target) * scrollView.bounds.width, y: 0),
            animated: false
        )
    }

    private func load() {
        let cached = StoriesPlayerCache.shared.players
        if !cached.isEmpty {
            for player in cached { player.removeFromSuperview() }
            setupPlayers(cached)
            activityIndicator.stopAnimating()
            view.setNeedsLayout()
            view.layoutIfNeeded()
            tryStartFirstPlayback()
            return
        }

        loadPlayers(ShoppableVideoConfigs.stories()) { [weak self] players in
            guard let self else { return }
            StoriesPlayerCache.shared.players = players
            self.setupPlayers(players)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.tryStartFirstPlayback()
        }
    }

    private func setupPlayers(_ list: [BambuserPlayerView]) {
        guard !list.isEmpty else { return }
        players = list
        router.bind(list)
        progressBar.configure(segmentCount: list.count)

        for player in list {
            player.translatesAutoresizingMaskIntoConstraints = false
            player.backgroundColor = .clear
            player.isUserInteractionEnabled = true
            player.pause()

            let page = UIView()
            page.translatesAutoresizingMaskIntoConstraints = false
            page.backgroundColor = .black
            page.addSubview(player)

            pageStack.addArrangedSubview(page)
            NSLayoutConstraint.activate([
                page.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                page.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                player.leadingAnchor.constraint(equalTo: page.leadingAnchor),
                player.trailingAnchor.constraint(equalTo: page.trailingAnchor),
                player.topAnchor.constraint(equalTo: page.topAnchor),
                player.bottomAnchor.constraint(equalTo: page.bottomAnchor)
            ])
        }
    }

    private func tryStartFirstPlayback() {
        alignInitialPageIfNeeded()
        guard !didStartPlayback,
              didAppearOnce,
              didAlignInitial,
              !players.isEmpty else { return }
        let resolvedStart = min(startIndex, max(0, players.count - 1))
        guard players[resolvedStart].currentPlayerState != .idle,
              players[resolvedStart].currentPlayerState != .loading else { return }
        didStartPlayback = true
        activatePage(currentIndex)
    }

    private func currentPage() -> Int {
        let w = max(scrollView.bounds.width, 1)
        return max(0, min(players.count - 1, Int(round(scrollView.contentOffset.x / w))))
    }

    private func scrollToPage(_ index: Int, animated: Bool = true) {
        guard players.indices.contains(index) else { return }
        let w = scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * w, y: 0), animated: animated)
    }

    private func activatePage(_ index: Int) {
        guard players.indices.contains(index) else { return }
        currentIndex = index
        progressBar.setActiveSegment(index)

        for (i, p) in players.enumerated() where i != index {
            p.pause()
            p.seek(to: 0)
        }
        players[index].play()
    }

    private func togglePlayback(id: String) {
        guard let player = players.first(where: { $0.id == id }) else { return }
        if player.currentPlayerState == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    private func handleState(id: String, state: BambuserVideoState) {
        if state == .ready {
            activityIndicator.stopAnimating()
            tryStartFirstPlayback()
        }

        if state == .completed {
            guard let idx = players.firstIndex(where: { $0.id == id }) else { return }
            let next = idx + 1
            if players.indices.contains(next) {
                scrollToPage(next)
            } else {
                progressBar.fillActiveSegment()
            }
        }
    }

    private func handleProgress(id: String, duration: Double, current: Double) {
        guard players.indices.contains(currentIndex),
              players[currentIndex].id == id,
              duration > 0 else { return }
        progressBar.setProgress(CGFloat(current / duration))
    }
}

extension StoriesFeedViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let w = max(scrollView.bounds.width, 1)
        let target = max(0, min(players.count - 1, Int(round(targetContentOffset.pointee.x / w))))
        activatePage(target)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        activatePage(currentPage())
    }
}
