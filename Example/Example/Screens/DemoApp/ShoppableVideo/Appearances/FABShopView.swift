//
//  FABShopView.swift
//  Example
//

import SwiftUI
import UIKit
import BambuserCommerceSDK

struct FABShopView: UIViewControllerRepresentable {
    @EnvironmentObject var navigationManager: NavigationManager

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = FABShopViewController(navManager: navigationManager)
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

final class FABShopViewController: UIViewController {

    let navManager: NavigationManager
    private lazy var router = ShoppableVideoEventRouter(navManager: navManager, tab: .fab)
    private var shoppable: BambuserShoppableView?

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
            spacing: 24,
            margins: UIEdgeInsets(top: 16, left: 0, bottom: 32, right: 0)
        )

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
        do {
            let handle = try await BambuserSDK(server: .US).attachShoppableView(
                into: window,
                videoConfiguration: ShoppableVideoConfigs.fab()
            )
            handle.delegate = self
            router.attach(to: handle)
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
