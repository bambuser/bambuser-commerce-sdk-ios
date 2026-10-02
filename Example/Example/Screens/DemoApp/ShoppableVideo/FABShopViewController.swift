//
//  FABShopViewController.swift
//  Example
//

import UIKit
import BambuserCommerceSDK

final class FABShopViewController: UIViewController {

    let navManager: NavigationManager
    private var shoppable: BambuserShoppableView?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(navManager: NavigationManager) {
        self.navManager = navManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        let handle = shoppable
        Task { @MainActor in handle?.cleanup() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigation()
        setupContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        attachFABIfNeeded()
    }

    private func attachFABIfNeeded() {
        guard shoppable == nil, let window = view.window else { return }
        Task { await attachFAB(in: window) }
    }

    private func setupNavigation() {
        title = "Deals"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "cart"),
            style: .plain,
            target: nil,
            action: nil
        )
    }

    private func setupContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 0, bottom: 32, right: 0)
        contentStack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        contentStack.addArrangedSubview(DemoShopSections.banner(
            title: "Shop the Look",
            subtitle: "See the latest drops in action",
            symbol: "play.rectangle.fill",
            background: .systemOrange,
            iconTint: .systemOrange
        ))
        contentStack.addArrangedSubview(DemoShopSections.sectionHeader("Tap any product to watch the video", style: .caption))
        contentStack.addArrangedSubview(DemoShopSections.productGrid(
            DemoProduct.featured + DemoProduct.newArrivals,
            columns: 2,
            spacing: 12,
            onTap: { [weak self] in self?.attachFABIfNeeded() }
        ))
    }

    private func attachFAB(in window: UIWindow) async {
        let sdk = BambuserSDK(server: .US)
        let config = BambuserShoppableVideoConfiguration(
            type: .playlist(Show.FABPlaylistConfig),
            events: ["*"],
            configuration: [
                "preload": true,
                "thumbnail": ["enabled": false],
                "playerConfig": [
                    "buttons": ["dismiss": "event"],
                    "enableTrackingPoint": false,
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ],
            videoScaleMode: .fill
        )
        do {
            let handle = try await sdk.attachShoppableView(
                into: window,
                videoConfiguration: config
            )
            handle.delegate = self
            shoppable = handle
        } catch {
            print("Failed to attach FAB: \(error)")
        }
    }
}

extension FABShopViewController: BambuserShoppableViewDelegate {
    func shoppableViewDidDismiss(_ view: BambuserShoppableView) {
        shoppable = nil
    }
}
