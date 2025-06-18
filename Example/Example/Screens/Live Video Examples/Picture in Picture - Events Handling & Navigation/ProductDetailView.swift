//
//  ProductDetailView.swift
//  Example
//
//  Created by Saeid Basirnia on 3/12/25.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product

    var body: some View {
        if let hydrated = product.hydrated {
            ScrollView {
                VStack(alignment: .leading) {
                    if let imageUrl = hydrated.variations.first?.imageUrls.first {
                        AsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .clipped()
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        Color.gray.frame(height: 200)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(hydrated.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(hydrated.introduction ?? "")
                            .font(.subheadline)
                        Text(hydrated.description ?? "")
                            .font(.body)
                    }
                    .padding()
                }
            }
            .navigationTitle(hydrated.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            VStack {
                Text("Product not found")
                    .font(.title)
                    .bold()
                    .foregroundColor(.black)
            }
            .navigationTitle("Error")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
