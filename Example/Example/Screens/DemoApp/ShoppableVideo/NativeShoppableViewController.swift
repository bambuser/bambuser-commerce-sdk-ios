//
//  NativeShoppableViewController.swift
//  Example
//

import UIKit
import BambuserCommerceSDK

final class NativeShoppableViewController: UIViewController {

    let navManager: NavigationManager
    private var shoppable: BambuserShoppableView?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let shoppableHost = UIView()
    private var loadingPlaceholderHeight: NSLayoutConstraint!
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

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
        Task { await attachShoppable() }
    }

    private func setupNavigation() {
        title = "Appearances"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "cart"),
            style: .plain,
            target: self,
            action: #selector(openCart)
        )
    }

    @objc private func openCart() {
        navManager.switchTo(.cart)
    }

    private func setupContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
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

        shoppableHost.translatesAutoresizingMaskIntoConstraints = false
        shoppableHost.backgroundColor = .clear

        // Keeps the spinner visible while loading. Removed once the view is
        // attached, so the host gets its height from the SDK instead.
        loadingPlaceholderHeight = shoppableHost.heightAnchor.constraint(equalToConstant: 90)
        loadingPlaceholderHeight.isActive = true

        shoppableHost.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: shoppableHost.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: shoppableHost.centerYAnchor)
        ])

        let shoppableMargined = UIStackView(arrangedSubviews: [shoppableHost])
        shoppableMargined.axis = .vertical
        shoppableMargined.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        shoppableMargined.isLayoutMarginsRelativeArrangement = true

        contentStack.addArrangedSubview(DemoShopSections.banner(
            title: "Summer Sale",
            subtitle: "Up to 50% off, limited time",
            symbol: "sun.max.fill",
            background: .systemIndigo,
            iconTint: .systemOrange
        ))
        contentStack.addArrangedSubview(DemoShopSections.sectionHeader("Featured", style: .title))
        contentStack.addArrangedSubview(DemoShopSections.productGrid(DemoProduct.featured, columns: 3, spacing: 8))

        // The shoppable view sits between the two product sections.
        contentStack.addArrangedSubview(shoppableMargined)

        contentStack.addArrangedSubview(DemoShopSections.sectionHeader("New Arrivals", style: .title))
        contentStack.addArrangedSubview(DemoShopSections.productGrid(DemoProduct.newArrivals, columns: 3, spacing: 8))
    }
}

extension NativeShoppableViewController: BambuserShoppableViewDelegate {
    private func log(_ callback: String, _ view: BambuserShoppableView, _ details: String = "") {
        let pagination = view.pagination
        print("""
        [Appearance] \(callback)\(details.isEmpty ? "" : " \(details)")
            mode=\(view.mode) players=\(view.players.count) contentSize=\(view.contentSize.map { "\($0)" } ?? "nil")
            pagination page=\(pagination.page) pageSize=\(pagination.pageSize) total=\(pagination.total) totalPages=\(pagination.totalPages.map(String.init) ?? "nil")
        """)
    }

    private func describe(_ item: BambuserShoppableItem) -> String {
        let m = item.metadata
        return "index=\(item.index) playerId=\(item.playerId) video(id=\(m.id) title=\(m.title ?? "nil") length=\(m.length) hasAudio=\(m.hasAudio.map(String.init) ?? "nil") preview=\(m.preview ?? "nil"))"
    }

    func shoppableView(_ view: BambuserShoppableView, didChangeContentSize size: CGSize) {
        log("didChangeContentSize", view, "size=\(size)")
    }

    func shoppableView(_ view: BambuserShoppableView, willLoadPage page: Int) {
        log("willLoadPage", view, "page=\(page)")
    }

    func shoppableView(_ view: BambuserShoppableView, didLoadPage page: Int, totalPages: Int?) {
        log("didLoadPage", view, "page=\(page) totalPages=\(totalPages.map(String.init) ?? "nil")")
    }

    func shoppableView(_ view: BambuserShoppableView, didFailToLoadPage page: Int, error: Error) {
        log("didFailToLoadPage", view, "page=\(page) error=\(error)")
    }

    func shoppableView(_ view: BambuserShoppableView, didSelect item: BambuserShoppableItem) {
        log("didSelect", view, describe(item))
    }

    func shoppableView(_ view: BambuserShoppableView, didEnterFullscreen item: BambuserShoppableItem) {
        log("didEnterFullscreen", view, describe(item))
        navManager.isShoppableFullscreen = true
    }

    func shoppableView(_ view: BambuserShoppableView, didExitFullscreen item: BambuserShoppableItem) {
        log("didExitFullscreen", view, describe(item))
        navManager.isShoppableFullscreen = false
    }

    func shoppableView(_ view: BambuserShoppableView, didChangeCurrent item: BambuserShoppableItem) {
        log("didChangeCurrent", view, describe(item))
    }

    func shoppableViewDidDismiss(_ view: BambuserShoppableView) {
        log("shoppableViewDidDismiss", view)
        navManager.isShoppableFullscreen = false
        shoppable = nil
    }
}

extension NativeShoppableViewController {
    private func attachShoppable() async {
        let sdk = BambuserSDK(server: .US)
        let config = BambuserShoppableVideoConfiguration(
            type: .playlist(Show.PlaylistConfig),
            events: ["*"],
            configuration: [
                "thumbnail": ["enabled": false],
                "playerConfig": [
                    "buttons": ["dismiss": "event"],
                    "currency": "SEK",
                    "locale": "en-US"
                ]
            ],
            videoScaleMode: .fill
        )
        do {
            let bamPlaylist = try await sdk.attachShoppableView(
                into: shoppableHost,
                videoConfiguration: config
            )
            bamPlaylist.delegate = self
            shoppable = bamPlaylist
            log("attached", bamPlaylist, "playerIds=\(bamPlaylist.players.map(\.id))")
            activityIndicator.stopAnimating()

            // The view reports its own size now, so the host does not need a height.
            loadingPlaceholderHeight.isActive = false
        } catch {
            activityIndicator.stopAnimating()
            print("Failed to attach shoppable view: \(error)")
        }
    }
}
