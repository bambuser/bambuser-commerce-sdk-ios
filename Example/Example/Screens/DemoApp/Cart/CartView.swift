//
//  CartView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-08-22.
//

import SwiftUI

struct CartView: View {
    @StateObject private var vm = CartViewModel()
    @State private var showCheckoutAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.items.isEmpty {
                    ContentUnavailableView(
                        "Your cart is empty",
                        systemImage: "cart",
                        description: Text("Add products from videos or wishlist.")
                    )
                } else {
                    List {
                        ForEach(vm.items) { item in
                            HStack(alignment: .top, spacing: 12) {
                                ProductThumb(url: item.imageURL)
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.headline)
                                        .lineLimit(2)

                                    HStack(spacing: 8) {
                                        Text(item.brand)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        if let sizeName = item.sizeName, !sizeName.isEmpty {
                                            Text("· \(sizeName)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    HStack(spacing: 6) {
                                        Text(item.unitPrice, format: .currency(code: item.currency))
                                            .font(.subheadline.weight(.semibold))
                                            .monospacedDigit()

                                        if let original = item.original, original > item.unitPrice {
                                            Text(original, format: .currency(code: item.currency))
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .strikethrough()
                                                .monospacedDigit()
                                        }
                                    }
                                }

                                Spacer(minLength: 8)

                                VStack(alignment: .trailing, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Text("Qty: \(item.quantity)")
                                            .font(.subheadline)
                                            .monospacedDigit()

                                        Stepper(
                                            onIncrement: { vm.updateQuantity(productId: item.id, quantity: 1) },
                                            onDecrement: { vm.updateQuantity(productId: item.id, quantity: -1) }
                                        ) { EmptyView() }
                                        .labelsHidden()
                                        .controlSize(.small)
                                    }

                                    Text(item.lineTotal, format: .currency(code: item.currency))
                                        .font(.headline.weight(.semibold))
                                        .monospacedDigit()
                                }
                            }
                            .contentShape(Rectangle())
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vm.remove(productId: item.id)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { vm.remove(at: $0) }
                    }
                    .listStyle(.plain)
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(vm.subtotal, format: .currency(code: vm.currency))
                                    .bold()
                                    .monospacedDigit()
                            }
                            .padding(.horizontal)

                            Button {
                                showCheckoutAlert = true
                            } label: {
                                Text("Checkout")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        .background(.ultraThinMaterial)
                    }
                }
            }
        }
        .onAppear { vm.reloadFromStorage() }
        .alert("Congradulation 🎉 Your order is on the way!", isPresented: $showCheckoutAlert) {
            Button("OK", role: .cancel) { }
        }
    }

}

// MARK: - Item model
struct CartItem: Identifiable, Hashable {
    let id: String
    let parentSKU: String
    let title: String
    let brand: String
    let imageURL: URL?
    let sizeName: String?
    let unitPrice: Double
    let original: Double?
    let currency: String
    let quantity: Int

    var lineTotal: Double {
        unitPrice * Double(quantity)
    }
}

func parentSKU(from sku: String) -> String {
    sku.split(separator: "-", maxSplits: 1).first.map(String.init) ?? sku
}

// MARK: - Components

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

// MARK: - Preview
#Preview {
    Storage.shared.addToCart(items: [
        "436775-Bronzer-medium": 5,
        "614442-silver-standard": 2,
        "624114-standard": 1
    ])
    return CartView()
}
