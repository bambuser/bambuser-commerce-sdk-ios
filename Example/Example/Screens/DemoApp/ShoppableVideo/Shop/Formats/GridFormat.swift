//
//  GridFormat.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct GridFormatView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> GridFormatViewController {
        GridFormatViewController(navManager: navigationManager)
    }

    func updateUIViewController(_ uiViewController: GridFormatViewController, context: Context) {}
}

final class GridFormatViewController: ShoppableFormatViewController {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(grid)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            grid.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8),
            grid.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8),
            grid.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            grid.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            grid.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16)
        ])

        router.onStateChanged = { [weak self] id, state in self?.resetIfCompleted(id: id, state: state) }
        router.onThumbnailTapped = { [weak self] id in self?.playExclusively(id: id) }

        loadPlayers(ShoppableVideoConfigs.grid()) { [weak self] in self?.setupGrid($0) }
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

            let cell = PlayerCardView(cornerRadius: 12)
            cell.attach(player)
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
}
