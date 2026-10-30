//
//  DemoProduct.swift
//  Example
//

import UIKit

struct DemoProduct {
    let title: String
    let price: String
    let symbol: String
    let tint: UIColor
}

extension DemoProduct {
    static let featured: [DemoProduct] = [
        DemoProduct(title: "Linen Shirt", price: "$59", symbol: "tshirt.fill", tint: .systemBlue),
        DemoProduct(title: "Running Shoes", price: "$129", symbol: "figure.run", tint: .systemOrange),
        DemoProduct(title: "Sunglasses", price: "$49", symbol: "sun.max.fill", tint: .systemYellow),
        DemoProduct(title: "Smart Watch", price: "$249", symbol: "applewatch", tint: .systemGray),
        DemoProduct(title: "Wireless Earbuds", price: "$179", symbol: "earbuds", tint: .systemMint),
        DemoProduct(title: "Tote Bag", price: "$69", symbol: "handbag.fill", tint: .systemRed)
    ]

    static let newArrivals: [DemoProduct] = [
        DemoProduct(title: "Backpack", price: "$89", symbol: "bag.fill", tint: .systemGreen),
        DemoProduct(title: "Baseball Cap", price: "$24", symbol: "circle.hexagonpath.fill", tint: .systemPurple),
        DemoProduct(title: "Denim Jacket", price: "$119", symbol: "rectangle.fill", tint: .systemIndigo),
        DemoProduct(title: "Leather Wallet", price: "$45", symbol: "wallet.pass.fill", tint: .systemBrown),
        DemoProduct(title: "Wool Beanie", price: "$29", symbol: "snowflake", tint: .systemTeal),
        DemoProduct(title: "Silk Scarf", price: "$39", symbol: "scribble.variable", tint: .systemPink)
    ]
}

final class ProductCardView: UIView {
    let product: DemoProduct
    var onTap: (() -> Void)?

    init(product: DemoProduct) {
        self.product = product
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        let imageContainer = UIView()
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.backgroundColor = product.tint.withAlphaComponent(0.18)

        let icon = UIImageView(image: UIImage(systemName: product.symbol))
        icon.tintColor = product.tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = product.title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let priceLabel = UILabel()
        priceLabel.text = product.price
        priceLabel.font = .systemFont(ofSize: 13, weight: .medium)
        priceLabel.textColor = .secondaryLabel
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageContainer)
        addSubview(titleLabel)
        addSubview(priceLabel)

        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: topAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor, multiplier: 1.0),

            icon.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalTo: imageContainer.widthAnchor, multiplier: 0.45),
            icon.heightAnchor.constraint(equalTo: icon.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            priceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }
}
