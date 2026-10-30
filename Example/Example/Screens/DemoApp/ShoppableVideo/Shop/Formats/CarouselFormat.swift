//
//  CarouselFormat.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct CarouselFormatView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager
    var compact: Bool = false

    func makeUIViewController(context: Context) -> CarouselFormatViewController {
        CarouselFormatViewController(navManager: navigationManager, compact: compact)
    }

    func updateUIViewController(_ uiViewController: CarouselFormatViewController, context: Context) {}
}

final class CarouselFormatViewController: ShoppableFormatViewController {
    private let compact: Bool

    private lazy var header: UILabel = {
        let l = UILabel()
        l.text = "Featured shoppable videos"
        l.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .systemFont(ofSize: 20, weight: .bold))
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

    init(navManager: NavigationManager, compact: Bool = false) {
        self.compact = compact
        super.init(navManager: navManager)
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

        var constraints: [NSLayoutConstraint] = [
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 300),

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

        router.onStateChanged = { [weak self] id, state in self?.resetIfCompleted(id: id, state: state) }
        router.onThumbnailTapped = { [weak self] id in self?.playExclusively(id: id) }

        loadPlayers(ShoppableVideoConfigs.carousel()) { [weak self] in self?.setupRow($0) }
    }

    private func setupRow(_ list: [BambuserPlayerView]) {
        players = list
        router.bind(list)
        activityIndicator.stopAnimating()

        for player in list {
            let card = PlayerCardView(cornerRadius: 16)
            card.attach(player)
            row.addArrangedSubview(card)
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: 170),
                card.heightAnchor.constraint(equalTo: row.heightAnchor)
            ])
        }
    }
}
