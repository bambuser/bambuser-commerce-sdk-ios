//
//  SpotlightFormat.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct SpotlightFeedView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> SpotlightFeedViewController {
        SpotlightFeedViewController(navManager: navigationManager)
    }

    func updateUIViewController(_ uiViewController: SpotlightFeedViewController, context: Context) {}
}

final class SpotlightFeedViewController: UIViewController {
    private let navManager: NavigationManager
    private lazy var router = ShoppableVideoEventRouter(navManager: navManager)
    private var players: [BambuserPlayerView] = []
    private var heroIndex: Int = 0

    private lazy var heroContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private lazy var heroLabel: UILabel = {
        let l = UILabel()
        l.text = "Featured"
        l.font = .preferredFont(forTextStyle: .caption1)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        l.textAlignment = .center
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        return l
    }()

    private lazy var railTitle: UILabel = {
        let l = UILabel()
        l.text = "More videos"
        l.font = .preferredFont(forTextStyle: .headline)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var railScroll: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceHorizontal = true
        s.showsHorizontalScrollIndicator = false
        return s
    }()

    private lazy var railStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .large)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.hidesWhenStopped = true
        return i
    }()

    private var cards: [SpotlightRailCard] = []

    init(navManager: NavigationManager) {
        self.navManager = navManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(heroContainer)
        heroContainer.addSubview(heroLabel)
        view.addSubview(railTitle)
        view.addSubview(railScroll)
        railScroll.addSubview(railStack)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            heroContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            heroContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            heroContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            heroContainer.heightAnchor.constraint(equalTo: heroContainer.widthAnchor, multiplier: 0.75),

            heroLabel.topAnchor.constraint(equalTo: heroContainer.topAnchor, constant: 10),
            heroLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 10),
            heroLabel.widthAnchor.constraint(equalToConstant: 72),
            heroLabel.heightAnchor.constraint(equalToConstant: 22),

            railTitle.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            railTitle.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            railTitle.topAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: 16),

            railScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            railScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            railScroll.topAnchor.constraint(equalTo: railTitle.bottomAnchor, constant: 8),
            railScroll.heightAnchor.constraint(equalToConstant: 220),

            railStack.leadingAnchor.constraint(equalTo: railScroll.leadingAnchor, constant: 16),
            railStack.trailingAnchor.constraint(equalTo: railScroll.trailingAnchor, constant: -16),
            railStack.topAnchor.constraint(equalTo: railScroll.topAnchor),
            railStack.bottomAnchor.constraint(equalTo: railScroll.bottomAnchor),
            railStack.heightAnchor.constraint(equalTo: railScroll.heightAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        router.presenter = self
        router.onStateChanged = { [weak self] id, state in self?.handleState(id: id, state: state) }
        activityIndicator.startAnimating()
        load()
    }

    private func load() {
        let sdk = BambuserSDK(server: .US)
        Task {
            do {
                let result = try await sdk.createShoppableVideoPlayerCollection(
                    videoConfiguration: ShoppableVideoConfigs.spotlight()
                )
                await MainActor.run { self.setupHeroAndRail(result.players) }
            } catch {
                print("Spotlight load error: \(error)")
            }
        }
    }

    private func setupHeroAndRail(_ list: [BambuserPlayerView]) {
        guard !list.isEmpty else { return }
        players = list
        router.bind(list)

        for index in list.indices {
            let card = SpotlightRailCard(index: index) { [weak self] tapped in self?.promote(index: tapped) }
            cards.append(card)
        }

        rebuildLayout()
    }

    private func rebuildLayout() {
        heroContainer.subviews.filter { $0 is BambuserPlayerView }.forEach { $0.removeFromSuperview() }
        railStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cards.forEach { $0.detachPlayer() }

        guard players.indices.contains(heroIndex) else { return }
        let hero = players[heroIndex]
        hero.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.insertSubview(hero, belowSubview: heroLabel)
        NSLayoutConstraint.activate([
            hero.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            hero.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            hero.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            hero.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor)
        ])

        for (index, card) in cards.enumerated() where index != heroIndex {
            card.attach(player: players[index])
            railStack.addArrangedSubview(card)
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: 140),
                card.heightAnchor.constraint(equalTo: railStack.heightAnchor)
            ])
        }
    }

    private func promote(index: Int) {
        guard players.indices.contains(index), index != heroIndex else { return }
        players[heroIndex].resetPlayer()
        heroIndex = index
        rebuildLayout()
        expandHeroIfReady()
    }

    private func handleState(id: String, state: BambuserVideoState) {
        if state == .ready {
            activityIndicator.stopAnimating()
            if players.indices.contains(heroIndex), players[heroIndex].id == id {
                expandHeroIfReady()
            }
        }
    }

    private func expandHeroIfReady() {
        guard players.indices.contains(heroIndex) else { return }
        let hero = players[heroIndex]
        guard hero.currentPlayerMode != .fullExperience else { return }
        Task { @MainActor in
            try? await hero.changeMode(to: .fullExperience)
        }
    }
}

private final class SpotlightRailCard: UIView {
    private let index: Int
    private let onTap: (Int) -> Void
    private weak var attachedPlayer: BambuserPlayerView?

    init(index: Int, onTap: @escaping (Int) -> Void) {
        self.index = index
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        clipsToBounds = true

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(gesture)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }

    func attach(player: BambuserPlayerView) {
        player.translatesAutoresizingMaskIntoConstraints = false
        player.isUserInteractionEnabled = false
        addSubview(player)
        NSLayoutConstraint.activate([
            player.leadingAnchor.constraint(equalTo: leadingAnchor),
            player.trailingAnchor.constraint(equalTo: trailingAnchor),
            player.topAnchor.constraint(equalTo: topAnchor),
            player.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        attachedPlayer = player
    }

    func detachPlayer() {
        attachedPlayer?.removeFromSuperview()
        attachedPlayer = nil
    }

    @objc private func handleTap() { onTap(index) }
}
