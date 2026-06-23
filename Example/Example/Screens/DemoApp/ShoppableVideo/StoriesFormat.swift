//
//  StoriesFormat.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

@MainActor
final class StoriesPlayerCache {
    static let shared = StoriesPlayerCache()
    private init() {}
    var players: [BambuserPlayerView] = []
}

struct StoriesFeedView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager
    var startIndex: Int = 0

    func makeUIViewController(context: Context) -> StoriesFeedViewController {
        StoriesFeedViewController(navManager: navigationManager, startIndex: startIndex)
    }

    func updateUIViewController(_ uiViewController: StoriesFeedViewController, context: Context) {}
}

final class StoriesFeedViewController: UIViewController {
    private let navManager: NavigationManager
    private let startIndex: Int
    private lazy var router = ShoppableVideoEventRouter(navManager: navManager)

    private var players: [BambuserPlayerView] = []
    private var currentIndex: Int = 0
    private var didAlignInitial = false
    private var didStartPlayback = false
    private var didAppearOnce = false

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .large)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.hidesWhenStopped = true
        return i
    }()

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
        self.navManager = navManager
        self.startIndex = max(0, startIndex)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(pageStack)
        view.addSubview(progressBar)
        view.addSubview(activityIndicator)

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
            progressBar.heightAnchor.constraint(equalToConstant: 3),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        router.presenter = self
        router.onStateChanged = { [weak self] id, state in self?.handleState(id: id, state: state) }
        router.onProgress = { [weak self] id, duration, current in self?.handleProgress(id: id, duration: duration, current: current) }
        router.onPreviewShouldExpand = { [weak self] id in self?.togglePlayback(id: id) }

        activityIndicator.startAnimating()
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

        let sdk = BambuserSDK(server: .US)
        Task {
            do {
                let result = try await sdk.createShoppableVideoPlayerCollection(
                    videoConfiguration: ShoppableVideoConfigs.stories()
                )
                await MainActor.run {
                    StoriesPlayerCache.shared.players = result.players
                    self.setupPlayers(result.players)
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    self.tryStartFirstPlayback()
                }
            } catch {
                print("Stories load error: \(error)")
            }
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

struct StoriesSelectorView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager
    var compact: Bool = false

    func makeUIViewController(context: Context) -> StoriesSelectorViewController {
        StoriesSelectorViewController(navManager: navigationManager, compact: compact)
    }

    func updateUIViewController(_ uiViewController: StoriesSelectorViewController, context: Context) {}
}

final class StoriesSelectorViewController: UIViewController {
    private let navManager: NavigationManager
    private let compact: Bool
    private lazy var router = ShoppableVideoEventRouter(navManager: navManager)
    private var players: [BambuserPlayerView] = []
    private var cells: [StoryCircleCell] = []

    private lazy var heading: UILabel = {
        let l = UILabel()
        l.text = "Stories"
        l.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var hint: UILabel = {
        let l = UILabel()
        l.text = "Tap a circle to watch full-screen"
        l.font = .preferredFont(forTextStyle: .subheadline)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceHorizontal = true
        s.showsHorizontalScrollIndicator = false
        return s
    }()

    private lazy var row: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 14
        s.alignment = .top
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .large)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.hidesWhenStopped = true
        return i
    }()

    init(navManager: NavigationManager, compact: Bool = false) {
        self.navManager = navManager
        self.compact = compact
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = compact ? .clear : .systemBackground

        if !compact {
            view.addSubview(heading)
            view.addSubview(hint)
        }
        view.addSubview(scrollView)
        scrollView.addSubview(row)
        view.addSubview(activityIndicator)

        let selectorHeight: CGFloat = compact ? 121 : 160
        var constraints: [NSLayoutConstraint] = [
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: selectorHeight),

            row.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: scrollView.topAnchor),
            row.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        if compact {
            constraints.append(scrollView.topAnchor.constraint(equalTo: view.topAnchor))
        } else {
            constraints += [
                heading.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                heading.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                heading.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

                hint.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
                hint.trailingAnchor.constraint(equalTo: heading.trailingAnchor),
                hint.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 2),

                scrollView.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 24)
            ]
        }
        NSLayoutConstraint.activate(constraints)

        router.presenter = self
        router.onStateChanged = { [weak self] _, _ in self?.activityIndicator.stopAnimating() }

        if !StoriesPlayerCache.shared.players.isEmpty {
            setupCircles(StoriesPlayerCache.shared.players)
            activityIndicator.stopAnimating()
        } else {
            activityIndicator.startAnimating()
            load()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reattachPlayers()
    }

    private func load() {
        let sdk = BambuserSDK(server: .US)
        Task {
            do {
                let result = try await sdk.createShoppableVideoPlayerCollection(
                    videoConfiguration: ShoppableVideoConfigs.stories()
                )
                await MainActor.run {
                    StoriesPlayerCache.shared.players = result.players
                    self.setupCircles(result.players)
                    for player in result.players { player.preload() }
                }
            } catch {
                print("Stories selector load error: \(error)")
            }
        }
    }

    private func setupCircles(_ list: [BambuserPlayerView]) {
        players = list
        router.bind(list)

        cells.removeAll()
        row.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let circleSize: CGFloat = compact ? 101 : 120
        for (index, player) in list.enumerated() {
            let cell = StoryCircleCell(index: index, size: circleSize) { [weak self] tappedIndex in
                self?.navManager.push(.storiesFeed(startIndex: tappedIndex), in: .shoppableVideo)
            }
            cell.attach(player: player)
            cells.append(cell)
            row.addArrangedSubview(cell)
        }
    }

    private func reattachPlayers() {
        guard !cells.isEmpty, !players.isEmpty else { return }
        router.bind(players)
        for (index, cell) in cells.enumerated() where players.indices.contains(index) {
            let player = players[index]
            if player.superview !== cell.circleHost {
                player.removeFromSuperview()
                player.resetPlayer()
                cell.attach(player: player)
            }
        }
    }
}

private final class StoryCircleCell: UIView {
    private let index: Int
    private let onTap: (Int) -> Void
    let circleHost = UIView()

    init(index: Int, size: CGFloat = 104, onTap: @escaping (Int) -> Void) {
        self.index = index
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        circleHost.translatesAutoresizingMaskIntoConstraints = false
        circleHost.backgroundColor = .secondarySystemBackground
        circleHost.layer.cornerRadius = size / 2
        circleHost.clipsToBounds = true
        circleHost.layer.borderWidth = 2
        circleHost.layer.borderColor = UIColor.systemPink.cgColor

        addSubview(circleHost)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),

            circleHost.topAnchor.constraint(equalTo: topAnchor),
            circleHost.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleHost.widthAnchor.constraint(equalToConstant: size),
            circleHost.heightAnchor.constraint(equalToConstant: size),
            circleHost.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(gesture)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }

    func attach(player: BambuserPlayerView) {
        player.translatesAutoresizingMaskIntoConstraints = false
        player.isUserInteractionEnabled = false
        circleHost.addSubview(player)
        NSLayoutConstraint.activate([
            player.leadingAnchor.constraint(equalTo: circleHost.leadingAnchor),
            player.trailingAnchor.constraint(equalTo: circleHost.trailingAnchor),
            player.topAnchor.constraint(equalTo: circleHost.topAnchor),
            player.bottomAnchor.constraint(equalTo: circleHost.bottomAnchor)
        ])
    }

    @objc private func handleTap() { onTap(index) }
}

final class StoriesProgressBar: UIView {
    private var tracks: [UIView] = []
    private var fills: [UIView] = []
    private var widthConstraints: [NSLayoutConstraint] = []
    private var activeIndex: Int = 0
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(segmentCount: Int) {
        tracks.forEach { $0.removeFromSuperview() }
        tracks.removeAll()
        fills.removeAll()
        widthConstraints.removeAll()

        for _ in 0..<segmentCount {
            let track = UIView()
            track.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            track.layer.cornerRadius = 1.5
            track.clipsToBounds = true
            track.translatesAutoresizingMaskIntoConstraints = false

            let fill = UIView()
            fill.backgroundColor = .white
            fill.translatesAutoresizingMaskIntoConstraints = false
            track.addSubview(fill)

            let widthConstraint = fill.widthAnchor.constraint(equalToConstant: 0)
            NSLayoutConstraint.activate([
                fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
                fill.topAnchor.constraint(equalTo: track.topAnchor),
                fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
                widthConstraint
            ])

            stack.addArrangedSubview(track)
            tracks.append(track)
            fills.append(fill)
            widthConstraints.append(widthConstraint)
        }
    }

    func setActiveSegment(_ index: Int) {
        activeIndex = index
        for i in fills.indices {
            replaceWidth(at: i, ratio: i < index ? 1 : 0)
        }
    }

    func setProgress(_ ratio: CGFloat) {
        guard fills.indices.contains(activeIndex) else { return }
        replaceWidth(at: activeIndex, ratio: max(0, min(1, ratio)))
    }

    func fillActiveSegment() {
        setProgress(1)
    }

    private func replaceWidth(at index: Int, ratio: CGFloat) {
        widthConstraints[index].isActive = false
        let fill = fills[index]
        let track = tracks[index]
        let newConstraint: NSLayoutConstraint
        if ratio <= 0 {
            newConstraint = fill.widthAnchor.constraint(equalToConstant: 0)
        } else if ratio >= 1 {
            newConstraint = fill.widthAnchor.constraint(equalTo: track.widthAnchor)
        } else {
            newConstraint = fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: ratio)
        }
        newConstraint.isActive = true
        widthConstraints[index] = newConstraint
    }
}
