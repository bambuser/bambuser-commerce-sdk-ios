//
//  PlayerCardView.swift
//  Example
//

import UIKit
import BambuserCommerceSDK

/// A rounded, clipped host for one player. With an `onTap` the card takes the
/// touches itself and the player is not interactive.
final class PlayerCardView: UIView {
    private let onTap: (() -> Void)?
    private weak var player: BambuserPlayerView?

    init(cornerRadius: CGFloat, onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = cornerRadius
        clipsToBounds = true

        if onTap != nil {
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
            isUserInteractionEnabled = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func attach(_ player: BambuserPlayerView) {
        player.translatesAutoresizingMaskIntoConstraints = false
        player.isUserInteractionEnabled = onTap == nil
        addSubview(player)
        NSLayoutConstraint.activate([
            player.leadingAnchor.constraint(equalTo: leadingAnchor),
            player.trailingAnchor.constraint(equalTo: trailingAnchor),
            player.topAnchor.constraint(equalTo: topAnchor),
            player.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.player = player
    }

    func detachPlayer() {
        player?.removeFromSuperview()
        player = nil
    }

    @objc private func handleTap() { onTap?() }
}
