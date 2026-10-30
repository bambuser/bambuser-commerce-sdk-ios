//
//  AppearancesView.swift
//  Example
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct AppearancesView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = AppearancesViewController(navManager: navigationManager)
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

final class AppearancesViewController: UIViewController {

    let navManager: NavigationManager
    private lazy var router = ShoppableVideoEventRouter(navManager: navManager, tab: .appearances)
    private var shoppable: BambuserShoppableView?

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
        router.presenter = self
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
        let contentStack = DemoShopSections.scrollingContent(
            in: view,
            spacing: 12,
            margins: UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        )

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

extension AppearancesViewController: BambuserShoppableViewDelegate {
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

extension AppearancesViewController {
    private func attachShoppable() async {
        do {
            let bamPlaylist = try await BambuserSDK(server: .US).attachShoppableView(
                into: shoppableHost,
                videoConfiguration: ShoppableVideoConfigs.appearance()
            )
            bamPlaylist.delegate = self
            router.attach(to: bamPlaylist)
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
