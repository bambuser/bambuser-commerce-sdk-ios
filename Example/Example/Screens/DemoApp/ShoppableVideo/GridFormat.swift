//
//  GridFormat.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct GridFeedView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> GridFeedViewController {
        GridFeedViewController(navManager: navigationManager)
    }

    func updateUIViewController(_ uiViewController: GridFeedViewController, context: Context) {}
}

final class GridFeedViewController: UIViewController {
    private let navManager: NavigationManager
    private lazy var router = ShoppableVideoEventRouter(navManager: navManager)

    private var players: [BambuserPlayerView] = []
    private var activeId: String?

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceVertical = true
        return s
    }()

    private lazy var grid: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .large)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.hidesWhenStopped = true
        return i
    }()

    init(navManager: NavigationManager) {
        self.navManager = navManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(grid)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            grid.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8),
            grid.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8),
            grid.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            grid.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            grid.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

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
                    videoConfiguration: ShoppableVideoConfigs.grid()
                )
                await MainActor.run { self.setupGrid(result.players) }
            } catch {
                print("Grid load error: \(error)")
            }
        }
    }

    private func setupGrid(_ list: [BambuserPlayerView]) {
        players = list
        router.bind(list)
        activityIndicator.stopAnimating()

        var rowStack: UIStackView?
        for (index, player) in list.enumerated() {
            if index.isMultiple(of: 2) {
                let row = UIStackView()
                row.axis = .horizontal
                row.spacing = 8
                row.distribution = .fillEqually
                row.translatesAutoresizingMaskIntoConstraints = false
                grid.addArrangedSubview(row)
                rowStack = row
            }

            let cell = GridCell()
            cell.attach(player: player)
            rowStack?.addArrangedSubview(cell)
            NSLayoutConstraint.activate([
                cell.heightAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 16.0 / 9.0)
            ])
        }

        if let last = grid.arrangedSubviews.last as? UIStackView,
           last.arrangedSubviews.count == 1 {
            let spacer = UIView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            last.addArrangedSubview(spacer)
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

private final class GridCell: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
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
