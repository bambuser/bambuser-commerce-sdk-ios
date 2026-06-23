//
//  ShopHomeView.swift
//  Example
//
//  Created by Saeid Basirnia on 2026-06-11.
//

import SwiftUI

struct ShopHomeView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                StoriesInlineSection()
                trendingSection
                CarouselInlineSection()
                moreProductsSection
                allFormatsLink
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Trending")
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(ShopCatalog.featuredProducts.prefix(2)) { product in
                    ProductCard(product: product)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var moreProductsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("More to love")
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(ShopCatalog.featuredProducts.dropFirst(2)) { product in
                    ProductCard(product: product)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var allFormatsLink: some View {
        NavigationLink(value: PushDestination.allFormats) {
            HStack {
                Image(systemName: "play.rectangle.on.rectangle")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("More UI Examples")
                        .font(.subheadline.weight(.semibold))
                    Text("Reels, Grid, Spotlight and more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 16)
    }
}

private struct StoriesInlineSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stories")
                .font(.headline)
                .padding(.horizontal, 16)
            StoriesSelectorView(compact: true)
                .frame(height: 121)
        }
    }
}

private struct CarouselInlineSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Shop the show")
                    .font(.headline)
                Spacer()
                Text("Tap to play inline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            CarouselFeedView(compact: true)
                .frame(height: 300)
        }
    }
}

private struct ProductCard: View {
    let product: ShopCatalog.Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                LinearGradient(
                    colors: [product.tint.opacity(0.25), product.tint.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: product.symbol)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(product.tint)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(product.price, format: .currency(code: product.currency))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    NavigationStack {
        ShopHomeView()
            .environmentObject(NavigationManager())
    }
}
