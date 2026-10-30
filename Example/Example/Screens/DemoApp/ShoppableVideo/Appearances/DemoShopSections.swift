//
//  DemoShopSections.swift
//  Example
//

import UIKit

enum DemoShopSections {
    enum HeaderStyle {
        case title
        case caption
    }

    /// Pins a vertical scroll view to `view` and returns the stack to fill.
    static func scrollingContent(
        in view: UIView,
        spacing: CGFloat,
        margins: UIEdgeInsets
    ) -> UIStackView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = spacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.layoutMargins = margins
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
        return contentStack
    }

    static func banner(
        title: String,
        subtitle: String,
        symbol: String,
        background: UIColor,
        iconTint: UIColor
    ) -> UIView {
        let banner = UIView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.backgroundColor = background.withAlphaComponent(0.15)
        banner.layer.cornerRadius = 16
        banner.clipsToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subLabel = UILabel()
        subLabel.text = subtitle
        subLabel.font = .systemFont(ofSize: 14)
        subLabel.textColor = .secondaryLabel
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = iconTint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        banner.addSubview(titleLabel)
        banner.addSubview(subLabel)
        banner.addSubview(icon)
        NSLayoutConstraint.activate([
            banner.heightAnchor.constraint(equalToConstant: 100),
            titleLabel.topAnchor.constraint(equalTo: banner.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 20),
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subLabel.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 20),
            icon.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            icon.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -24),
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56)
        ])
        return margined(banner)
    }

    static func sectionHeader(_ title: String, style: HeaderStyle) -> UIView {
        let header = UILabel()
        header.text = title
        switch style {
        case .title:
            header.font = .systemFont(ofSize: 20, weight: .bold)
            header.textColor = .label
        case .caption:
            header.font = .systemFont(ofSize: 16, weight: .semibold)
            header.textColor = .secondaryLabel
            header.numberOfLines = 0
        }
        return margined(header)
    }

    static func productGrid(
        _ products: [DemoProduct],
        columns: Int,
        spacing: CGFloat,
        onTap: (() -> Void)? = nil
    ) -> UIView {
        let outer = UIStackView()
        outer.axis = .vertical
        outer.spacing = spacing
        outer.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        outer.isLayoutMarginsRelativeArrangement = true

        for chunk in stride(from: 0, to: products.count, by: columns) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = spacing
            row.distribution = .fillEqually
            for product in products[chunk..<min(chunk + columns, products.count)] {
                let card = ProductCardView(product: product)
                card.onTap = onTap
                row.addArrangedSubview(card)
            }
            while row.arrangedSubviews.count < columns {
                row.addArrangedSubview(UIView())
            }
            outer.addArrangedSubview(row)
        }
        return outer
    }

    private static func margined(_ view: UIView) -> UIView {
        let stack = UIStackView(arrangedSubviews: [view])
        stack.axis = .vertical
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }
}
