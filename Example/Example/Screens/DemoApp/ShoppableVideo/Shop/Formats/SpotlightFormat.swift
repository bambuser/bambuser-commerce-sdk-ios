//
//  SpotlightFormat.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct SpotlightFormatView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> SpotlightFormatViewController {
        SpotlightFormatViewController(navManager: navigationManager)
    }

    func updateUIViewController(_ uiViewController: SpotlightFormatViewController, context: Context) {}
}

final class SpotlightFormatViewController: ShoppableFormatViewController {
    private var heroIndex: Int = 0
    private var cards: [PlayerCardView] = []

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(heroContainer)
        heroContainer.addSubview(heroLabel)
        view.addSubview(railTitle)
        view.addSubview(railScroll)
        railScroll.addSubview(railStack)

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
            railStack.heightAnchor.constraint(equalTo: railScroll.heightAnchor)
        ])

        router.onStateChanged = { [weak self] id, state in self?.handleState(id: id, state: state) }
        loadPlayers(ShoppableVideoConfigs.spotlight()) { [weak self] in self?.setupHeroAndRail($0) }
    }

    private func setupHeroAndRail(_ list: [BambuserPlayerView]) {
        guard !list.isEmpty else { return }
        players = list
        router.bind(list)

        cards = list.indices.map { index in
            PlayerCardView(cornerRadius: 12) { [weak self] in self?.promote(index: index) }
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
            card.attach(players[index])
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
