//
//  CarouselFormat.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct CarouselFeedView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager
    var compact: Bool = false

    func makeUIViewController(context: Context) -> CarouselFeedViewController {
        CarouselFeedViewController(navManager: navigationManager, compact: compact)
    }

    func updateUIViewController(_ uiViewController: CarouselFeedViewController, context: Context) {}
}

final class CarouselFeedViewController: UIViewController {
    private let navManager: NavigationManager
    private let compact: Bool
    private lazy var router = ShoppableVideoEventRouter(navManager: navManager)
    private var players: [BambuserPlayerView] = []
    private var activeId: String?

    private lazy var header: UILabel = {
        let l = UILabel()
        l.text = "Featured shoppable videos"
        l.font = .preferredFont(forTextStyle: .title3).bold()
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subheader: UILabel = {
        let l = UILabel()
        l.text = "Tap a card to play it inline"
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
        s.spacing = 12
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
            view.addSubview(header)
            view.addSubview(subheader)
        }
        view.addSubview(scrollView)
        scrollView.addSubview(row)
        view.addSubview(activityIndicator)

        var constraints: [NSLayoutConstraint] = [
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 300),

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
                header.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                header.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

                subheader.leadingAnchor.constraint(equalTo: header.leadingAnchor),
                subheader.trailingAnchor.constraint(equalTo: header.trailingAnchor),
                subheader.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 2),

                scrollView.topAnchor.constraint(equalTo: subheader.bottomAnchor, constant: 12)
            ]
        }
        NSLayoutConstraint.activate(constraints)

        router.presenter = self
        router.onStateChanged = { [weak self] id, state in self?.handleState(id: id, state: state) }
        router.onThumbnailTapped = { [weak self] id in self?.handleThumbnailTap(id: id) }

        activityIndicator.startAnimating()
        load()
    }

    private func load() {
        let sdk = BambuserSDK(server: .US)
        Task {
            do {
                let result = try await sdk.createShoppableVideoPlayerCollection(
                    videoConfiguration: ShoppableVideoConfigs.carousel()
                )
                await MainActor.run { self.setupRow(result.players) }
            } catch {
                print("Carousel load error: \(error)")
            }
        }
    }

    private func setupRow(_ list: [BambuserPlayerView]) {
        players = list
        router.bind(list)
        activityIndicator.stopAnimating()

        for player in list {
            let card = CarouselCard()
            card.attach(player: player)
            row.addArrangedSubview(card)
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: 170),
                card.heightAnchor.constraint(equalTo: row.heightAnchor)
            ])
        }
    }

    private func handleThumbnailTap(id: String) {
        guard let tapped = players.first(where: { $0.id == id }) else { return }
        activeId = id

        for p in players where p.id != id {
            p.resetPlayer()
        }
        tapped.play()
    }

    private func handleState(id: String, state: BambuserVideoState) {
        if state == .completed, id == activeId,
           let player = players.first(where: { $0.id == id }) {
            player.resetPlayer()
            activeId = nil
        }
    }
}

private final class CarouselCard: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        clipsToBounds = true
    }
    required init?(coder: NSCoder) { fatalError() }

    func attach(player: BambuserPlayerView) {
        player.translatesAutoresizingMaskIntoConstraints = false
        addSubview(player)
        NSLayoutConstraint.activate([
            player.leadingAnchor.constraint(equalTo: leadingAnchor),
            player.trailingAnchor.constraint(equalTo: trailingAnchor),
            player.topAnchor.constraint(equalTo: topAnchor),
            player.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

private extension UIFont {
    func bold() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) ?? fontDescriptor
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
