//
//  StoriesSelector.swift
//  Example
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct StoriesSelectorView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager
    var compact: Bool = false

    func makeUIViewController(context: Context) -> StoriesSelectorViewController {
        StoriesSelectorViewController(navManager: navigationManager, compact: compact)
    }

    func updateUIViewController(_ uiViewController: StoriesSelectorViewController, context: Context) {}
}

final class StoriesSelectorViewController: ShoppableFormatViewController {
    private let compact: Bool
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

    init(navManager: NavigationManager, compact: Bool = false) {
        self.compact = compact
        super.init(navManager: navManager)
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

        let selectorHeight: CGFloat = compact ? 121 : 160
        var constraints: [NSLayoutConstraint] = [
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: selectorHeight),

            row.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: scrollView.topAnchor),
            row.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
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

        router.onStateChanged = { [weak self] _, _ in self?.activityIndicator.stopAnimating() }

        if !StoriesPlayerCache.shared.players.isEmpty {
            setupCircles(StoriesPlayerCache.shared.players)
        } else {
            load()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reattachPlayers()
    }

    private func load() {
        loadPlayers(ShoppableVideoConfigs.stories()) { [weak self] players in
            StoriesPlayerCache.shared.players = players
            self?.setupCircles(players)
            for player in players { player.preload() }
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
    let circleHost: PlayerCardView

    init(index: Int, size: CGFloat = 104, onTap: @escaping (Int) -> Void) {
        circleHost = PlayerCardView(cornerRadius: size / 2) { onTap(index) }
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

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
    }
    required init?(coder: NSCoder) { fatalError() }

    func attach(player: BambuserPlayerView) {
        circleHost.attach(player)
    }
}
