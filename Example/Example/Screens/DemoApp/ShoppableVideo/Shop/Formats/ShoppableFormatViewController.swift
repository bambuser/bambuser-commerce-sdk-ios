//
//  ShoppableFormatViewController.swift
//  Example
//

import UIKit
import BambuserCommerceSDK

/// Scaffolding shared by the Shop tab formats: the event router, the loading
/// indicator, the collection fetch, and tap-to-play for the inline formats.
class ShoppableFormatViewController: UIViewController {
    let navManager: NavigationManager
    private(set) lazy var router = ShoppableVideoEventRouter(navManager: navManager)
    var players: [BambuserPlayerView] = []
    private(set) var activePlayerId: String?

    let activityIndicator: UIActivityIndicatorView = {
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
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        router.presenter = self
    }

    /// Fetches the collection and hands the players over on the main actor.
    func loadPlayers(
        _ configuration: BambuserShoppableVideoConfiguration,
        then handle: @escaping @MainActor ([BambuserPlayerView]) -> Void
    ) {
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
        Task {
            do {
                let result = try await BambuserSDK(server: .US).createShoppableVideoPlayerCollection(
                    videoConfiguration: configuration
                )
                handle(result.players)
            } catch {
                print("\(type(of: self)) load error: \(error)")
            }
        }
    }

    /// Plays one player inline and resets the others.
    func playExclusively(id: String) {
        guard let tapped = players.first(where: { $0.id == id }) else { return }
        activePlayerId = id
        for p in players where p.id != id {
            p.resetPlayer()
        }
        tapped.play()
    }

    /// Resets the active player once it finishes, so it shows its preview again.
    func resetIfCompleted(id: String, state: BambuserVideoState) {
        guard state == .completed, id == activePlayerId,
              let player = players.first(where: { $0.id == id }) else { return }
        player.resetPlayer()
        activePlayerId = nil
    }
}
