//
//  WishlistView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-22.
//

import SwiftUI

struct WishlistView: View {
    @StateObject private var viewModel = WishlistViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.items.isEmpty {
                    ContentUnavailableView(
                        "Your wishlist is empty",
                        systemImage: "heart",
                        description: Text("Save products from videos to see them here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.items) { item in
                            HStack(spacing: 12) {
                                ProductThumb(url: item.imageURL)
                                    .frame(width: 84, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(item.brand)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 8) {
                                        Text(item.price, format: .currency(code: item.currency))
                                            .font(.subheadline).bold()
                                        if let original = item.original, original > item.price {
                                            Text(original, format: .currency(code: item.currency))
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .strikethrough()
                                        }
                                    }
                                }

                                Spacer()

                                HStack(spacing: 12) {
                                    Button {
                                        viewModel.addToCart(sku: item.sku)
                                    } label: {
                                        Image(systemName: "cart.badge.plus")
                                            .imageScale(.large)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Add to cart")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.remove(sku: item.sku)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.remove(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .onAppear {
            viewModel.reloadFromStorage()
        }
    }
}

struct WishlistItem: Identifiable, Hashable {
    let id: String
    let sku: String
    let title: String
    let brand: String
    let imageURL: URL?
    let price: Double
    let original: Double?
    let currency: String

    init(product: HydratedProduct) {
        self.id = product.sku
        self.sku = product.sku
        self.title = product.name
        self.brand = product.brandName

        let variation = product.variations.first
        self.imageURL = variation?.imageUrls.first

        let size = variation?.sizes.first
        self.price = size?.current ?? 0
        self.original = size?.original
        self.currency = size?.currency ?? "SEK"
    }
}

private struct ProductThumb: View {
    let url: URL?

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.secondarySystemBackground))
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "photo")
                .imageScale(.large)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    Storage.shared.addToWishlist(
        items: ["436775": true, "614442": true]
    )
    return WishlistView()
}
